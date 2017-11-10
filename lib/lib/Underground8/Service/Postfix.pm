# This file is part of the Open AS Communication Gateway.
#
# The Open AS Communication Gateway is free software: you can redistribute it
# and/or modify it under theterms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# The Open AS Communication Gateway is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
# General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.


package Underground8::Service::Postfix;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Postfix::SLAVE;
use Underground8::ReportFactory::LimesAS::LDAP;
use Underground8::Exception::DomainExists;
use Underground8::Exception::DomainNotExists;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;
use Underground8::Exception::SMTPServerNotExists;
use Underground8::Exception::CertificateInvalid;
use Underground8::Exception::NoMatchCertificatePrivatekey;
use Net::IP;
use XML::Dumper;
use Data::Dumper;
use Hash::Merge qw( merge );

#Constructor
sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Postfix::SLAVE();
    $self->{'_config'} = { };
    $self->{'_options'} = { 
         sender_domain_verify => 0,
         sender_fqdn_required => 0,
         rbl_checks => 0,
         backscatter_protection => 1,
         backscatter_key => 0,
    };
    $self->{'_ip_range_whitelist'} = [];
    $self->{'_usermaps'} = ();
    return $self;
}

#### Accessors ####

sub slave ($)
{
    my $self = instance(shift,__PACKAGE__); 
    return $self->{'_slave'};;
}

sub config($)
{
    my $self = instance(shift,__PACKAGE__);
    return $self->{'_config'};
}

sub ip_range_whitelist ($)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_ip_range_whitelist'} = shift;
    }
    return $self->{'_ip_range_whitelist'};
}

sub usermaps ($)
{
    my $self = instance(shift);
    
    if (@_)
    {
        $self->{'_usermaps'} = shift;
    }
    return $self->{'_usermaps'};
}

sub get_usermaps_domain ($$)
{
    my $self = instance(shift);
    my $domain = shift;
    my $ldap = shift;

    if (! $ldap eq "1")
    {
        return $self->{'_usermaps'}{$domain};
    } else {
        my $ldapmaps_file = $g->{'ldap_maps_dir'}.$g->{'ldap_maps_cache_file'};
        my $dump = new XML::Dumper;
        my $ldapmaps = ();
        my $merged_maps = ();
    
        if (-f $ldapmaps_file)
        {
            $ldapmaps = $dump->xml2pl($ldapmaps_file)
                or throw Underground8::Exception::FileOpen($ldapmaps_file);
        }
        Hash::Merge::set_behavior( 'LEFT_PRECEDENT' );
        if ( ref($self->{'_usermaps'}) eq 'HASH' )
        {
            $merged_maps = merge($self->{'_usermaps'}, $ldapmaps);
        } else {
            $merged_maps = $ldapmaps;
        }
    
        my $addr_count;
        if (!(ref($merged_maps) eq 'HASH'))
        {
            $merged_maps = undef;
            print STDERR "\nI set merged_maps to undef!\n";
        }
    
        foreach my $domain (keys %{$self->{'_domains'}->{'relay_domains'}})
        {
            $addr_count = 0;
            $merged_maps->{$domain}{'accept_all'} = 1;
            if ( ref($merged_maps->{$domain}{'addresses'}) eq 'HASH')
            {
                $addr_count = (keys %{$merged_maps->{$domain}{'addresses'}});
            }
    
            if ( !($addr_count =~ /\d+?/) )
            {
                $addr_count = 0;
            }
    
            if ($addr_count gt "0") {
                $merged_maps->{$domain}{'accept_all'} = 0;
            }
        }
        
        return $merged_maps->{$domain};
    }

}

sub commit ($)
{
    my $self = instance(shift,__PACKAGE__);

    my @ip_range_whitelist;
    foreach my $ip_range (@{ $self->ip_range_whitelist })
    {
	    my $start = $ip_range->{'start'};
	    my $end = $ip_range->{'end'};
	    my $ip = new Net::IP("$start - $end");
	    push( @ip_range_whitelist, $ip->find_prefixes() );	# add the classes for this range
	    $ip = undef;
    }
    #prepare rbls by sorting them into array
	# $self->sorted_enabled_rbls($self->rbls_list);

    my $files;
    foreach my $key (keys %$g)
    {
        if ($key =~ m/^file_postfix_/)
        {
            push @{$files}, $g->{$key};
        }

        if ($key =~ m/^file_batv_/)
        {
            push @{$files}, $g->{$key};
        }
    }
    push @{$files}, $g->{'usermaps_raw_file'};
    
    my $md5_first = $self->create_md5_sums($files);
        
    
    $self->slave->write_config( 
		$self->{'_config'}, 
		$self->{'_domains'}, 
		$self->{'_options'}, 
		\@ip_range_whitelist,
   	);


    # well ... here we are looking in our usermaps file and merging it with configured domains
    # and we are also merging with ldap usermaps ...!
    
    my $ldapmaps_file = $g->{'ldap_maps_dir'}.$g->{'ldap_maps_cache_file'};
    my $dump = new XML::Dumper;
    my $ldapmaps = ();
    my $merged_maps = ();
    
    if (-f $ldapmaps_file)
    {
        $ldapmaps = $dump->xml2pl($ldapmaps_file)
            or throw Underground8::Exception::FileOpen($ldapmaps_file);
    }
    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' );
    if ( ref($self->{'_usermaps'}) eq 'HASH' )
    {
        $merged_maps = merge($self->{'_usermaps'}, $ldapmaps);
    } else {
        $merged_maps = $ldapmaps;
    }

    my $addr_count;
    if (!(ref($merged_maps) eq 'HASH'))
    {
        $merged_maps = undef;
        print STDERR "\nI set merged_maps to undef!\n";
    }
     
    foreach my $domain (keys %{$self->{'_domains'}->{'relay_domains'}})
    {
        $addr_count = 0;
        $merged_maps->{$domain}{'accept_all'} = 1;
        if ( ref($merged_maps->{$domain}{'addresses'}) eq 'HASH')
        {
            $addr_count = (keys %{$merged_maps->{$domain}{'addresses'}});
        }
    
        if ( !($addr_count =~ /\d+?/) )
        {
            $addr_count = 0;
        }
    
        if ($addr_count gt "0") {
            $merged_maps->{$domain}{'accept_all'} = 0;
        } 
    }
    
    # no need for writing usermaps if we don't even have ONE domain configured
    if (defined $merged_maps)
    {
        $self->slave->create_usermaps($merged_maps);
    }


    my $md5_second = $self->create_md5_sums($files);
    
    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_reload();
        $self->slave->service_batv_restart();
    }

    

    # populate the tables with the values from the object
    my $db_host = $self->{'_domains'}->{'_mysql_host'} || "localhost" ;
    my $db_port = $self->{'_domains'}->{'_mysql_port'};
    my $db_usr = $self->{'_domains'}->{'_mysql_user'} || "smtp_auth-user" ;
    my $db_pwd = $self->{'_domains'}->{'_mysql_password'} || "loltruck2000";

    my $dbi = 'DBI:mysql:smtp_auth';
    $dbi .= ";host=$db_host" if $db_host;
    $dbi .= ";port=$db_port" if $db_port;
    my $dbh = DBI->connect( $dbi, $db_usr, $db_pwd ) || die "Could not connect to database: $DBI::errstr";

    $dbh->do( "TRUNCATE TABLE domains" ) or die( "$DBI::errstr" );
    my $sth = $dbh->prepare( "INSERT INTO domains (name, smtp_srv_ref) VALUES (?, ?)" );
    foreach my $domain_name ( keys %{ $self->{'_domains'}->{ 'relay_domains' } } )
    {
        foreach my $smtp_srv_ref ( $self->{'_domains'}->{ 'relay_domains' }->{ $domain_name }->{ 'dest_mailserver' } )
        {
            if( ref( $smtp_srv_ref ) eq "ARRAY" ) {
            foreach my $smtp_ref ( @$smtp_srv_ref )
            {
                $sth->execute( $domain_name, $smtp_ref->{'CONTENT'} ) or die( "$DBI::errstr" );
            }
            } else {
            $sth->execute( $domain_name, $smtp_srv_ref ) or die( "$DBI::errstr" );
            }
            next if $smtp_srv_ref !~ /^smtp[0-9]{14}$/;
        }
    }

    $dbh->do( "TRUNCATE TABLE smtp_servers" ) or die( "$DBI::errstr" );
    $sth = $dbh->prepare( "INSERT INTO smtp_servers (smtp_srv_ref, descr, addr, port, auth_enabled, auth_methods, ssl_validation, use_fqdn) VALUES (?, ?, ?, ?, ?, ?, ?, ?)" );
    foreach my $smtp_srv_id ( keys %{ $self->{'_domains'}->{ 'relay_smtp' } } )
    {
        my $smtp_srv = $self->{'_domains'}->{ 'relay_smtp' }->{ $smtp_srv_id };
        my $descr = "$smtp_srv->{descr}";
        my $addr = "$smtp_srv->{addr}";
        my $port = "$smtp_srv->{port}";
        my $auth_enabled = "$smtp_srv->{auth_enabled}";
        my $auth_method = "$smtp_srv->{auth_methods}";
        my $ssl_validation = "$smtp_srv->{ssl_validation}";
        my $use_fqdn = "$smtp_srv->{use_fqdn}";

        $sth->execute( $smtp_srv_id, $descr, $addr, $port, $auth_enabled,
            $auth_method, $ssl_validation, $use_fqdn ) or die( "$DBI::errstr" );
    }

    $dbh->disconnect();

    $self->unchange;
}
    



#### CRUD Methods ####

sub domain_create ($$$$)
{
    my $self = instance(shift);
    my $domain_name = shift;
    my $dest_mailserver = shift;
    my $enabled = shift;


    if (!$self->domain_exists($domain_name))
    {
        $self->{'_domains'}->{'relay_domains'}->{$domain_name}->{'dest_mailserver'} = $dest_mailserver;
        $self->{'_domains'}->{'relay_domains'}->{$domain_name}->{'enabled'} = $enabled;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::DomainExists();
    }
}

sub domain_update ($$$$)
{
    my $self = instance(shift);
    my $domain_name = shift;
    my $dest_mailserver = shift;

    if ($self->domain_exists($domain_name))
    {
        $self->{'_domains'}->{'relay_domains'}->{$domain_name}->{'dest_mailserver'} = $dest_mailserver;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::DomainNotExists();
    }

}


# return all relay_domains
sub domain_read ($)
{
    my $self = instance(shift);

    return $self->{'_domains'}->{'relay_domains'};
}

sub domain_delete ($$)
{
    my $self = instance(shift);
    my $domain_name = shift;

    if ($self->domain_exists($domain_name))
    {
        delete($self->{'_domains'}->{'relay_domains'}->{$domain_name});
        $self->change;

	# delete from the cache all the users authenticated for this domain
        my $db_host = $self->{'_domains'}->{'_mysql_host'} || "localhost" ;
        my $db_port = $self->{'_domains'}->{'_mysql_port'};
        my $db_usr = $self->{'_domains'}->{'_mysql_user'} || "smtp_auth-user" ;
        my $db_pwd = $self->{'_domains'}->{'_mysql_password'} || "loltruck2000";

        my $dbi = 'DBI:mysql:smtp_auth';
        $dbi .= ";host=$db_host" if $db_host;
        $dbi .= ";port=$db_port" if $db_port;

        # TODO replace die with exceptions for more stability and niceness
        my $dbh = DBI->connect( $dbi, $db_usr, $db_pwd ) || die "Could not connect to database: $DBI::errstr";

        $dbh->do( "DELETE FROM cache_auth WHERE domain = '$domain_name'" ) or die( "$DBI::errstr" );

        $dbh->disconnect();
    }
    else
    {
        throw Underground8::Exception::DomainNotExists();
    }

}

sub smtpsrv_read ($)
{
    my $self = instance(shift);

    return $self->{'_domains'}->{'relay_smtp'};
}

sub domains_linked($$)
{
    my $self = instance(shift);
    my $smtpsrv_name = shift;
    my @arr;
    
    while( my ($domain, my $domain_properties) = each( %{ $self->{'_domains'}->{'relay_domains'} } ) )
    {
        if( $domain_properties->{'dest_mailserver'} eq $smtpsrv_name )
        {
            push @arr, $domain;
        }
    }
    return \@arr;
}


# USERMAP Controlling

# This is add and update in one thing ;)
sub usermaps_update_addr($$$$)
{
    my $self = instance(shift);
    my $domain = shift;
    my $address = shift;
    my $accept = shift;

    $self->{'_usermaps'}{$domain}{'addresses'}{$address}{'accept'} = $accept;
    $self->{'_usermaps'}{$domain}{'accept_all_manual'} = 0;
    $self->change;
}

sub usermaps_delete_addr($$$)
{
    my $self = instance(shift);
    my $domain = shift;
    my $address = shift;
    
    delete  $self->{'_usermaps'}{$domain}{'addresses'}{$address};
    $self->change;
}

sub usermaps_delete_domain($$)
{
    my $self = instance(shift);
    my $domain = shift;
    
    if ($domain)
    {
        delete $self->{'_usermaps'}{$domain};
        
        $self->change;
    }
}


=head2
sub: domains_bulk_assign
goal: change the SMTP server assigned to all the domains linked against the src_mailserver
return: 1 if there was domains changed, otherwise 0
=cut
sub domains_bulk_assign($$$)
{
    my $self = instance(shift);
    my $src_mailserver = shift;
    my $dest_mailserver = shift;
    
    my $atleast_one = 0;

    while( my ($domain, my $domain_properties) = each( %{ $self->{'_domains'}->{'relay_domains'} } ) )
    {
        if( $domain_properties->{'dest_mailserver'} eq $src_mailserver )
        {
            $atleast_one = 1;
            $domain_properties->{'dest_mailserver'} = $dest_mailserver;
        }
    }

    if( $atleast_one )
    {
	$self->change;
    }
    
    return $atleast_one;
}

# return all relay_smtpsrvs
sub smtpsrv_delete ($$)
{
    my $self = instance(shift);
    my $smtpsrv_name = shift;

    if (exists($self->{'_domains'}->{'relay_smtp'}->{$smtpsrv_name}))
    {
        if( $self->{'_domains'}->{'relay_smtp'}->{$smtpsrv_name}->{'has_cacert'} )
        {
            $self->slave->cacert_delete( $smtpsrv_name );	# delete the certificate
        }

        delete($self->{'_domains'}->{'relay_smtp'}->{$smtpsrv_name});

        foreach my $domain_name ( keys %{ $self->{'_domains'}->{'relay_domains'} } )
        {
            my $ref = $self->{'_domains'}->{'relay_domains'}->{ $domain_name };
            # de facut cazul cand sunt mai multe smtp pentru un domeniu si trebuie sters doar dest_ daca sunt mai multe
            # !!!
            if( $ref->{ 'dest_mailserver'} eq $smtpsrv_name )
            {
            delete( $self->{'_domains'}->{'relay_domains'}->{ $domain_name } );
            }
        }
        $self->change;

        # delete also from cache the users validated for this domain
        my $db_host = $self->{'_domains'}->{'_mysql_host'} || "localhost" ;
        my $db_port = $self->{'_domains'}->{'_mysql_port'};
        my $db_usr = $self->{'_domains'}->{'_mysql_user'} || "smtp_auth-user" ;
        my $db_pwd = $self->{'_domains'}->{'_mysql_password'} || "loltruck2000";

        my $dbi = 'DBI:mysql:smtp_auth';
        $dbi .= ";host=$db_host" if $db_host;
        $dbi .= ";port=$db_port" if $db_port;
        my $dbh = DBI->connect( $dbi, $db_usr, $db_pwd ) || die "Could not connect to database: $DBI::errstr";

        $dbh->do( "DELETE FROM cache_auth WHERE smtp_srv_ref = '$smtpsrv_name'" ) or die( "$DBI::errstr" );
        
        # delete also all the domains linked to it
        $dbh->do( "DELETE FROM domains WHERE smtp_srv_ref = '$smtpsrv_name'" ) or die( "$DBI::errstr" );

        $dbh->disconnect();
    }
    else
    {
        throw Underground8::Exception::SMTPServerNotExists();
    }
}

sub smtpsrv_create ($$$$) {
    my $self = instance(shift);
    my $descr = shift;
    my $addr = shift;
    my $port = shift;
    my $auth_enabled = shift;
    my $auth_methods = shift;
    my $ssl_check = shift;
    my $use_fqdn = shift;
    my $ldap_enabled = shift;
    my $ldap_server = shift;
    my $ldap_user = shift;
    my $ldap_pass = shift;
    my $ldap_base = shift;
    my $ldap_filter = shift;
    my $ldap_property = shift;
    my $ldap_autolearn_domains = shift;

    my $smtp_name = "_";	# we need to return something
    if ( ! $self->smtpsrv_exists( $addr, $port ) ) {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime( time );
        $smtp_name = sprintf( "smtp%4d%02d%02d%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'descr'} = $descr;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'addr'} = $addr;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'port'} = $port;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'auth_enabled'} = $auth_enabled;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'auth_methods'} = $auth_methods;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ssl_validation'} = $ssl_check;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'use_fqdn'} = $use_fqdn;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'has_cacert'} = 0;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_enabled'} = $ldap_enabled;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_server'} = $ldap_server;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_user'} = $ldap_user;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_pass'} = $ldap_pass;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_base'} = $ldap_base;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_filter'} = $ldap_filter;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_property'} = $ldap_property;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_autolearn_domains'} = $ldap_autolearn_domains;
        $self->change;
    } else {
        throw Underground8::Exception::SMTPServerExists();
    }
    
    return $smtp_name;
}

sub smtpsrv_update ($$$$) {
    my $self = instance(shift);
    my $smtp_name = shift;
    my $descr = shift;
    my $addr = shift;
    my $port = shift;
    my $auth_enabled = shift;
    my $auth_methods = shift;
    my $ssl_check = shift;
    my $use_fqdn = shift;
    my $ldap_enabled = shift;
    my $ldap_server = shift;
    my $ldap_user = shift;
    my $ldap_pass = shift;
    my $ldap_base = shift;
    my $ldap_filter = shift;
    my $ldap_property = shift;
	my $ldap_autolearn_domains = shift;

    if (exists($self->{'_domains'}->{'relay_smtp'}->{$smtp_name})) {
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'descr'} = $descr;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'addr'} = $addr;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'port'} = $port;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'auth_enabled'} = $auth_enabled;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'auth_methods'} = $auth_methods;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ssl_validation'} = $ssl_check;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'use_fqdn'} = $use_fqdn;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_enabled'} = $ldap_enabled;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_server'} = $ldap_server;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_user'} = $ldap_user;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_pass'} = $ldap_pass;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_base'} = $ldap_base;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_filter'} = $ldap_filter;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_property'} = $ldap_property;
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'ldap_autolearn_domains'} = $ldap_autolearn_domains;

        $self->change;
    } else {
        throw Underground8::Exception::SMTPServerNotExists();
    }
}

sub domain_enable ($$) {
    my $self = instance(shift);
    my $domain_name = shift;

    if ($self->domain_exists($domain_name))
    {
        $self->{'_domains'}->{'relay_domains'}->{$domain_name}->{'enabled'} = 'yes';
        $self->change;
    }
    else
    {
        throw Underground8::Exception::DomainNotExists();
    }
}

sub domain_disable ($$)
{
    my $self = instance(shift);
    my $domain_name = shift;

    if ($self->domain_exists($domain_name))
    {
        $self->{'_domains'}->{'relay_domains'}->{$domain_name}->{'enabled'} = 'no';
        $self->change;
    }
    else
    {
        throw Underground8::Exception::DomainNotExists();
    }
}



#### internal validations ####

sub domain_exists ($$)
{
    my $self = instance(shift);
    my $domain_name = shift;

    if (exists($self->{'_domains'}->{'relay_domains'}->{$domain_name}))
    {
        return 1;
    }
    return 0;
}

sub smtpsrv_exists ($$$)
{
    my $self = instance(shift);
    my $addr = shift;
    my $port = shift;

    foreach my $smtpsrv (keys %{ $self->{'_domains'}->{'relay_smtp'} })
    {
        if( ($self->{'_domains'}->{'relay_smtp'}->{ $smtpsrv }->{'addr'} eq $addr) &&
            ($self->{'_domains'}->{'relay_smtp'}->{ $smtpsrv }->{'port'} == $port) )
        {
                return 1;
        }
    }
    return 0;
}



#### getters and setters for config access ####

sub smtpd_banner ($)
{
    my $self = instance(shift);
    return $self->{'_config'}->{'smtpd_banner'}
}

sub set_smtpd_banner ($$)
{
    my $self = instance(shift);
    my $smtpd_banner = shift;
    $self->{'_config'}->{'smtpd_banner'} = $smtpd_banner;
    $self->change;
}


sub set_myhostname ($$)
{
    my $self = instance(shift);
    my $myhostname = shift;
    $self->{'_config'}->{'myhostname'} = $myhostname;
    $self->change;
}

sub set_mydestination ($$)
{
    my $self = instance(shift);
    my $hostname = shift;
    my $mydestination = $hostname;
    $mydestination .= ", localhost.localdomain, localhost";
    $self->{'_config'}->{'mydestination'} = $mydestination;
    $self->change;
}


sub helo_required ($)
{
    my $self = instance(shift);
    return 0 if not defined $self->config->{'smtpd_helo_required'};
    if ($self->config->{'smtpd_helo_required'} eq 'yes')
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
sub enable_helo_required ($)
{
    my $self = instance(shift);
    $self->config->{'smtpd_helo_required'} = 'yes';
    $self->change;
}

sub disable_helo_required ($)
{
    my $self = instance(shift);
    $self->config->{'smtpd_helo_required'} = 'no';
    $self->change;
}

sub rfc_strict ($)
{
    my $self = instance(shift);
    return 0 if not defined $self->config->{'strict_rfc821_envelopes'};
    if ($self->config->{'strict_rfc821_envelopes'} eq 'yes')
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub enable_rfc_strict ($)
{
    my $self = instance(shift);
    $self->config->{'strict_rfc821_envelopes'} = 'yes';
    $self->change;
}

sub disable_rfc_strict ($)
{
    my $self = instance(shift);
    $self->config->{'strict_rfc821_envelopes'} = 'no';
    $self->change;
}

sub sender_fqdn_required ($)
{
    my $self = instance(shift);
    return $self->{'_options'}->{'sender_fqdn_required'} || 0;
}

sub enable_sender_fqdn_required ($)
{
    my $self = instance(shift);
    $self->{'_options'}->{'sender_fqdn_required'} = 1;
    $self->change;
}

sub disable_sender_fqdn_required ($)
{
    my $self = instance(shift);
    $self->{'_options'}->{'sender_fqdn_required'} = 0;
    $self->change;
}

sub sender_domain_verify ($)
{
    my $self = instance(shift);
    return $self->{'_options'}->{'sender_domain_verify'};
}

sub enable_sender_domain_verify ($)
{
    my $self = instance(shift);
    $self->{'_options'}->{'sender_domain_verify'} = 1;
    $self->change;
    
}

sub disable_sender_domain_verify ($)
{
    my $self = instance(shift);
    $self->{'_options'}->{'sender_domain_verify'} = 0;
    $self->change;
}

sub max_incoming_connections($$)
{
    my $self = instance(shift);
    if(@_)
    {
	    $self->config->{'smtpd_client_connection_rate_limit'} = shift;
	    $self->change();
    }
    return $self->config->{'smtpd_client_connection_rate_limit'};
}

# PostFWD stuff
sub enable_postfwd($){
	my $self = instance(shift);
	$self->{'_options'}->{'enable_postfwd'} = 1;
	$self->change;
}

sub disable_postfwd($){
	my $self = instance(shift);
	$self->{'_options'}->{'enable_postfwd'} = 0;
	$self->change;
}

sub status_postfwd($){
	my $self = instance(shift);
	return $self->{'_options'}->{'enable_postfwd'};
}

# batv-filter

sub backscatter_protection
{
    my $self = instance(shift);
    if(@_)
    {
        $self->{'_options'}->{'backscatter_protection'} = shift;
        $self->change;
    }
    return $self->{'_options'}->{'backscatter_protection'};
}

sub backscatter_key
{
    my $self = instance(shift);
    if(@_)
    {
        $self->{'_options'}->{'backscatter_key'} = shift;
        $self->change;
    }
    return $self->{'_options'}->{'backscatter_key'};
}

# Remote Blacklists
#sub enable_rbl_checks($)
#{
#    my $self = instance(shift);
#    $self->{'_options'}->{'rbl_checks'} = 1; 
#    $self->change;
#}
#
#sub disable_rbl_checks($)
#{
#    my $self = instance(shift);
#    $self->{'_options'}->{'rbl_checks'} = 0; 
#    $self->change;
#}
#
# Obsolete - but we'll still need this sub for converting old sqlgrey-rbl to new postfwd-rbl
sub rbl_checks($)
{
    my $self = instance(shift);
    return $self->{'_options'}->{'rbl_checks'};
}
#
#sub sorted_enabled_rbls ($$)
#{
#    my $self = instance(shift);
#    my $rbls = shift;
#    #sorting by rank
#    my @sorted = sort { $rbls->{$a}->{'rank'} <=> $rbls->{$b}->{'rank'} } keys %$rbls ;
#    #deleting those disabled rbls
#    my @sorted_enabled=();
#    foreach (@sorted)
#    {
#        if($rbls->{$_}->{'enabled'} == 1) {push @sorted_enabled, $_};
#    }
#    $self->{'_options'}->{'rbls'}= \@sorted_enabled ;
#}
#
#sub rbls_list($)
#{
#    my $self = instance(shift);
#    return  new XML::Dumper()->xml2pl($g->{'rbls_list'}) or throw Underground8::Exception::FileOpen($g->{'rbls_list'}) ;
#}
#
#sub toggle_rbl_service($$)
#{
#    my $self = instance(shift);
#    my $rbl_name = shift ;
#    my $rbls = rbls_list($self) ;
#    $rbls->{$rbl_name}->{'enabled'} = ( $rbls->{$rbl_name}->{'enabled'} ==1)? 0 : 1 ;
#    new XML::Dumper->pl2xml($rbls , $g->{'rbls_list'});
#    $self->{'_options'}->{'rbls_list'} = new XML::Dumper()->xml2pl($g->{'rbls_list'})or throw Underground8::Exception::FileOpen($g->{'rbls_list'});
#    $self->change;
#    $self->commit($self);
#    
#}
#sub add_custom_rbl($$)
#{
#    my $self = instance(shift);
#    my $rbl_name = shift ;
#    my $rbls = rbls_list($self) ;
#    if (defined $rbls->{$rbl_name})
#    {
#        throw Underground8::Exception::EntryExistsIn( 'rbl list', $rbl_name );
#    }
#    else
#    {
#        # calculate rank of the new rbl , rank  = nb_of_defined_rbls + 1
#        my $rank = scalar (keys  %{$rbls})  + 1 ;
#        #add the new rbl entry to the main hash
#        $rbls->{$rbl_name}= {rank =>$rank , enabled => 0, type =>'user'};
#        # write down 
#        new XML::Dumper->pl2xml($rbls , $g->{'rbls_list'});
#        $self->{'_options'}->{'rbls_list'} = new XML::Dumper()->xml2pl($g->{'rbls_list'});
#        $self->change;
#        $self->commit($self);
#    }
#    
#}
#
#sub delete_rbl($$) 
#{
#    my $self = instance(shift);
#    my $rbl_name = shift ;
#    my $rbls = rbls_list($self) ;
#    # we first recalculate the ranking because of deletion
#    # foreach entry were the rank is greater we set it s rank to rank-1
#    foreach my $rbl (keys %$rbls)
#    {
#        if($rbls->{$rbl}->{'rank'} > $rbls->{$rbl_name}->{'rank'})
#        {
#            $rbls->{$rbl}->{'rank'} = $rbls->{$rbl}->{'rank'} - 1;
#        }
#    }
#    delete($rbls->{$rbl_name}) ;
#    new XML::Dumper->pl2xml($rbls , $g->{'rbls_list'});
#    $self->{'_options'}->{'rbls_list'} = new XML::Dumper()->xml2pl($g->{'rbls_list'});
#    $self->change;
#    $self->commit($self);
#}
#
#sub reorder($$){
#    my $self = instance(shift);
#    #order is  the list of rbls in the new order.
#    my $order = shift;
#    my $count =1;
#    my $rbls = rbls_list($self);
#    foreach (@$order)
#    {
#        if(defined $rbls->{$_})
#        {
#            $rbls->{$_}->{'rank'}= $count;
#            $count ++;   
#        }
#    }
#    $self->{'_options'}->{'rbls_list'} = $rbls; 
#    $self->change;
#}
#
#sub confirm_order($)
#{
#    my $self = instance(shift);
#    if (defined $self->{'_options'}->{'rbls_list'})
#    {
#        new XML::Dumper->pl2xml( $self->{'_options'}->{'rbls_list'} , $g->{'rbls_list'});
#    }
#}

#selective greylisting
sub selective_greylisting()
{
    my $self = instance(shift);
    return $self->config->{'selective_greylisting'};
}

sub enable_selective_greylisting ($)
{
    my $self = instance(shift);
    $self->config->{'selective_greylisting'} = 1;
    $self->change;

}

sub disable_selective_greylisting ($)
{
    my $self = instance(shift);
    $self->config->{'selective_greylisting'} = 0;
    $self->change;
}

# These subs just call selective greylisting, for it's not relevant to postfix since postfwd migration
# We just need the rc_greylisting smtpd_restriction_class, independent from which greylisting type has been chosen
sub greylisting($) {
    my $self = instance(shift);
	return $self->selective_greylisting();
}

sub enable_greylisting($){
    my $self = instance(shift);
	$self->enable_selective_greylisting();
}

sub disable_greylisting($){
    my $self = instance(shift);
	$self->disable_selective_greylisting();
}


sub smtpd_timeout($@)
{
    my $self = instance(shift);
    if(@_)
    {
	$self->config->{'smtpd_timeout'} = shift;
	$self->change;
    }
    return $self->config->{'smtpd_timeout'};
	
}

sub smtpd_queuetime($@){
	my $self = instance(shift);
	if(@_){
		$self->config->{'smtpd_queuetime'} = shift;
		$self->change;
	}

	return (defined($self->config->{'smtpd_queuetime'}) ? $self->config->{'smtpd_queuetime'} : 6);
}

sub smtpcrypt($@){
	my $self = instance(shift);
	if(@_){
		$self->config->{'smtpcrypt'} = shift;
		$self->change;
	}

	return (defined($self->config->{'smtpcrypt'}) ? $self->config->{'smtpcrypt'} : 0);
}


sub add_ip_range_whitelist($@)
{
    my $self = instance(shift);
    my $start = shift;
    my $end = shift;
    my $description = shift;

    my $range = {
        start => $start,
        end => $end,
        description => $description,
    };

    my $ranges = $self->ip_range_whitelist;
    
    if( $self->check_overlapping( $ranges, $range ) )
    {
        throw Underground8::Exception::EntryExists();
    }

    push @$ranges, $range;
    $self->ip_range_whitelist($ranges);
    $self->change();
}

sub check_range_overlap($$$$$)
{
    my $self = shift;
    my $start1 = ip_dec( shift );
    my $end1 = ip_dec( shift );
    my $start2 = ip_dec( shift );
    my $end2 = ip_dec( shift );

    if( ($end2 < $start1) || ($start2 > $end1) )
    {
        return 0;
    }
    
    return 1;
}

sub check_overlapping($$$)
{
    my $self = shift;
    my $arr_ref = shift;	# [ {start, end, address, description } ]
    my $hash_ref = shift;	# { start, end, address, description }

    my ($start, $end);
    if( defined $hash_ref->{'address'} ) 
    {
        # single IP
        $start = $hash_ref->{'address'};
        $end = $hash_ref->{'address'};
    } 
    elsif( defined $hash_ref->{'start'} && defined $hash_ref->{'end'} ) 
    {
        # IP range
        $start = $hash_ref->{'start'};
        $end = $hash_ref->{'end'};
    } 
    else
    {
	    return 1;
    }

    for my $item ( @$arr_ref )
    {
        if( defined $item->{'address'} ) 
        {
            # single IP
            if( $self->check_range_overlap( $item->{'address'}, $item->{'address'}, $start, $end ) )
            {
                return 1;
            }
        } 
        elsif( defined $item->{'start'} && defined $item->{'end'} ) 
        {
            # IP range
            if( $self->check_range_overlap( $item->{'start'}, $item->{'end'}, $start, $end ) )
            {
                return 1;
            }
        }
    }
    
    return 0;
}

sub make_range($$)
{
    my $self = instance(shift);
    my $range = shift;
    my $new_range = {};
    
    if (ref($range) eq 'HASH' && defined($range->{'start'}) && $range->{'start'} ne '' && 
        defined($range->{'end'}) && $range->{'end'} ne '')
    {   
        if ((ip_dec($range->{'end'}) - ip_dec($range->{'start'})) > 65535)
        {
            throw Underground8::Exception::TooBigRange();
        }
        elsif(ip_dec($range->{'start'}) <= ip_dec($range->{'end'}))
        {
            for(my $i=ip_dec($range->{'start'});$i<ip_dec($range->{'end'})+1;$i++)
            {
                $new_range->{dec_ip($i)} = '1';
            }
        }
        else
        {   
            throw Underground8::Exception::FalseRange();
        }   
    }
    elsif(ref($range) eq 'ARRAY')
    {
        foreach my $entry (@$range)
        {
            if(defined($entry->{'start'}) && $entry->{'start'} ne '' && defined($entry->{'end'}) && $entry->{'end'} ne '')
            {
                if ((ip_dec($entry->{'end'}) - ip_dec($entry->{'start'})) > 65535)
                {
                    throw Underground8::Exception::TooBigRange();
                }
                elsif(ip_dec($entry->{'start'}) <= ip_dec($entry->{'end'}))
                {
                    for(my $i=ip_dec($entry->{'start'});$i<ip_dec($entry->{'end'})+1;$i++)
                    {
                        $new_range->{dec_ip($i)} = '1';
                    }
                }
                else
                {
                    throw Underground8::Exception::FalseRange();
                }
               
            }
            elsif(defined($entry->{'start'}) && $entry->{'start'} ne '' && defined($entry->{'end'}) && $entry->{'end'} eq '')
            {
                $new_range->{$entry->{'start'}} = '1';
            }
        }                    
    }
    return $new_range;        
}

sub del_ip_range_whitelist($$)
{
    my $self = instance(shift);
    my $start = shift;

    my $loop = 0;
    my $current_ranges = $self->ip_range_whitelist;
    foreach my $range (@{$current_ranges})
    {
        if($range->{'start'} eq "$start")
        {
            splice(@{$current_ranges},$loop,1);
            $self->ip_range_whitelist($current_ranges);
            $self->change;
            return 1;
        }
        $loop++;	
    }
    throw Underground8::Exception::EntryNotExists();
}

sub dec_ip
{
    if ($_[0] =~ /^\d+$/)
    {
        return (($_[0] >> 24 & 255) . "." . ($_[0] >> 16 & 255) . "." . ($_[0] >> 8 & 255) . "." . ($_[0] & 255));
    }
    else
    {
        return 0;
    }
}

sub ip_dec
{
    my $ip = $_[0];
    if ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/)
    {
        return (($1 << 24) + ($2 << 16) + ($3 << 8) + $4);
    }
    else
    {
        return 0;
    }
}

sub cacert_assign( $$$ )
{
    my $self = instance(shift);
    my $smtp_name = shift;
    my $cacert = shift;
    
    # cacert holds the name (with full path) of the temporary certificate
    if( $cacert && (-f $cacert) )
    {
	# check if the certificate is OK. If it is OK then rename it by copying via SLAVE and then delete it, else delete it
	my ($exit_code, $output) = safe_system( "$g->{'cmd_openssl'} verify $cacert | $g->{'cmd_grep'} -i -w 'OK'", 0, 1 );
	my $cert_ok = ! $exit_code;

	if( $cert_ok ) 
    {
	    my $buffer;
        $self->slave->cacert_initialize_upload( $smtp_name );
        open( UL, $cacert ) or throw Underground8::Exception( $cacert );
        
        while( read( UL, $buffer, 1024 ) )
        {
            $self->slave->cacert_write_file( $smtp_name, $buffer );
        }
        
        # Write an empty buffer afterwards to close the filehandles...
        $buffer = '';
        $self->slave->cacert_write_file( $smtp_name, $buffer );
        $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'has_cacert'} = 1;
	} 
    else 
    {
	    throw Underground8::Exception::CertificateInvalid;
	}

	# delete the certificate
	unlink( $cacert );
    }
}

sub cacert_unassign( $$$ )
{
    my $self = instance(shift);
    my $smtp_name = shift;

    if( ! exists( $self->{'_domains'}->{'relay_smtp'}->{$smtp_name} ) )
    {
	    throw Underground8::Exception::SMTPServerNotExists;
    }

    $self->slave->cacert_delete( $smtp_name );
    $self->{'_domains'}->{'relay_smtp'}->{$smtp_name}->{'has_cacert'} = 0;
}

sub certificate_present()
{
    my $self = shift;
    my $str = $self->{'_config'}{'smtpd_tls_cert_file'};
    if ($str)
    {
        return ($str ne "") ? 1 : 0;
    }
    return 0;
}

sub privatekey_present()
{
    my $self = shift;
    my $str = $self->{'_config'}{'smtpd_tls_key_file'};
    if ($str)
    {
        return ($str ne "") ? 1 : 0;
    }
    return 0;
}

sub assign_cert($$)
{
    my $self = shift;
    my $cert = shift;
    
    # cacert holds the name (with full path) of the temporary certificate
    if( $cert && (-f $cert) )
    {
	    # check if the certificate is OK. If it is OK then rename it by copying via SLAVE and then delete it, else delete it
	    my ($exit_code, $output) = safe_system( "$g->{'cmd_openssl'} verify -CAfile $g->{'cfg_cacert_dir'}/ca-certificates.crt $cert | $g->{'cmd_grep'} -i -w 'OK'", 0, 1 );
        my $cert_ok = ! $exit_code;

        if( $cert_ok ) 
        {
            my $buffer;
            $self->slave->cert_initialize_upload();
            open( UL, $cert ) or throw Underground8::Exception( $cert );
            
            while( read( UL, $buffer, 1024 ) )
            {
                $self->slave->cert_write_file( $buffer );
            }
            # Write an empty buffer afterwards to close the filehandles...
            $self->slave->cert_write_file( '' );

            if( $self->privatekey_present && ! $self->slave->match_cert_pkey )
            {
                throw Underground8::Exception::NoMatchCertificatePrivatekey;
            }

            $self->{'_config'}->{'smtpd_tls_cert_file'} = "$g->{'cfg_cacert_dir'}/postfix-certificate";
            $self->change;
        } 
        else 
        {
            $self->{'_config'}->{'smtpd_tls_cert_file'} = "";
            throw Underground8::Exception::CertificateInvalid;
        }

        # delete the certificate
        unlink( $cert );
    }
}

sub assign_pkey($$)
{
    my $self = shift;
    my $cert = shift;

    # cacert holds the name (with full path) of the temporary certificate
    if( $cert && (-f $cert) )
    {
    	# check if the certificate is OK. If it is OK then rename it by copying via SLAVE and then delete it, else delete it
	    my ($exit_code, $output) = safe_system( "$g->{'cmd_openssl'} rsa -check -in $cert -noout -passin pass:nopaswd -passout pass:nopaswd | $g->{'cmd_grep'} -i -w 'OK'", 0, 1 );
	    my $cert_ok = ! $exit_code;

        if( $cert_ok )
        {
            my $buffer;
                $self->slave->pkey_initialize_upload();
                open( UL, $cert ) or throw Underground8::Exception( $cert );
                while( read( UL, $buffer, 1024 ) )
                {
                    $self->slave->pkey_write_file( $buffer );
                }
                # Write an empty buffer afterwards to close the filehandles...
                $self->slave->pkey_write_file( '' );

            if( $self->certificate_present && ! $self->slave->match_cert_pkey )
            {
            throw Underground8::Exception::NoMatchCertificatePrivatekey;
            }

                $self->{'_config'}->{'smtpd_tls_key_file'} = "$g->{'cfg_cacert_dir'}/postfix-privatekey";
            $self->change;
        }
        else
        {
                $self->{'_config'}->{'smtpd_tls_key_file'} = "";
        }
        
	# delete the certificate
        unlink( $cert );
    }
}

sub delete_cert()
{
    my $self = shift;
    $self->{'_config'}->{'smtpd_tls_cert_file'} = "";
    $self->change;
}

sub delete_pkey()
{
    my $self = shift;
    $self->{'_config'}->{'smtpd_tls_key_file'} = "";
    $self->change;
}


#
## export and import config-options.
## the special case of domains which start with
## numbers, like "234.com", needs to be covered
#
sub import_params ($$)
{
    my $self = instance(shift);
    my $import = shift;
    if (ref($import) eq 'HASH')
    {
        # loop through $import->{_domains}->{relay_domains}
        # and insert _ before every number-starting-domain
#        print STDERR Dumper($import);

        my $new_domain = undef;
        foreach my $domain (keys %{$import->{'_domains'}->{'relay_domains'}})
        {
            if ($domain =~ m/^_{1}/)
            {
                $new_domain = substr($domain, 1, length($domain)-1);
            }
            else
            {
                $new_domain = $domain;
            }

            %{$self->{'_domains'}->{'relay_domains'}->{$new_domain}} = 
                %{$import->{'_domains'}->{'relay_domains'}->{$domain}};
        }
        
        $self->{'_domains'}->{'relay_smtp'} = $import->{'_domains'}->{'relay_smtp'}; 

        foreach my $key (keys %$import)
        {
            if ($key ne "_domains")
            {
                $self->{$key} = $import->{$key};
            }
        }
#        print STDERR Dumper($self);

        $self->change;
    }
    else
    {
        warn 'No hash supplied!';
    }
}


sub export_params ($)
{
    my $self = instance(shift);
    my $export = undef;


    foreach my $key (keys %$self)
    {
        if ($key ne "_domains")
        {
            $export->{$key} = $self->{$key};
        }
    }

    # loop through $export->{_domains}->{relay_domains}
    # and insert _ before every number-starting-domain

    my $new_domain = undef;
    foreach my $domain (keys %{$self->{'_domains'}->{'relay_domains'}})
    {
        if ($domain =~ m/^\d{1}/)
        {
            $new_domain = '_' . $domain;
        }
        else
        {
            $new_domain = $domain;
        } 

        $export->{'_domains'}->{'relay_domains'}->{$new_domain}->{'dest_mailserver'} = 
            $self->{'_domains'}->{'relay_domains'}->{$domain}->{'dest_mailserver'};
        $export->{'_domains'}->{'relay_domains'}->{$new_domain}->{'enabled'} = 
            $self->{'_domains'}->{'relay_domains'}->{$domain}->{'enabled'};
    }

    $export->{'_domains'}->{'relay_smtp'} = $self->{'_domains'}->{'relay_smtp'};

#    print STDERR Dumper($export);
#    print STDERR Dumper($self);

    # usermaps are not being saved into the main XML, they have their own file
    delete $export->{'_usermaps'};

    delete $export->{'_slave'};
    delete $export->{'_has_changes'};
    return $export;
}


1;

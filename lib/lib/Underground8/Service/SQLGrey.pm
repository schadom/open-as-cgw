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


package Underground8::Service::SQLGrey;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::SQLGrey::SLAVE;
use Underground8::Exception::EntryExists;
use Underground8::Exception::EntryNotExists;

use Data::Dumper;

#Constructor
sub new ($$)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::SQLGrey::SLAVE();
    $self->{'_config'} = { greylisting => 1,
                           selective_greylisting => 0,
			   greylisting_authtime => 30,
			   greylisting_triplettime => 5,
			   greylisting_connectage => 24,
			   greylisting_domainlevel => 2,
			   greylisting_message => 'You have been greylisted.',
			 };
    $self->{'_ip_blacklist'} = {};
    $self->{'_ip_whitelist'} = {};
    $self->{'_addr_blacklist'} = {};
    $self->{'_addr_whitelist'} = {};
    $self->{'_ip_blacklist_has_changes'} = 0;
    $self->{'_ip_whitelist_has_changes'} = 0;
    $self->{'_addr_blacklist_has_changes'} = 0;
    $self->{'_addr_whitelist_has_changes'} = 0;
    $self->{'_mysql_host'} = 'localhost';
    $self->{'_mysql_database'} = 'sqlgrey';
    $self->{'_mysql_username'} = 'sqlgrey-user';
    $self->{'_mysql_password'} = '';
    return $self;
}



#### Accessors ####

sub config ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_config'};
}


sub slave ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_slave'};
}

sub initialized ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_initialized'};
}

sub ip_blacklist_has_changes ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_ip_blacklist_has_changes'};
}

sub ip_whitelist_has_changes ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_ip_whitelist_has_changes'};
}

sub addr_blacklist_has_changes ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_addr_blacklist_has_changes'};
}

sub addr_whitelist_has_changes ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_addr_whitelist_has_changes'};
}

sub mysql_username ($@)
{
    my $self = instance(shift);
    $self->{'_mysql_username'} = shift if @_;
    return $self->{'_mysql_username'};
}

sub mysql_database ($@)
{
    my $self = instance(shift);
    $self->{'_mysql_database'} = shift if @_;
    return $self->{'_mysql_database'};
}

sub mysql_host ($@)
{
    my $self = instance(shift);
    $self->{'_mysql_host'} = shift if @_;
    return $self->{'_mysql_host'};
}

sub mysql_password ($@)
{
    my $self = instance(shift);
    $self->{'_mysql_password'} = shift if @_;
    return $self->{'_mysql_password'};
}


#### CRUD Methods ####

###             ###
### Greylisting ###
###             ###
sub greylisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->config->{'greylisting'};
}

sub enable_greylisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'greylisting'} = 1;
    $self->change;
}

sub disable_greylisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'greylisting'} = 0;
    $self->change;
}

###                     ###
## selective greylisting ##
###                     ###
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

sub greylisting_triplettime ($;$) {
	my $self = instance(shift);
	my $val = shift;

	if($val) {
		$self->config->{'greylisting_triplettime'} = $val;
		$self->change;
	} else {
		return $self->config->{'greylisting_triplettime'};
	}
}

sub greylisting_authtime ($;$) {
	my $self = instance(shift);
	my $val = shift;

	if($val) {
		$self->config->{'greylisting_authtime'} = $val;
		$self->change;
	} else {
		return $self->config->{'greylisting_authtime'};
	}
}

sub greylisting_connectage ($;$) {
        my $self = instance(shift);
        my $val = shift;

        if($val) {
                $self->config->{'greylisting_connectage'} = $val;
                $self->change;
        } else {
                return $self->config->{'greylisting_connectage'};
        }
}

sub greylisting_domainlevel ($;$) {
        my $self = instance(shift);
        my $val = shift;

        if($val) {
                $self->config->{'greylisting_domainlevel'} = $val;
                $self->change;
        } else {
                return $self->config->{'greylisting_domainlevel'};
        }
}

sub greylisting_message ($;$) {
        my $self = instance(shift);
        my $val = shift;

        if($val) {
                $self->config->{'greylisting_message'} = $val;
                $self->change;
        } else {
                return $self->config->{'greylisting_message'};
        }
}

###                 ###
### Blacklisting IP ###
###                 ###
sub ip_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    return ($self->config->{'ip_blacklisting'} == 1) ? 1 : 0;
}

sub enable_ip_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'ip_blacklisting'} = 1;
    $self->{'_ip_blacklist_has_changes'} = 1;
    $self->change;
}

sub disable_ip_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'ip_blacklisting'} = 0;
    $self->{'_ip_blacklist_has_changes'} = 1;
    $self->change;
}

sub create_blacklist_ip ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $range_start = shift;
    my $range_end = shift;
    my $description = shift;

    my $range = {
        start => $range_start,
        end => $range_end,
        description => $description,
    };

    my $ranges = $self->{'_ip_blacklist'};

    foreach my $entry (@$ranges)
    {
        if ($self->check_range_overlap( $entry->{'start'}, $entry->{'end'}, $range_start, $range_end ))
        {
            throw Underground8::Exception::EntryExists();
        }
    }

    push @$ranges, $range;

    $self->{'_ip_blacklist_has_changes'} = 1;
    $self->change;
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

sub read_blacklist_ip ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_ip_blacklist'};
}

sub update_blacklist_ip ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $range = shift;
    my $description = shift;
    if ($self->blacklist_ip_exists($range))
    {
        $self->{'_ip_blacklist'}->{$range} = $description;
        $self->{'_ip_blacklist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}

sub delete_blacklist_ip ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $start = shift;

    my $loop = 0;
    my $current_ranges = $self->{'_ip_blacklist'};
    foreach my $range (@{$current_ranges})
    {
        if($range->{'start'} eq "$start")
        {
            splice(@{$current_ranges},$loop,1);
            $self->{'_ip_blacklist'} = $current_ranges;
    	    $self->{'_ip_blacklist_has_changes'} = 1;
            $self->change;
            return 1;
        }
        $loop++;	
    }
    throw Underground8::Exception::EntryNotExists();
}




###                 ###
### Whitelisting IP ###
###                 ###

sub ip_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    return ($self->config->{'ip_whitelisting'} == 1) ? 1 : 0;
}

sub enable_ip_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'ip_whitelisting'} = 1;
    $self->{'_ip_whitelist_has_changes'} = 1;
    $self->change;
}

sub disable_ip_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'ip_whitelisting'} = 0;
    $self->{'_ip_whitelist_has_changes'} = 1;
    $self->change;
}

sub create_whitelist_ip ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $range = shift;
    my $description = shift;

    if (!$self->whitelist_ip_exists($range))
    {
        $self->{'_ip_whitelist'}->{$range} = $description;
        $self->{'_ip_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryExists();
    }
}

# returns all whitelisted ip ranges
sub read_whitelist_ip ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_ip_whitelist'};                 
}

sub update_whitelist_ip ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $range = shift;
    my $description = shift;
    if ($self->whitelist_ip_exists($range))
    {
        $self->{'_ip_whitelist'}->{$range} = $description;
        $self->{'_ip_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
       throw Underground8::Exception::EntryNotExists();
    }
}

sub delete_whitelist_ip ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $range = shift;
    if ($self->whitelist_ip_exists($range))
    {
        delete($self->{'_ip_whitelist'}->{$range});
        $self->{'_ip_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}




###                            ###
### Blacklisting Email Address ###
###                            ###

sub addr_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    return ($self->config->{'addr_blacklisting'} == 1) ? 1 : 0;
}

sub enable_addr_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'addr_blacklisting'} = 1;
    $self->{'_addr_blacklist_has_changes'} = 1;
    $self->change;
}

sub disable_addr_blacklisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'addr_blacklisting'} = 0;
    $self->{'_addr_blacklist_has_changes'} = 1;
    $self->change;
}

sub create_blacklist_addr ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    my $description = shift;

    if (!$self->blacklist_addr_exists($addr))
    {
        $self->{'_addr_blacklist'}->{$addr} = $description;
        $self->{'_addr_blacklist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryExists();
    }
}

sub read_blacklist_addr ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_addr_blacklist'};
}

sub update_blacklist_addr ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    my $description = shift;
    if ($self->blacklist_addr_exists($addr))
    {
        $self->{'_addr_blacklist'}->{$addr} = $description;
        $self->{'_addr_blacklist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}

sub delete_blacklist_addr ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    if ($self->blacklist_addr_exists($addr))
    {
        delete($self->{'_addr_blacklist'}->{$addr});
        $self->{'_addr_blacklist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}






###                            ###
### Whitelisting Email Address ###
###                            ###

sub addr_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    return ($self->config->{'addr_whitelisting'} == 1 ) ? 1 : 0;
}

sub enable_addr_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'addr_whitelisting'} = 1;
    $self->{'_addr_whitelist_has_changes'} = 1;
    $self->change;
}

sub disable_addr_whitelisting ($)
{
    my $self = instance(shift, __PACKAGE__);
    $self->config->{'addr_whitelisting'} = 0;
    $self->{'_addr_whitelist_has_changes'} = 1;
    $self->change;
}

sub create_whitelist_addr ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    my $description = shift;

    if (!$self->whitelist_addr_exists($addr))
    {
        $self->{'_addr_whitelist'}->{$addr} = $description;
        $self->{'_addr_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryExists();
    }
}

sub read_whitelist_addr ($)
{
    my $self = instance(shift, __PACKAGE__);
    return $self->{'_addr_whitelist'};
}

sub update_whitelist_addr ($$$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    my $description = shift;
    if ($self->whitelist_addr_exists($addr))
    {
        $self->{'_addr_whitelist'}->{$addr} = $description;
        $self->{'_addr_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}

sub delete_whitelist_addr ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    if ($self->whitelist_addr_exists($addr))
    {
        delete($self->{'_addr_whitelist'}->{$addr});
        $self->{'_addr_whitelist_has_changes'} = 1;
        $self->change;
    }
    else
    {
        throw Underground8::Exception::EntryNotExists();
    }
}




###                  ###
### Existance Checks ###
###                  ###

sub blacklist_ip_exists ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $ip = shift;
    if (exists($self->{'_ip_blacklist'}->{$ip}))
    {
        return 1;
    }
    return 0;
}


sub whitelist_ip_exists ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $ip = shift;
    if (exists($self->{'_ip_whitelist'}->{$ip}))
    {
        return 1;
    }
    return 0;
}



sub blacklist_addr_exists ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    if (exists($self->{'_addr_blacklist'}->{$addr}))
    {
        return 1;
    }
    return 0;
}



sub whitelist_addr_exists ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $addr = shift;
    if (exists($self->{'_addr_whitelist'}->{$addr}))
    {
        return 1;
    }
    return 0;
}




###                              ###
### Commiting and Config writing ###
###                              ###

# This function is used for changes in service configuration, like
# disabling greylisting or enabling whitelisting
sub commit ($)
{
    my $self = instance(shift, __PACKAGE__);
    print STDERR "We are in sqlgrey commit\n";
    $self->init_slave();
    $self->slave->write_config($self->mysql_host,
                               $self->mysql_database,
                               $self->mysql_username,
                               $self->mysql_password,
                               $self->config);
    $self->slave->service_restart();

# TODO REMOVE DATABASE STUFF RELATED TO WHITELIST OR BLACKLIST
# Black/Whitelists will be done in postfwd, not here anymore!
#    $self->commit_ip_blacklist() if ($self->ip_blacklist_has_changes());
#    $self->commit_ip_whitelist($self->config) if ($self->ip_whitelist_has_changes());
#    $self->commit_addr_blacklist() if ($self->addr_blacklist_has_changes());
#    $self->commit_addr_whitelist($self->config) if ($self->addr_whitelist_has_changes());

    $self->unchange;
}

sub init_slave
{
    my $self = instance(shift, __PACKAGE__);
    $self->slave->initialize($self->mysql_host,
                             $self->mysql_database,
                             $self->mysql_username,
                             $self->mysql_password 
                             ) unless $self->slave->initialized();
}


sub commit_ip_blacklist ($)
{
    my $self = instance(shift, __PACKAGE__);
    my %hash;
    
    # if the blacklisting are disabled then we delete the content of the database by sending an empty hash
    if( $self->ip_blacklisting )
    {
	foreach my $range (@{ $self->{'_ip_blacklist'} })
	{
	    my @arr = $self->calculate( $range->{'start'}, $range->{'end'} );
	    foreach my $class (@arr)
	    {
		$hash{ $class } = $range->{'description'};
	    }
	}
    }
    
    $self->init_slave();
    $self->slave->commit_ip_blacklist( \%hash );
    $self->{'_ip_blacklist_has_changes'} = 0;
}

sub commit_ip_whitelist ($)
{
    my $self = instance(shift, __PACKAGE__);
    my $config = shift;
    my $hash_ref;
    
    # if the blacklisting are disabled then we delete the content of the database by sending an empty hash
    if( $self->ip_whitelisting ) {
	$hash_ref = $self->{'_ip_whitelist'};
    } else {
	$hash_ref = {};
    }
    
    $self->init_slave();
    $self->slave->commit_ip_whitelist( $hash_ref, $config );
    $self->{'_ip_whitelist_has_changes'} = 0;
}

sub commit_addr_blacklist ($)
{
    my $self = instance(shift, __PACKAGE__);
    my $hash_ref;
    
    # if the blacklisting are disabled then we delete the content of the database by sending an empty hash
    if( $self->addr_blacklisting ) {
	$hash_ref = $self->{'_addr_blacklist'};
    } else {
	$hash_ref = {};
    }
    
    $self->init_slave();
    $self->slave->commit_addr_blacklist( $hash_ref );
    $self->{'_addr_blacklist_has_changes'} = 0;
}

sub commit_addr_whitelist ($)
{
    my $self = instance(shift, __PACKAGE__);
    my $config = shift;
    my $hash_ref;
    
    # if the blacklisting are disabled then we delete the content of the database by sending an empty hash
    if( $self->addr_whitelisting ) {
	$hash_ref = $self->{'_addr_whitelist'};
    } else {
	$hash_ref = {};
    }
    
    $self->init_slave();
    $self->slave->commit_addr_whitelist( $hash_ref, $config );
    $self->{'_addr_whitelist_has_changes'} = 0;
}


#### Overloading of the SUPER import_ and export_params method ####
#### (needed for slave initialization                          ####

sub export_params ($)
{
    my $self = instance(shift, __PACKAGE__);
    my $export;
    $export->{'_mysql_username'} = $self->mysql_username;
    $export->{'_mysql_password'} = $self->mysql_password;
    $export->{'_mysql_database'} = $self->mysql_database;
    $export->{'_mysql_host'} = $self->mysql_host;
    $export->{'_config'} = $self->config;

    $export->{'_ip_blacklist'} = $self->{'_ip_blacklist'};
    $export->{'_ip_whitelist'} = $self->export_prepare($self->{'_ip_whitelist'});
    $export->{'_addr_blacklist'} = $self->export_prepare($self->{'_addr_blacklist'});
    $export->{'_addr_whitelist'} = $self->export_prepare($self->{'_addr_whitelist'});
    return $export;
}

sub export_prepare($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $vals = shift;
    my $export = [];

    my $hash_size = keys %$vals;
    
    my $i = 0;

    if ($hash_size > 0)
    {
        while ( my($key, $value) = each(%$vals) )
        {
            $export->[$i]->{'address'} = $key;
            $export->[$i]->{'description'} = $value;
            $i++;
        }
    }
    return $export;
}

=head2
The following 3 functions are used to calculate full network classes from any custom IP range
Author: Iulian Radu, Underground8 Wien
=cut

sub is_first_addr( $$$ )
{
    my $self = shift;
    my $i = shift;
    my @IP = @_;
    
    for( ; $i < 4; $i++ )
    {
	if( $IP[ $i ] != 0 )
	{
	    return 0;
	}
    }

    return 1;
}

sub is_last_addr( $$$ )
{
    my $self = shift;
    my $i = shift;
    my @IP = @_;
    
    for( ; $i < 4; $i++ )
    {
	if( $IP[ $i ] != 255 )
	{
	    return 0;
	}
    }

    return 1;
}

sub calculate( $$$ )
{
    my $self = shift;
    my $IP1 = shift;
    my $IP2 = shift;

    my @IP1fields = split( /\./, $IP1 );
    my @IP2fields = split( /\./, $IP2 );

    my (@arr, $base, $i, $j, $k);
    
    $base = "";
    for( $i = 0; $i < 4; $i++ )
    {
	if( $IP1fields[ $i ] != $IP2fields[ $i ] )
	{
	    last;
	}
	$base .= ($i ? ".": "") . $IP1fields[ $i ];
    }
    # $i holds first not equal field number

    # the two values are equal
    if( $i == 4 )
    {
	return ( $IP1 )
    }

    # there are diferences only in the last field and it is not covered a full class C
    if( ($i == 3) && (($IP1fields[ 3 ] > 0) || ($IP2fields[ 3 ] < 255)) )
    {
	for( $j = $IP1fields[ 3 ]; $j <= $IP2fields[ 3 ]; $j++ )
	{
	    push( @arr, "$base.$j" );
	}
	return @arr;
    }

    # if there is a clean class then return the corresponding answer
    if( $self->is_first_addr( $i, @IP1fields ) && $self->is_last_addr( $i, @IP2fields ) )
    {
	my $class = $base;
	$class .= ".%" x (4 - $i);
	return ( $class );
    }

    my ($class1, $class2);
    $class1 = $IP1;
    while( $IP1fields[ $i ] <= $IP2fields[ $i ] )
    {
	if( $i ) {
	    $class2 = $base . "." . $IP1fields[ $i ];
	} else {
	    $class2 = $IP1fields[ $i ];
	}
	if( $IP1fields[ $i ] < $IP2fields[ $i ] ) {
	    $class2 .= ".255" x (3 - $i);
	} else {
	    for( $j = $i + 1; $j < 4; $j++ )
	    {
		$class2 .= "." . $IP2fields[ $j ];
	    }
	}

	push( @arr, $self->calculate( $class1, $class2 ) );
	
	# move to the next class
	$IP1fields[ $i ]++;
	
	# the new class is aligned to its bottom
	if( $i ) {
	    $class1 = $base . "." . $IP1fields[ $i ];
	} else {
	    $class1 = $IP1fields[ $i ];
	}
	$class1 .= ".0" x (3 - $i);
    }

    return @arr;
}

1;

__DATA__

sub import_params ($$)
{
    my $self = instance(shift, __PACKAGE__);
    my $import = shift;

    #print Dumper $import;

    my $entry;
    my @gold = qw(_ip_blacklist _ip_whitelist _addr_blacklist _addr_whitelist);

    if (ref($import) eq 'HASH')                                                                                              
    {
        $self->mysql_host($import->{'_mysql_host'});
        $self->mysql_database($import->{'_mysql_database'});
        $self->mysql_username($import->{'_mysql_username'});
        $self->mysql_password($import->{'_mysql_password'});
        $self->{'_config'} = $import->{'_config'};

    my $range = {
    	    start => "1.2.3.4",
	    end => "5.6.7.8",
            description => 'description'
    };
    $self->{'_ip_blacklist'} = [ $range ];
        
        foreach my $field (@gold)
        {

            if (exists($import->{$field}))
            {

                my $list = $import->{$field};

                # one or more black/whitelist entries in xml (works now with one or more)
                if (ref($list) eq 'ARRAY')
                {
                    # one entry is handled in another way than multiple entries
                    if (@{$list} > 1)
                    {
                        foreach $entry ( @{$list} )
                        {
			    if(exists($entry->{'address'})) {
                        	$self->{$field}->{$entry->{'address'}} = $entry->{'description'};
			    } elsif(exists($entry->{'start'})) {
                        	$self->{$field}->{$entry->{'start'}} = $entry->{'end'};
			    }
                        }
                    }
                    else
                    {
                        # check if there is sthg usable in the list
                        if (exists($list->[0]->{'address'}))
                        {
                            if (ref($list->[0]->{'address'}) eq 'SCALAR')
                            {
                                $self->{$field}->{ $list->[0]->{'address'} } = $list->[0]->{'description'};
                            }
                            else
                            {
                                $self->{$field} = {};
                            } 
                        }
			elsif(exists($list->[0]->{'start'}))
			{
                            if (ref($list->[0]->{'start'}) eq 'SCALAR')
                            {
				my $range = {
    				    start => $list->[0]->{'start'},
				    end => $list->[0]->{'end'},
			            description => $list->[0]->{'description'},
			        };

                                $self->{$field}->{ $list->[0]->{'start'} } = $list->[0]->{'end'};
                            }
                            else
                            {
                                $self->{$field} = {};
                            } 
			}
                        else
                        {
                            $self->{$field} = {};
                        }
                    }
                }
            }
        }
    }                                                                                                                        
    else                                                                                                                     
    {                                                                                                                        
        warn 'No valid configuration supplied!';
    }
}            

1; 

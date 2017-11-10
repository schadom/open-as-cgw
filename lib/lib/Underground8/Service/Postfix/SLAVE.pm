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


package Underground8::Service::Postfix::SLAVE;
use base Underground8::Service::SLAVE;

use Underground8::Utils;
use Carp;

use Error;
use Underground8::Exception::Execution;
use Underground8::Exception::FileOpen;
use Underground8::Exception::FileExists;
use strict;
use warnings;
use Template;
use Data::Dumper;
use XML::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('postfix');
    return $self;
}

# TODO
sub write_config ($$$$)
{
    my $self = instance(shift);
    my $config = shift;
    my $domains = shift;
    my $options = shift;
    my $ip_range_whitelist = shift;
	my $smtpcrypt_cryptotag = shift;

    $self->write_postfix_config( $config, $domains, $options, $smtpcrypt_cryptotag );
    $self->write_batv_config( $config, $domains, $options, $ip_range_whitelist );
    
    # write and map transport file
    $self->write_transport_file($domains);

    # write maps for quarantine
    $self->write_quarantine_maps();
    if(defined $ip_range_whitelist)
    {
        $self->write_bypass($ip_range_whitelist);
    }

	### DEPRICATED, now done via postfwd
    #no need to write this file every time
	# if(defined $config->{'selective_greylisting'} and $config->{'selective_greylisting'} == 1)
	# {
	#    $self->write_filter_dynip_file($config, $options);
	# }

	$self->write_header_checks_file;
}




# do the following:
# - copy master.cf.template over the original master.cf
# - write_transport_file
#
sub write_postfix_config ($$$)
{
    my $self = instance(shift);
    my $config = shift;    
    my $domains = shift;    
    my $options = shift;

    my $memory_factor = $self->memory_factor;

    # no sasl auth
    $config->{'smtpd_sasl_auth_enable'} = 'no';
	$config->{'smtpd_queuetime'} = 6 if !defined($config->{'smtpd_queuetime'});
    my $relay_smtpsrvs = $domains->{'relay_smtp'};
    while ( my ($smtpsrv, $smtpsrv_properties) = each(%$relay_smtpsrvs) )
    {
        if ($smtpsrv_properties->{'auth_enabled'} eq '1')
        {
	        # do sasl auth
            $config->{'smtpd_sasl_auth_enable'} = 'yes';
	        last;
        }
    }

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 

    my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam("amavis");

    my $vars = {
        config => $config,
        options => $options,
        domains => $domains->{'relay_domains'},
        memory_factor => $memory_factor,
        amavisuid => $uid,
        amavisgid => $gid,
    };

	# Generate /etc/postfix/main.cf
    my $config_content;
    $template->process($g->{'template_postfix_main_cf'},$vars,\$config_content) 
        or throw Underground8::Exception($template->error);
    open (POSTFIX_MAINCF,'>',$g->{'file_postfix_main_cf'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_main_cf'});
    print POSTFIX_MAINCF $config_content;
    close (POSTFIX_MAINCF); 

	# Generate /etc/postfix/master.cf
    $config_content = "";
    $template->process($g->{'template_postfix_master_cf'},$vars,\$config_content) 
        or throw Underground8::Exception($template->error);
    open (POSTFIX_MASTERCF,'>',$g->{'file_postfix_master_cf'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_master_cf'});
    print POSTFIX_MASTERCF $config_content;
    close (POSTFIX_MASTERCF);

	# Generate /etc/postfix/sasl/smtpd.conf
    $config_content = "";
    $template->process($g->{'template_postfix_sasl_smtpd_conf'},$vars,\$config_content)
        or throw Underground8::Exception($template->error);
    open(POSTFIX_SASL_SMTPD,'>',$g->{'file_postfix_sasl_smtpd_conf'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_sasl_smtpd_conf'});
    print POSTFIX_SASL_SMTPD $config_content;
    close(POSTFIX_SASL_SMTPD);

    safe_system($g->{'cmd_postfix_check'});
}

sub write_batv_config ($$$)
{
    my $self = instance(shift);
    my $config = shift;
    my $domains = shift;
    my $options = shift;
    my $ip_range_whitelist = shift;

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });


    my $vars = {
        config => $config,
        options => $options,
        domains => $domains->{'relay_domains'},
        iprange => $ip_range_whitelist,
    };

    # Write default for batv-filter
    my $config_content;
    $template->process($g->{'template_batv_default'},$vars,\$config_content)
        or throw Underground8::Exception($template->error);
    open (BATV_DEFAULT,'>',$g->{'file_batv_default'})
        or throw Underground8::Exception::FileOpen($g->{'file_batv_default'});
    print BATV_DEFAULT $config_content;
    close (BATV_DEFAULT);

    $config_content = "";
    $template->process($g->{'template_batv_key'},$vars,\$config_content)
        or throw Underground8::Exception($template->error);
    open (BATV_DEFAULT,'>',$g->{'file_batv_key'})
        or throw Underground8::Exception::FileOpen($g->{'file_batv_key'});
    print BATV_DEFAULT $config_content;
    close (BATV_DEFAULT);

    $config_content = "";
    $template->process($g->{'template_batv_relay'},$vars,\$config_content)
        or throw Underground8::Exception($template->error);
    open (BATV_DEFAULT,'>',$g->{'file_batv_relay'})
        or throw Underground8::Exception::FileOpen($g->{'file_batv_relay'});
    print BATV_DEFAULT $config_content;
    close (BATV_DEFAULT);

    $config_content = "";
    $template->process($g->{'template_batv_domains'},$vars,\$config_content)
        or throw Underground8::Exception($template->error);
    open (BATV_DEFAULT,'>',$g->{'file_batv_domains'})
        or throw Underground8::Exception::FileOpen($g->{'file_batv_domains'});
    print BATV_DEFAULT $config_content;
    close (BATV_DEFAULT);


}


sub service_batv_restart ($)
{
    my $self = instance(shift);

	## BATV is not supported by now
    # my $command = $g->{'cmd_batv_restart'};
    # my $output = safe_system($command);
	return 1;
}


sub service_start ($)
{
    my $self = instance(shift);
    my $command = $g->{'cmd_postfix_start'};
    my $output = safe_system($command);
}


sub service_stop ($)
{
    my $self = instance(shift);
    my $command = $g->{'cmd_postfix_stop'};
    my $output = safe_system($command);
}


sub service_restart ($)
{
    my $self = instance(shift);
    my $command = $g->{'cmd_postfix_restart'};
    my $output = safe_system($command);
}



sub service_reload ($)
{
    my $self = instance(shift);
    my $command = $g->{'cmd_postfix_reload'};
    my $output = safe_system($command);
}


# do the following:
# - write formated text into transport file,: domain.com smtp:[1.2.3.4]:25
# - execute postmap to generate db file
#
sub write_transport_file ($$)
{
    my $self = instance(shift);
    my $domains  = shift;

    open (TRANSPORT, '>', $g->{'file_postfix_transport'})
        or carp "Could not open " . $g->{'file_postfix_transport'} . ", maybe bad access rights";

    while ( (my $domain, my $domain_properties) = each(%{$domains->{'relay_domains'}}) )
    {
        if ($domain_properties->{'enabled'} eq 'yes')
        {
	    my $smtp_properties = $domains->{'relay_smtp'}->{ $domain_properties->{'dest_mailserver'} };
            print TRANSPORT sprintf( "%s smtp:[%s]:%d\n", $domain, $smtp_properties->{'addr'}, $smtp_properties->{'port'} );
        }
    }

    close TRANSPORT or carp "Could not close " . $g->{'file_postfix_transport'};

    # set the local child handler to nothing
    my $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_transport'});
    my $output = safe_system($command);
}

sub write_bypass ($$)
{
    my $self = instance(shift);
    my $ip_range_whitelist = shift;

    my $template = Template->new ({
				      INCLUDE_PATH => $g->{'cfg_template_dir'},
				  });  
    
    my $options = {
	ip_range_whitelist => $ip_range_whitelist
    };
    
    my $config_content;
    $template->process($g->{'template_postfix_amavis_bypass_internal_filter'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (AMAVIS_BYPASS_INTERNAL,'>',$g->{'file_postfix_amavis_bypass_internal_filter'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_bypass_internal_filter'});
    
    print AMAVIS_BYPASS_INTERNAL $config_content;
    
    close (AMAVIS_BYPASS_INTERNAL);

    # the same for warnings
    
    $config_content = "";
    $template->process($g->{'template_postfix_amavis_bypass_internal_warn'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (AMAVIS_BYPASS_INTERNAL,'>',$g->{'file_postfix_amavis_bypass_internal_warn'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_bypass_internal_warn'});
    
    print AMAVIS_BYPASS_INTERNAL $config_content;
    
    close (AMAVIS_BYPASS_INTERNAL); 

    $config_content = "";
    $template->process($g->{'template_postfix_amavis_bypass_internal_accept'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (AMAVIS_BYPASS_INTERNAL,'>',$g->{'file_postfix_amavis_bypass_internal_accept'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_amavis_bypass_internal_accept'});
    
    print AMAVIS_BYPASS_INTERNAL $config_content;
    
    close (AMAVIS_BYPASS_INTERNAL);

    $config_content = "";
    $template->process($g->{'template_postfix_mynetworks'},$options,\$config_content)
      or throw Underground8::Exception($template->error);

    open (AMAVIS_BYPASS_INTERNAL,'>',$g->{'file_postfix_mynetworks'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_mynetworks'});

    print AMAVIS_BYPASS_INTERNAL $config_content;

    close (AMAVIS_BYPASS_INTERNAL);


    my $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_bypass_internal_filter'});
    my $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_bypass_internal_warn'});
    $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_amavis_bypass_internal_accept'});
    $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_mynetworks'});
    $output = safe_system($command);
}


sub write_quarantine_maps ($$)
{
    my $self = instance(shift);
    my $quarantine = shift;
    my $alias = shift;

    # if there is no given quarantine mailbox, use default
    if (!$quarantine)
    {
        $quarantine = "quarantine";
    }

    if (!$alias)
    {
        my $domain = `hostname -d`;
        chomp($domain);
        $alias = $quarantine ."@". $domain;
    }

    my $template = Template->new ({
				      INCLUDE_PATH => $g->{'cfg_template_dir'},
				  });  
    
    my $options = {
        quarantine => $quarantine,
        alias => $alias,
    };
    
    my $config_content;

    $template->process($g->{'template_postfix_local_rcpt_map'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (LOCAL_RCPT_MAP,'>',$g->{'file_postfix_local_rcpt_map'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_local_rcpt_map'});
    
    print LOCAL_RCPT_MAP $config_content;
    
    close (LOCAL_RCPT_MAP);

    
    $config_content = "";
    $template->process($g->{'template_postfix_mbox_transport'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (MBOX_TRANSPORT,'>',$g->{'file_postfix_mbox_transport'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_mbox_transport'});
    
    print MBOX_TRANSPORT $config_content;
    
    close (MBOX_TRANSPORT); 

    $config_content = "";
    $template->process($g->{'template_postfix_virtual_mbox'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (VIRTUAL_MBOX,'>',$g->{'file_postfix_virtual_mbox'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_virtual_mbox'});
    
    print VIRTUAL_MBOX $config_content;
    
    close (VIRTUAL_MBOX);  

    $config_content = "";
    $template->process($g->{'template_postfix_virtual_alias'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (VIRTUAL_ALIAS,'>',$g->{'file_postfix_virtual_alias'})
      or throw Underground8::Exception::FileOpen($g->{'file_postfix_virtual_alias'});
    
    print VIRTUAL_ALIAS $config_content;
    
    close (VIRTUAL_ALIAS);  

    my $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_local_rcpt_map'});
    my $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_virtual_mbox'});
    $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_mbox_transport'});
    $output = safe_system($command);
    $command = ($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_virtual_alias'});
    $output = safe_system($command);
}



=head1
Function: initialize_upload( filename )
Used to setup communication with the slave
=cut
sub cacert_initialize_upload ($$)
{
    my $self = instance(shift);
    my $file = shift;

    my $cacert = "$g->{'cfg_cacert_dir'}/$file";

    # Return 0 if the file that we should save is already there
    if( -f $cacert )
    {
        unlink( $cacert );
    }
    # Check if a file upload is already in progress
    # Return 2 if it's in progress, 
    # so that the caller can cancel the upload
    # if the upload hangs for example or a copy wasn't finished cleanly
    if (defined $self->{'_ul'} && 
        defined $self->{'_ul'}->{$file} && 
        defined $self->{'_ul'}->{$file}->{'_status'} &&
        $self->{'_ul'}->{$file}->{'_status'} == 1)
    {
        throw Underground8::Exception::FileInUse( $file );
    }

    open( $self->{'_ul'}->{$file}->{'_handle'}, ">$cacert" ) or throw Underground8::Exception::FileOpen( $cacert );
    $self->{'_ul'}->{$file}->{'_status'} = 1;
    return 1;
}

sub cacert_write_file ($$$)
{
    # Required Values:
    # - Filename of CA certificate
    # - Content
    my $self = instance(shift);
    my $file = shift;
    my $content = shift;

    my $cacert = "$g->{'cfg_cacert_dir'}/$file";
    my $global_cacert = "$g->{'cfg_cacert_dir'}/ca-certificates.crt";
    
    if (ref($self->{'_ul'}->{$file}->{'_handle'}) ne 'GLOB')
    {
        throw Underground8::Exception("File Handle not found");;
    }
    
    # Return 2: Got an emtpy content, End of File reached, buffer closed
    if (length $content == 0)
    {
        close $self->{'_ul'}->{$file}->{'_handle'};
        delete $self->{'_ul'}->{$file};

	# we need to create the new ca-file
	if( -f "$global_cacert" ) {
	    safe_system( "$g->{cmd_cat} '$cacert' >> '$global_cacert'" );
	} else {
	    safe_system( "$g->{cmd_cat} '$g->{ca_certificates}' '$cacert' > '$global_cacert'" );
	}
	
        return 2;
    } else {
        print { $self->{'_ul'}->{$file}->{'_handle'} } $content;
        return 1;
    }
    return 0;
}

sub cacert_delete ($$)
{
    my $self = instance(shift);
    my $smtp_name = shift;

    my $capath = "$g->{'cfg_cacert_dir'}";
    my $cacert = "$g->{'cfg_cacert_dir'}/$smtp_name";
    my $global_cacert = "$g->{'cfg_cacert_dir'}/ca-certificates.crt";

    # remove this certificate
    unlink( $cacert );

    # concatenate all the other certificates
    safe_system( "$g->{cmd_cat} '$g->{ca_certificates}' '$capath/smtp'* > '$global_cacert'", 0, 1 );
    
    return 0;
}

# postfix certificate
sub cert_initialize_upload ($$)
{
    my $self = instance(shift);

    my $file = "postfix-certificate";
    my $cert = "$g->{'cfg_cacert_dir'}/$file";

    # Return 0 if the file that we should save is already there
    if( -f $cert )
    {
        unlink( $cert );
    }
    # Check if a file upload is already in progress
    # Return 2 if it's in progress, 
    # so that the caller can cancel the upload
    # if the upload hangs for example or a copy wasn't finished cleanly
    if (defined $self->{'_ul'} && 
        defined $self->{'_ul'}->{$file} && 
        defined $self->{'_ul'}->{$file}->{'_status'} &&
        $self->{'_ul'}->{$file}->{'_status'} == 1)
    {
        throw Underground8::Exception::FileInUse( $file );
    }

    open( $self->{'_ul'}->{$file}->{'_handle'}, ">$cert" ) or throw Underground8::Exception::FileOpen( $cert );
    $self->{'_ul'}->{$file}->{'_status'} = 1;
    return 1;
}

sub cert_write_file ($$$)
{
    # Required Values:
    # - Filename of CA certificate
    # - Content
    my $self = instance(shift);
    my $content = shift;

    my $file = "postfix-certificate";
    my $cert = "$g->{'cfg_cacert_dir'}/$file";
    
    if (ref($self->{'_ul'}->{$file}->{'_handle'}) ne 'GLOB')
    {
        throw Underground8::Exception("File Handle not found");;
    }
    
    # Return 2: Got an emtpy content, End of File reached, buffer closed
    if (length $content == 0)
    {
        close $self->{'_ul'}->{$file}->{'_handle'};
        delete $self->{'_ul'}->{$file};

#        my $sys_arg = quotemeta("smtpd_tls_cert_file=$cert");
#        my $command = $g->{'cmd_postfix_postconf'}." -e $sys_arg";
#        my $output = safe_system($command);

        return 2;
    } else {
        print { $self->{'_ul'}->{$file}->{'_handle'} } $content;
        return 1;
    }
    return 0;
}

# postfix private key
sub pkey_initialize_upload ($$)
{
    my $self = instance(shift);

    my $file = "postfix-privatekey";
    my $cert = "$g->{'cfg_cacert_dir'}/$file";

    # Return 0 if the file that we should save is already there
    if( -f $cert )
    {
        unlink( $cert );
    }
    # Check if a file upload is already in progress
    # Return 2 if it's in progress, 
    # so that the caller can cancel the upload
    # if the upload hangs for example or a copy wasn't finished cleanly
    if (defined $self->{'_ul'} && 
        defined $self->{'_ul'}->{$file} && 
        defined $self->{'_ul'}->{$file}->{'_status'} &&
        $self->{'_ul'}->{$file}->{'_status'} == 1)
    {
        throw Underground8::Exception::FileInUse( $file );
    }

    open( $self->{'_ul'}->{$file}->{'_handle'}, ">$cert" ) or throw Underground8::Exception::FileOpen( $cert );
    $self->{'_ul'}->{$file}->{'_status'} = 1;
    return 1;
}

sub pkey_write_file ($$$)
{
    # Required Values:
    # - Filename of CA certificate
    # - Content
    my $self = instance(shift);
    my $content = shift;

    my $file = "postfix-privatekey";
    my $cert = "$g->{'cfg_cacert_dir'}/$file";
    
    if (ref($self->{'_ul'}->{$file}->{'_handle'}) ne 'GLOB')
    {
        throw Underground8::Exception("File Handle not found");;
    }
    
    # Return 2: Got an emtpy content, End of File reached, buffer closed
    if (length $content == 0)
    {
        close $self->{'_ul'}->{$file}->{'_handle'};
        delete $self->{'_ul'}->{$file};

#        my $sys_arg = quotemeta("smtpd_tls_key_file=$cert");
#        my $command = $g->{'cmd_postfix_postconf'}." -e $sys_arg";
#        my $output = safe_system($command);

        return 2;
    } else {
        print { $self->{'_ul'}->{$file}->{'_handle'} } $content;
        return 1;
    }
    return 0;
}

sub pkey_delete ($$)
{
    my $self = instance(shift);
    my $smtp_name = shift;

    my $cert = "$g->{'cfg_cacert_dir'}/postfix-privatekey";

    # remove this certificate
    unlink( $cert );

#    my $sys_arg = quotemeta("smtpd_tls_pkey_file=");
#    my $command = $g->{'cmd_postfix_postconf'}." -e $sys_arg";
#    my $output = safe_system($command);
    
    return 0;
}

sub match_cert_pkey()
{
    my $self = shift;

    my $certificate = "$g->{'cfg_cacert_dir'}/postfix-certificate";
    my $privatekey = "$g->{'cfg_cacert_dir'}/postfix-privatekey";
    my $command = "($g->{'cmd_openssl'} x509 -noout -modulus -in $certificate | $g->{'cmd_openssl'} md5; $g->{'cmd_openssl'} rsa -noout -modulus -in $privatekey | $g->{'cmd_openssl'} md5) | $g->{'cmd_uniq'} | $g->{'cmd_wc'} -l";
    my $output = safe_system($command);

    return $output == 1;
}

sub create_usermaps($$)
{
    my $self = instance(shift);
    my $usermaps = shift;
    #print Dumper $usermaps;
    my $postmap_raw = "";
    foreach my $domain (keys %{$usermaps})
    {
        my $domain_san = $domain;
        $domain_san =~ s/([.-])/\\$1/g;

        if ($usermaps->{$domain}{'accept_all'})
        {
            #$postmap_raw .= "\@$domain OK\n";
            $postmap_raw .= "/\@$domain_san\$/ OK\n";
        } else {
            foreach my $addr (keys %{$usermaps->{$domain}{'addresses'}})
            {
                if ( $usermaps->{$domain}{'addresses'}{$addr}{'accept'} ne "0" )
                {
                    #$postmap_raw .= "$addr\@$domain OK\n";
                    $addr =~ s/([+.?{}-])/\\$1/g;
                    $addr =~ s#/#\\/#g;
                    $postmap_raw .= "/^$addr\@$domain_san\$/ OK\n";
                    $postmap_raw .= "/^prvs=[0-9]{4}[0-9A-F]{6}=$addr\@$domain_san\$/ OK\n";

                } else {
                    # This does not work ... we don't do anything here
                    #$postmap_raw .= "$addr\@$domain 550 User not found.\n";
                }
            }
        }
    }

	my $tmp_filename = '/tmp/new_usermaps_' . time();
	open(TMPFILE, '>' . $tmp_filename)
        or throw Underground8::Exception::FileOpen("$tmp_filename");
	print TMPFILE $postmap_raw;
	close(TMPFILE);

	sleep(1);

	my $output = safe_system("/usr/bin/sudo /bin/mv $tmp_filename " . $g->{'usermaps_raw_file'});
	safe_system("/usr/bin/sudo /bin/chown root:limes " . $g->{'usermaps_raw_file'});
	safe_system("/usr/bin/sudo /bin/chmod 0664 " . $g->{'usermaps_raw_file'});

	# No postmap -- we use regexp:/
}

sub write_filter_dynip_file($$)
{
    my $self = instance(shift);
    my $config = shift;
    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });
    my $config_content;
    $template->process($g->{'template_postfix_filter_dynip'},$config,\$config_content)
        or throw Underground8::Exception($template->error);

    open (POSTFIX_DYNIP,'>',$g->{'file_postfix_filter_dynip'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_filter_dynip'});

    print POSTFIX_DYNIP $config_content;

    close (POSTFIX_DYNIP);
   } 


sub write_header_checks_file($){
	my $self = instance(shift);
	my $config_content;
    my $template = Template->new ({ INCLUDE_PATH => $g->{'cfg_template_dir'}, }); 

	my $dump = new XML::Dumper;
	my $config = $dump->xml2pl( $g->{'file_smtpcrypt_conf'} );
	my $smtpcrypt_cryptotag = $config->{'global'}->{'default_tag'};
	my $smtpcrypt_enable = $config->{'global'}->{'enabled'};

    my $vars = {
		smtpcrypt_enable => $smtpcrypt_enable,
		smtpcrypt_cryptotag => $smtpcrypt_cryptotag,
    };

	# Generate /etc/postfix/header_checks
	$template->process($g->{'template_postfix_header_checks'}, $vars, \$config_content)
		or throw Underground8::Exception($template->error);
	open(POSTFIX_HEADER_CHECKS, '>', $g->{'file_postfix_header_checks'})
		or throw Underground8::Exception::FileOpen($g->{'file_postfix_header_checks'});
	print POSTFIX_HEADER_CHECKS $config_content;
	close POSTFIX_HEADER_CHECKS;

	# Postmap header_checks
	safe_system($g->{'cmd_postfix_postmap'} . " " . $g->{'file_postfix_header_checks'});

    safe_system($g->{'cmd_postfix_check'});
}

1;

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


package Underground8::Configuration::LimesAS::System;
use base Underground8::Configuration;

use strict;
use warnings;

#use Clone::Any qw(clone);
use Clone qw(clone);

use Underground8::Utils;
use Underground8::Service::NetworkInterface;
use Underground8::Service::DNS;
use Underground8::Service::Proxy;
use Underground8::Service::Backup;
use Underground8::Service::Authentication;
use Underground8::Service::Timezone;
use Underground8::Service::Timesync;
use Underground8::Service::Iptables;
use Underground8::Service::MySQL;
use Underground8::Service::Monit;
use Underground8::Service::SyslogNG;
use Underground8::Service::UpdateService;
use Underground8::Service::SMTPCrypt;
use Underground8::Service::SNMP;
use XML::Smart;
use Data::Dumper;
use Error qw(:try);
use Underground8::Exception;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $appliance = shift;

    my $self = $class->SUPER::new("system",$appliance);
    
    $self->{'_net_interface'} = new Underground8::Service::NetworkInterface($g->{'net_if0'});
    $self->{'_net_dns'} = new Underground8::Service::DNS;
    $self->{'_net_proxy'} = new Underground8::Service::Proxy;
    $self->{'_backup'} = new Underground8::Service::Backup;
    $self->{'_net_admin_ranges'} = '';
    $self->{'_authentication'} = new Underground8::Service::Authentication;    
    $self->{'_timezone'} = new Underground8::Service::Timezone;
    $self->{'_timesync'} = new Underground8::Service::Timesync;
    $self->{'_iptables'} = new Underground8::Service::Iptables;
    $self->{'_notification_email'} = new Underground8::Notification::Email;
    $self->{'_temp_dir'} = '';
    $self->{'_mysql'} = new Underground8::Service::MySQL;
    $self->{'_monit'} = new Underground8::Service::Monit;
    $self->{'_syslog'} = new Underground8::Service::SyslogNG;
    $self->{'_updateservice'} = new Underground8::Service::UpdateService;
	$self->{'_smtpcrypt'} = new Underground8::Service::SMTPCrypt;
    $self->{'_snmp'} = new Underground8::Service::SNMP;
    return $self;
}

#### Accessors ####
# local only

sub backup ($)
{
    my $self = instance(shift,__PACKAGE__);
    return $self->{'_backup'};
}

sub net_name ($)
{
    my $self = instance(shift,__PACKAGE__);
    return $self->net_interface->name();
    
}

sub net_interface ($@)
{
    my $self = instance(shift,__PACKAGE__);
    $self->{'_net_interface'} = shift if @_;
    return $self->{'_net_interface'};
}

sub net_dns ($@)
{
    my $self = instance(shift,__PACKAGE__);
    $self->{'_net_dns'} = shift if @_;
    return $self->{'_net_dns'};
}

sub net_proxy ($@)
{
    my $self = instance(shift,__PACKAGE__);
    $self->{'_net_proxy'} = shift if @_;
    return $self->{'_net_proxy'};
}
sub net_admin_ranges ($@)
{
    my $self = instance(shift,__PACKAGE__);
    $self->{'_net_admin_ranges'} = shift if @_;
    return $self->{'_net_admin_ranges'};
}

sub authentication ($@) {
    my $self = instance(shift,__PACKAGE__);
    $self->{'_authentication'} = shift if @_;
    return $self->{'_authentication'};
}

sub timezone ($@) {
    my $self = instance(shift,__PACKAGE__);
    $self->{'_timezone'} = shift if @_;
    return $self->{'_timezone'};
}

sub timesync ($@) {
    my $self = instance(shift,__PACKAGE__);
    $self->{'_timesync'} = shift if @_;
    return $self->{'_timesync'};
}

sub iptables ($@) {
    my $self = instance(shift,__PACKAGE__);
    $self->{'_iptables'} = shift if @_;
    return $self->{'_iptables'};
}

sub mysql ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_mysql'} = shift if @_;
    return $self->{'_mysql'};
}

sub monit ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_monit'} = shift if @_;
    return $self->{'_monit'};
}

sub syslog ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_syslog'} = shift if @_;
    return $self->{'_syslog'};
}

sub updateservice ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_updateservice'} = shift if @_;
    return $self->{'_updateservice'};
}

sub smtpcrypt ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_smtpcrypt'} = shift if @_;
    return $self->{'_smtpcrypt'};
}

sub snmp ($@) {
    my $self = instance(shift, __PACKAGE__);
    $self->{'_snmp'} = shift if @_;
    return $self->{'_snmp'};
}


#### CRUD Methods ####

### Firewall ###

sub firewall_notify($$)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->iptables->notify(shift);
    }
    return $self->iptables->notify();
}

sub firewall_user_change($$)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->iptables->user_change(shift);
    }
    return $self->iptables->user_change();
}

sub firewall_newconf_to_oldconf($)
{
    my $self = instance(shift);
    $self->iptables->newconf_to_oldconf();
}

sub firewall_revoke_settings ($)
{
    my $self = instance(shift);
    $self->iptables->revoke_settings();
}

sub firewall_confirm_settings ($)
{
    my $self = instance(shift);
    $self->iptables->confirm_settings;
}

sub client_ip_in_admin_ranges( $$ )
{
    my $self = instance(shift);
    my $ip = $ENV{ 'REMOTE_ADDR' };
    
    if( ! $ip )
    {
	return 1;	# we do not know the IP so we go forward
    }

    my $href = $self->get_ip_range_whitelist();
    unless( defined $href && defined ($href->[0]) )
    {
	return 1;	# the list is empty
    }

print STDERR "client = $ip | ranges = ".scalar(@$href)."\n";
    
    return $self->iptables->check_included( $ip, $href );
}

### Network Interface ###

sub ip_address ($)
{
    my $self = instance(shift);
    return $self->net_interface->ip_address();
}

sub net_restart_webserver($)
{
    my $self = instance(shift);
    $self->net_interface->restart_webserver();
}

sub net_interface_service_restart ($)
{
    my $self = instance(shift);
    $self->net_interface->service_restart();
}

sub set_ip_address ($$)
{
    my $self = instance(shift);
    my $ip_address = shift;
    # TODO: check for valid ip address
    $self->net_interface->ip_address($ip_address);
}

sub subnet_mask ($)
{
    my $self = instance(shift);
    return $self->net_interface->subnet_mask();
}

sub set_subnet_mask ($$)
{
    my $self = instance(shift);
    my $subnet_mask = shift;
    # TODO: check for valid subnet_mask
    $self->net_interface->subnet_mask($subnet_mask);
}

sub default_gateway ($@)
{
    my $self = instance(shift);
    return $self->net_interface->default_gateway();
}

sub set_default_gateway ($@)
{
    my $self = instance(shift);
    my $default_gateway = shift;
    # TODO: check for valid default_gateway
    $self->net_interface->default_gateway($default_gateway);
}

sub net_notify($$)
{
    my $self = instance(shift);
    return $self->net_interface->notify(shift);
}

sub net_newconf_to_oldconf($)
{
    my $self = instance(shift);
    $self->net_interface->newconf_to_oldconf();
}

sub net_revoke_settings ($)
{
    my $self = instance(shift);
    $self->net_interface->revoke_settings();
}
sub net_revoke_crontab ($)
{
    my $self = instance(shift);
    $self->net_interface->revoke_crontab();
}

sub set_net_user_change ($$)
{
    my $self = instance(shift);
    $self->net_interface->user_change(shift);
}

sub set_firewall_user_change ($$)
{
    my $self = instance(shift);
    $self->iptables->user_change(shift);
}
### DNS Settings ###

sub hostname ($)
{
    my $self = instance(shift);
    return $self->net_dns->hostname(); 
}

sub set_hostname ($$)
{
    my $self = instance(shift);
    my $hostname = shift;
    # TODO: check for valid hostname
    $self->net_dns->hostname($hostname);

    my $fq_hostname;
    if ($self->domainname) {
        $fq_hostname = "$hostname." . $self->domainname;
    } else {
        $fq_hostname = $hostname;
    }

    $self->appliance->antispam->set_myhostname($fq_hostname);
    $self->appliance->antispam->set_mydestination($fq_hostname);

	# We need to restart Amavis & Q-NG in order to get this done successfully
	$self->appliance->antispam->amavis->change;
	$self->appliance->quarantine->quarantineNG->change;

	$self->appliance->antispam->commit;
	$self->appliance->quarantine->commit;
}

sub domainname ($)
{
    my $self = instance(shift);
    return $self->net_dns->domainname;         
}

sub set_domainname ($$)
{
    my $self = instance(shift);
    my $domainname = shift;
    # TODO: check for valid domainname
    $self->net_dns->domainname($domainname);
    $self->net_interface->domainname($domainname);

    my $fq_hostname = $self->hostname . "." . $domainname;
    $self->appliance->antispam->set_myhostname($fq_hostname);
    $self->appliance->antispam->set_mydestination($fq_hostname);

	# We need to restart Amavis & Q-NG in order to get this done successfully
	$self->appliance->antispam->amavis->change;
	$self->appliance->quarantine->quarantineNG->change;

	$self->appliance->antispam->commit;
	$self->appliance->quarantine->commit;
}

sub primary_dns ($)
{
    my $self = instance(shift);
    return $self->net_interface->primary_dns;
}

sub set_primary_dns ($$)
{
    my $self = instance(shift);
    my $new_server = shift;
    
    $self->net_interface->primary_dns($new_server);
}

sub secondary_dns ($)
{
    my $self = instance(shift);
    return $self->net_interface->secondary_dns;
}

sub set_secondary_dns ($$)
{
    my $self = instance(shift);
    my $new_server = shift;
    
    $self->net_interface->secondary_dns($new_server);
}

sub delete_dns_server
{
}

### SMTPCrypt settings ###
sub smtpcrypt_get_cryptotag($) {
	my $self = instance(shift);
	return $self->smtpcrypt->get_cryptotag;
}

sub smtpcrypt_set_cryptotag($$) {
	my $self = instance(shift);
	$self->smtpcrypt->set_cryptotag(shift);
}

sub smtpcrypt_loadconfig($) {
	my $self = instance(shift);
	return $self->smtpcrypt->load_config;
}

sub smtpcrypt_get_packtype($){
	my $self = instance(shift);
	return $self->smtpcrypt->get_packtype;
}

sub smtpcrypt_set_packtype($$){
	my $self = instance(shift);
	$self->smtpcrypt->set_packtype(shift);
}

sub smtpcrypt_get_pwhandling($){
	my $self = instance(shift);
	return $self->smtpcrypt->get_pwhandling;
}

sub smtpcrypt_set_pwhandling($$){
	my $self = instance(shift);
	$self->smtpcrypt->set_pwhandling(shift);
}

sub smtpcrypt_get_presetpw($){
	my $self = instance(shift);
	return $self->smtpcrypt->get_presetpw;
}

sub smtpcrypt_set_presetpw($$){
	my $self = instance(shift);
	$self->smtpcrypt->set_presetpw(shift);
}


### Proxy Settings ###

sub proxy_server($)
{
    my $self = instance(shift);
    return $self->net_proxy->proxy_server;
}

sub set_proxy_server($$)
{
    my $self = instance(shift);
    my $new_server = shift;

    $self->net_proxy->proxy_server($new_server);
}

sub proxy_port($)
{
    my $self = instance(shift);
    return $self->net_proxy->proxy_port;
}

sub set_proxy_port($$)
{
    my $self = instance(shift);
    my $new_port = shift;

    $self->net_proxy->proxy_port($new_port);
}

sub proxy_username($)
{
    my $self = instance(shift);
    return $self->net_proxy->proxy_username;
}

sub set_proxy_username($$)
{
    my $self = instance(shift);
    my $new_username = shift;

    $self->net_proxy->proxy_username($new_username);
}

sub proxy_password($)
{
    my $self = instance(shift);
    return $self->net_proxy->proxy_password;
}

sub set_proxy_password($$)
{
    my $self = instance(shift);
    my $new_password = shift;

    $self->net_proxy->proxy_password($new_password);
}

sub proxy_enabled($)
{
    my $self = instance(shift);
    return $self->net_proxy->proxy_enabled;
}

sub set_proxy_enabled($$)
{
    my $self = instance(shift);
    my $enabled = shift;

    $self->net_proxy->proxy_enabled($enabled);
}

sub commit($)
{
    my $self = instance(shift);

    try {
        if ($self->prepare())
        {
            $self->net_interface->commit() if $self->net_interface->is_changed;
            $self->net_dns->commit() if $self->net_dns->is_changed;
            $self->net_proxy->commit() if $self->net_proxy->is_changed;
            $self->timezone->commit() if $self->timezone->is_changed;
            $self->timesync->commit() if $self->timesync->is_changed;
            $self->iptables->commit($self->net_name) if $self->iptables->is_changed;
            $self->mysql->commit() if $self->mysql->is_changed;
            $self->monit->commit() if $self->monit->is_changed;
            $self->updateservice->commit() if $self->updateservice->is_changed;
            $self->syslog->commit() if $self->syslog->is_changed;
            $self->authentication->commit() if $self->authentication->is_changed;
            $self->snmp->commit() if $self->snmp->is_changed;
            $self->save_config();
        }
    }
    catch Underground8::Exception with
    {
        my $E = shift;
        $self->xml_restore();
        $self->load_config();

        # rethrow
        use Data::Dumper;
        print Dumper $E;
        throw Underground8::Exception("rethrown", $E);
    }
    finally {
        $self->del_temp_dir();
    };
}


### Administration Ranges ###


### User Management ###

sub set_user_password($$$$$)
{
    my $self = instance(shift);
    my $user = shift;
    my $loggedinuser = shift;
    my $oldhash = shift;
    my $hash1 = shift;
    my $hash2 = shift;
    $self->authentication->user_password($user, $loggedinuser, $oldhash, $hash1, $hash2);
}
    
sub set_commonusers_password($$){
	my $self = instance(shift);
	my $pw = shift;

	$self->authentication->commonusers_password($pw);
}


### Timezone Management ###

sub initialize_timezones($$)
{
    my $self = instance(shift);
    $self->timezone->initialize_timezones();
}

sub tz($)
{
    my $self = instance(shift);
    return $self->timezone->timezone;
}

sub all_timezones($)
{
    my $self = instance(shift);
    return $self->timezone->timezones;
}
sub set_tz($$)
{
    my $self = instance(shift);
    my $newzone = shift;
    $self->mysql->change();
    return $self->timezone->timezone($newzone);
}


### Timesync Management ###

sub time_servers($)
{
    my $self = instance(shift);
    return $self->timesync->time_servers;
}

sub add_ntp_server($$)
{
    my $self = instance(shift);
    my $newserver = shift;
    $self->timesync->add_server($newserver);
}

sub del_ntp_server($$)
{
    my $self = instance(shift);
    my $delid = shift;
    $self->timesync->del_server($delid);
}

sub change_ntp_server($$$)
{
    my $self = instance(shift);
    my $changeid = shift;
    my $newserver = shift;
    $self->timesync->change_server($changeid, $newserver);
}

#### Misc Methods ####

sub reboot
{
    my $self = instance(shift);
    system("$g->{'cmd_reboot'} > /dev/null 2>&1 &");
}

sub shutdown 
{
    my $self = instance(shift);
    system("$g->{'cmd_shutdown'} > /dev/null 2>&1 &");
}

sub reset_statistics
{
    my $self = instance(shift);
    system("$g->{'cmd_resetter_statistics'}");
}

sub reset_soft
{
    my $self = instance(shift);
    system("$g->{'cmd_resetter_soft'}");
}

sub reset_hard
{
    my $self = instance(shift);
    system("$g->{'cmd_resetter_hard'}");
}

sub backup_create_backup_name($$)
{
    my $self = instance(shift);
    return $self->backup->create_backup_name(shift);
}


sub backup_initialize_download($$)
{
    my $self = instance(shift);
    return $self->backup->initialize_download(shift);
}

sub backup_initialize_upload ($$)
{
    my $self = instance(shift);
    return $self->backup->initialize_upload(shift);
}

sub backup_write_file ($$$)
{
    my $self = instance(shift);
    return $self->backup->write_file(shift, shift);    
}

sub backup_read_file($$$)
{
    my $self = instance(shift);
    return $self->backup->read_file(shift,shift);
}

sub backup_check_file ($$)
{
    my $self = instance(shift);
    return $self->backup->check_file(shift);
}

sub backup_get_encrypted_by_index ($$)
{
    my $self = instance(shift);
    return $self->backup->get_encrypted_by_index(shift);
}

sub backup_get_list_index ($$)
{
    my $self = instance(shift);
    return $self->backup->get_list_index(shift);
}

sub backup_read_list_encrypted ($)
{
    my $self = instance(shift);
    $self->backup->read_list_encrypted();
}

sub backup_read_list_unencrypted ($)
{
    my $self = instance(shift);
    $self->backup->read_list_unencrypted();
}

sub backup_list_encrypted ($)
{
    my $self = instance(shift);
    return $self->backup->list_encrypted();
}

sub backup_list_unencrypted ($)
{
    my $self = instance(shift);
    return $self->backup->list_unencrypted();
}

sub backup_remove_encrypted_backup ($$)
{
    my $self = instance(shift);
    $self->backup->remove_encrypted_backup(shift);
}

sub backup_remove_unencrypted_backup ($$)
{
    my $self = instance(shift);
    $self->backup->remove_unencrypted_backup(shift);
}

sub backup_remove_tempdir
{
    my $self = instance(shift);
    $self->backup->remove_tempdir();
}

sub backup_create_tempdir
{
    my $self = instance(shift);
    $self->backup->create_tempdir();
}

sub copy_to_backup ($)
{
    my $self = instance(shift);
    $self->backup->copy_to_backup();
}

sub copy_from_backup ($)
{
    my $self = instance(shift);
    $self->backup->copy_from_backup();
}

sub create_backup($)
{
    my $self = instance(shift);
    $self->backup->create_backup();
}

sub restore_backup($)
{
    my $self = instance(shift);
    $self->backup->restore_backup();
}

sub encrypt_backup($)
{
    my $self = instance(shift);
    $self->backup->encrypt_backup();
}

sub decrypt_backup($)
{
    my $self = instance(shift);
    $self->backup->decrypt_backup();
}

sub backup_file($)
{
    my $self = instance(shift);
    return $self->{'_backup'}->backup_file();
}

sub backup_set_backup_file($$)
{
    my $self = instance(shift);
    $self->{'_backup'}->set_backup_file(shift);
}


### Iptables ###
sub add_ip_range_whitelist($$$$)
{
    my $self = instance(shift);
    $self->iptables->add_ip_range_whitelist(shift,shift,shift);
}   

sub get_ip_range_whitelist($)
{
    my $self = instance(shift);
    return $self->iptables->get_ip_range_whitelist();
}

sub del_ip_range_whitelist($$)
{
    my $self = instance(shift);
    $self->iptables->del_ip_range_whitelist(shift);
}

sub set_additional_ssh_port($$)
{
	my $self = instance(shift);
	$self->iptables->additional_ssh_port( shift );
}

sub get_additional_ssh_port($)
{
	my $self = instance(shift);
	return ($self->iptables->get_additional_ssh_port());
}

#### Load / Save Configuration ####

sub load_config ($)
{
    my $self = instance(shift);

    $self->load_config_xml_smart();
}

sub load_config_xml_smart ($)
{
    my $self = instance(shift);
    my $infile = $self->config_filename();

    my $XML = new XML::Smart($infile,'XML::Smart::Parser');
    $XML = $XML->cut_root;

    ## Import of Timezones
    my $timezone = $XML->{'_timezone'}->tree_pointer_ok;

    for my $region (keys %{$XML->{'_timezone'}->{'_timezones'}} )
    {
        $timezone->{'_timezones'}->{$region} = [];
            foreach my $entry (@{$XML->{'_timezone'}->{'_timezones'}->{$region}})
            {
                push @{$timezone->{'_timezones'}->{$region}}, sprintf('%s',$entry);
            }
    }

    ## Import of Timesync

    my $timesync = $XML->{'_timesync'}->tree_pointer_ok;
    $timesync->{'_server'} = [];
    foreach my $server (@{$XML->{'_timesync'}->{'_server'}} )
    {
        push @{$timesync->{'_server'}}, sprintf('%s',$server);
    }
    

    ## Import of updateservice
    
    my $unblessed_updateservice = $XML->{'_updateservice'}->tree_pointer_ok;


    my $unblessed_net_interface = $XML->{'_net_interface'}->tree_pointer_ok;
    my $unblessed_net_dns = $XML->{'_net_dns'}->tree_pointer_ok;
    my $unblessed_net_proxy = $XML->{'_net_proxy'}->tree_pointer_ok;
    my $unblessed_authentication = $XML->{'_authentication'}->tree_pointer_ok;
    my $unblessed_iptables = $XML->{'_iptables'}->tree_pointer_ok;
    my $unblessed_syslog = $XML->{'_syslog'}->tree_pointer_ok;
    my $unblessed_snmp = $XML->{'_snmp'}->tree_pointer_ok;


    if(ref($unblessed_iptables->{'_ip_range_whitelist'}) eq '')
    {
         $unblessed_iptables->{'_ip_range_whitelist'} = [];
    }
    elsif (ref($unblessed_iptables->{'_ip_range_whitelist'}) eq 'HASH')
    {
        $unblessed_iptables->{'_ip_range_whitelist'} = [{start => $unblessed_iptables->{'_ip_range_whitelist'}->{'start'},
                                                          end => $unblessed_iptables->{'_ip_range_whitelist'}->{'end'},
                                                          description => $unblessed_iptables->{'_ip_range_whitelist'}->{'description'},
							  state => 0
                                                        }];
    }
    if(ref($unblessed_iptables->{'_old_ip_range_whitelist'}) eq '')
    {
         $unblessed_iptables->{'_old_ip_range_whitelist'} = [];
    }
    elsif (ref($unblessed_iptables->{'_old_ip_range_whitelist'}) eq 'HASH')
    {
        $unblessed_iptables->{'_old_ip_range_whitelist'} = [{start => $unblessed_iptables->{'_old_ip_range_whitelist'}->{'start'},
                                                          end => $unblessed_iptables->{'_old_ip_range_whitelist'}->{'end'},
                                                          description => $unblessed_iptables->{'_old_ip_range_whitelist'}->{'description'},
							  state => 2
                                                        }];
    }

    $self->net_interface->import_params($unblessed_net_interface);
    $self->appliance->set_alert_notify_nic_change() if ($self->net_interface->notify);
    $self->net_dns->import_params($unblessed_net_dns);
    $self->net_proxy->import_params($unblessed_net_proxy);
    $self->authentication->import_params($unblessed_authentication);
    $self->timezone->import_params($timezone);
    $self->timesync->import_params($timesync);
    $self->updateservice->import_params($unblessed_updateservice);
    $self->iptables->import_params($unblessed_iptables);
    $self->syslog->import_params($unblessed_syslog);
    $self->snmp->import_params($unblessed_snmp);

    # TODO: mysql does still not get or set any params from xml
    # maybe that changes in the future and here would be the point to write
    # Same for monit :-)
    $self->mysql->change();
    $self->monit->change();
}

sub save_config ($)
{
    my $self = instance(shift);
    $self->save_config_xml_smart();
}

sub save_config_xml_smart ($)
{
    my $self = instance(shift);

    my $outfile = $self->config_filename();

    my $XML = new XML::Smart('','XML::Smart::Parser');

    # unbless the network interface
    $XML->{'root'}->{'_net_interface'} = $self->net_interface->export_params;
    
    # unbless the dns settings
    $XML->{'root'}->{'_net_dns'} = $self->net_dns->export_params;

    #unbless the proxy settings
    $XML->{'root'}->{'_net_proxy'} = $self->net_proxy->export_params;

    # unbless the auth settings
    $XML->{'root'}->{'_authentication'} = $self->authentication->export_params;

    my $timezone = clone($self->timezone->export_params());
    $XML->{'root'}->{'_timezone'} = $timezone;

    my $timesync = clone($self->timesync->export_params());
    $XML->{'root'}->{'_timesync'} = $timesync;

    my $iptables = clone($self->iptables->export_params());
    $XML->{'root'}->{'_iptables'} = $iptables;
    
    my $updateservice = clone($self->updateservice->export_params());
    $XML->{'root'}->{'_updateservice'} = $updateservice;
    
    my $syslog = clone($self->syslog->export_params());
    $XML->{'root'}->{'_syslog'} = $syslog;

    my $snmp = clone($self->snmp->export_params());
    $XML->{'root'}->{'_snmp'} = $snmp;

    $XML->save($outfile);
}

sub xml_config_file
{
    return $g->{'cfg_system'};
}

sub check_revoke_apply
{
    my $self = instance(shift);
    return $self->iptables->check_revoke_apply;
}



### Underground_8 Smart Update Service ###

sub updateservice_parameters
{
    my $self = instance(shift);
    my $parameters = $self->updateservice->parameters();
    return $parameters;
}

sub set_updateservice_parameters
{
    my $self = instance(shift);
    my $parameters = shift;
    $self->updateservice->parameters($parameters);
}

sub toggle_updateservice_parameters ($$)
{
    my $self = instance(shift);
    my $service = shift;
    my $parameters;
    $parameters = $self->updateservice_parameters();

    if ( $service eq "update" )
    {
        if ( $parameters->{'update'} )
        {
            $parameters->{'update'} = "0";
            $parameters->{'download'} = "0";    
            $parameters->{'upgrade'} = "0";    
            $parameters->{'auto_newest'} = "0";    
        } else {
            $parameters->{'update'} = "1";
        }
    } elsif ( $service eq "download" ) {
        if ( $parameters->{'download'} )
        {
            $parameters->{'download'} = "0";
            $parameters->{'upgrade'} = "0"; 
            $parameters->{'auto_newest'} = "0";
        } else {
            $parameters->{'update'} = "1";
            $parameters->{'download'} = "1";
        }
    } elsif ( $service eq "upgrade" ) {
        if ( $parameters->{'upgrade'} )
        {
            $parameters->{'upgrade'} = "0"; 
            $parameters->{'auto_newest'} = "0";
        } else {
            $parameters->{'update'} = "1";
            $parameters->{'download'} = "1";
            $parameters->{'upgrade'} = "1";
        }
    } elsif ( $service eq "auto_newest" ) {

        if ( $parameters->{'auto_newest'} )
        {
            $parameters->{'auto_newest'} = "0";
        } else {
            $parameters->{'update'} = "1";
            $parameters->{'download'} = "1";
            $parameters->{'upgrade'} = "1";
            $parameters->{'auto_newest'} = "1";
        }
    }
    
    $self->set_updateservice_parameters($parameters);
    
}
sub initiate_usus ($)
{
    my $self = instance(shift);
    my $action = shift;
    my $version = shift;
    $self->updateservice->initiate_usus($action, $version);
}


sub snmp_enable() {
	my $self = instance(shift);
	$self->iptables->snmp_status(1);
	$self->snmp->enabled(1);
}

sub snmp_disable(){
	my $self = instance(shift);
	$self->iptables->snmp_status(0);
	$self->snmp->enabled(0);
}

sub snmp_status(){
	my $self = instance(shift);
	return $self->snmp->enabled();
}

sub snmp_configure(){
	my $self = instance(shift);

	if(@_) {
		my ($community, $network, $location, $contact) = @_;

		$self->snmp->community($community);
		$self->snmp->network($network);
		$self->snmp->location($location);
		$self->snmp->contact($contact);
	}

	return ($self->snmp->community(), $self->snmp->network(), $self->snmp->location(), $self->snmp->contact());
}



1;

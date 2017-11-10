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


package Underground8::Configuration::LimesAS::Antispam;
use base Underground8::Configuration;

use strict;
use warnings;

#use Clone::Any qw(clone);
use Clone qw(clone);

use Underground8::Utils;
use Underground8::Service::Postfix;
use Underground8::Service::Amavis;
use Underground8::Service::SQLGrey;
use Underground8::Service::Postfwd;
use Underground8::Service::Spamassassin;
use Underground8::Service::ClamAV;
#use Underground8::Service::KasperskyAV;
use Underground8::Service::Virustotal;
use Underground8::ReportFactory::LimesAS::LDAP;
use Underground8::Log;
use XML::Smart;
use File::Temp qw/ tempdir /;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::EntryExistsIn;
use XML::Dumper;
use Hash::Merge qw( merge );
#use String::Urandom;

# Constructor
sub new ($$) {
	my $class = shift;
	my $appliance = shift;

	my $self = $class->SUPER::new('antispam',$appliance);

	$self->{'_postfix'} =	    new Underground8::Service::Postfix();
	$self->{'_amavis'} =	    new Underground8::Service::Amavis();
	$self->{'_sqlgrey'} =	    new Underground8::Service::SQLGrey();
	$self->{'_postfwd'} =	    new Underground8::Service::Postfwd();
	$self->{'_spamassassin'} =  new Underground8::Service::Spamassassin();
	$self->{'_clamav'} =	    new Underground8::Service::ClamAV();
	#$self->{'_kasperskyav'} =   new Underground8::Service::KasperskyAV();
	$self->{'_virustotal'} =    new Underground8::Service::Virustotal();	
	$self->{'_ldap_report'} =   new Underground8::ReportFactory::LimesAS::LDAP();
	$self->{'_has_changes'} = 0;
	$self->{'_temp_dir'} = '';

	return $self;
}

#### Accessors ####
# read only and only available from this package
sub postfix {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_postfix'};
}

sub amavis {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_amavis'};
}

sub sqlgrey {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_sqlgrey'};
}

sub spamassassin {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_spamassassin'};
}

sub clamav {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_clamav'};
}

#sub kasperskyav {
#	my $self = instance(shift,__PACKAGE__);
#	return $self->{'_kasperskyav'};
#}

sub virustotal {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_virustotal'};
}

sub postfwd {
	my $self = instance(shift,__PACKAGE__);
	return $self->{'_postfwd'};
}

#### CRUD Methods for Postfix parameter 'relay_domains' ####
# - validate input parameters
# - hand parameters over to proper functions
sub domain_create ($$$$) {
	my $self = instance(shift);
	my $domain_name = shift;
	my $dest_mailserver = shift;
	my $enabled = shift;

	#TODO: checks and validations
	$self->{'_has_changes'} = 1;
	$self->postfix->domain_create($domain_name, $dest_mailserver, $enabled);
}

sub domain_update ($$$$) {
	my $self = instance(shift);
	my $domain_name = shift;
	my $dest_mailserver = shift;

	$self->{'_has_changes'} = 1;
	$self->postfix->domain_update( $domain_name, $dest_mailserver );
}

sub domain_read ($) {
	my $self = instance(shift);
	return $self->postfix->domain_read();	
}

sub domain_delete ($$) {
	my $self = instance(shift);
	my $domain_name = shift;

	#TODO: checks and validations
	$self->{'_has_changes'} = 1;

	$self->postfix->domain_delete($domain_name);	
}

sub domains_linked($$) {
	my $self = instance(shift);
	my $smtpsrv_name = shift;
	return $self->postfix->domains_linked($smtpsrv_name);
}

sub domains_bulk_assign($$$) {
	my $self = instance(shift);
	my $src_mailserver = shift;
	my $dest_mailserver = shift;
	return $self->postfix->domains_bulk_assign($src_mailserver, $dest_mailserver);
}

sub smtpsrv_read ($) {
	my $self = instance(shift);
	return $self->postfix->smtpsrv_read();
}

sub smtpsrv_delete ($$) {
	my $self = instance(shift);
	my $smtpsrv_name = shift;

	$self->{'_has_changes'} = 1;

	$self->postfix->smtpsrv_delete($smtpsrv_name);
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


	$self->{'_has_changes'} = 1;
	$self->postfix->smtpsrv_create($descr, $addr, $port, $auth_enabled, $auth_methods, $ssl_check, $use_fqdn, $ldap_enabled, $ldap_server, $ldap_user, $ldap_pass, $ldap_base, $ldap_filter, $ldap_property, $ldap_autolearn_domains);
}

sub smtpsrv_update ($$$$) {
	my $self = instance(shift);
	my $smtpsrv_name = shift;
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

	$self->{'_has_changes'} = 1;
	$self->postfix->smtpsrv_update($smtpsrv_name, $descr, $addr, $port, $auth_enabled, $auth_methods, $ssl_check, $use_fqdn, $ldap_enabled, $ldap_server, $ldap_user, $ldap_pass, $ldap_base, $ldap_filter, $ldap_property, $ldap_autolearn_domains);
}

sub domain_enable ($$) {
	my $self = instance(shift);
	my $domain_name = shift;

	#TODO: checks and validations
	$self->{'_has_changes'} = 1;
	$self->postfix->domain_enable($domain_name);	
}

sub domain_disable ($$) {
	my $self = instance(shift);
	my $domain_name = shift;

	#TODO: checks and validations
	$self->{'_has_changes'} = 1;
	$self->postfix->domain_disable($domain_name);	
}


sub domain_exists ($$) {
	my $self = instance(shift);
	my $domain_name = shift;
	
	return $self->postfix->domain_exists($domain_name);   
}


# Postfix Usermaps
sub usermaps {
	my $self = instance(shift);
	my $domain = shift;
	my $ldap = shift;

	if ($domain) {
		if ($ldap) {
			return $self->postfix->get_usermaps_domain($domain, $ldap);
		} else {
			return $self->postfix->get_usermaps_domain($domain);
		}
	} else {
		return $self->postfix->usermaps();
	}
}

# update and add are the same
sub usermaps_update_addr {
	my $self = instance(shift);
	my $domain = shift;
	my $address = shift;
	my $accept = shift;

	$self->postfix->usermaps_update_addr($domain, $address, $accept);
}

sub usermaps_delete_addr {
	my $self = instance(shift);
	my $domain = shift;
	my $address = shift;
	
	$self->postfix->usermaps_delete_addr($domain, $address);
}

sub usermaps_delete_domain {
	my $self = instance(shift);
	my $domain = shift;

	$self->postfix->usermaps_delete_domain($domain);
}


#### Methods for Postfix parameter 'smtpd_banner' ####
use Data::Dumper;

sub add_ip_range_whitelist($$$$) {
	my $self = instance(shift);
	my $range_start = shift;
	my $range_end = shift;
	my $description = shift;

	my $range = {
		start => $range_start,
		end => $range_end
	};

	if( ip_dec( $range->{'start'} ) > ip_dec( $range->{'end'} ) ) {
		throw Underground8::Exception::FalseRange();
	}

	my $res = $self->check_overlapping( $self->get_ip_range_whitelist, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExists();
	}

	$res = $self->check_overlapping( $self->read_blacklist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_ipblacklist', $res );
	}

	$res = $self->check_overlapping( $self->read_whitelist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_ipwhitelist', $res );
	}

	$self->postfix->add_ip_range_whitelist( $range_start, $range_end, $description );
}   

# TT: admin/antispam/ip_range_whitelist/ip_range_whitelist_listentries.inc.tt2
sub get_ip_range_whitelist($) {
	my $self = instance(shift);
	return $self->postfix->ip_range_whitelist();
}

sub del_ip_range_whitelist($$) {
	my $self = instance(shift);
	$self->postfix->del_ip_range_whitelist(shift);
}

# TT: admin/antispam/smtp/advanced.inc.tt2
sub smtpd_banner ($) {
	my $self = instance(shift);
	return $self->postfix->smtpd_banner();
}

sub set_smtpd_banner ($$) {
	my $self = instance(shift);
	my $banner = shift;

	$self->{'_has_changes'} = 1;
	$self->postfix->set_smtpd_banner($banner);
}	

# lib: Configuration/LimesAS/System.pm
sub set_myhostname ($$) {
	my $self = instance(shift);
	my $myhostname = shift;
	
	$self->{'_has_changes'} = 1;
	$self->postfix->set_myhostname($myhostname);

	# initiate change
	$self->amavis->spam_subject_tag($self->amavis->spam_subject_tag);
}

# lib: Configuration/LimesAS/System.pm
sub set_mydestination ($$) {
	my $self = instance(shift);
	my $hostname = shift;

	$self->{'_has_changes'} = 1;
	$self->postfix->set_mydestination($hostname);
}


### Methods for Postfix SMTP Settings ###
# TT: admin/antispam/smtp/restrictions.inc.tt2
sub helo_required($) {
	my $self = instance(shift);
	return $self->postfix->helo_required;
}

sub enable_helo_required($) {
	my $self = instance(shift);
	$self->postfix->enable_helo_required();
}

sub disable_helo_required($) {
	my $self = instance(shift);
	$self->postfix->disable_helo_required();
}

# TT: admin/antispam/smtp/restrictions.inc.tt2
sub rfc_strict ($) {
	my $self = instance(shift);
	return $self->postfix->rfc_strict;
}

sub enable_rfc_strict ($) {
	my $self = instance(shift);
	$self->postfix->enable_rfc_strict();
}

sub disable_rfc_strict ($) {
	my $self = instance(shift);
	$self->postfix->disable_rfc_strict();
}

sub backscatter_protection ($) {
	my $self = instance(shift);
	$self->postfix->backscatter_protection();
}

sub enable_backscatter_protection ($) {   
	my $self = instance(shift);
	$self->postfix->backscatter_protection(1);
}

sub disable_backscatter_protection ($) {
	my $self = instance(shift);
	$self->postfix->backscatter_protection(0);
}

# TT: admin/antispam/smtp/restrictions.inc.tt2
sub sender_domain_verify ($) {
	my $self = instance(shift);
	return $self->postfix->sender_domain_verify;
}

sub enable_sender_domain_verify ($) {
	my $self = instance(shift);
	$self->postfix->enable_sender_domain_verify();
}

sub disable_sender_domain_verify ($) {
	my $self = instance(shift);
	$self->postfix->disable_sender_domain_verify();
}

# TT: admin/antispam/smtp/restrictions.inc.tt2
sub sender_fqdn_required ($) {
	my $self = instance(shift);
	return $self->postfix->sender_fqdn_required;
}

sub enable_sender_fqdn_required ($) {
	my $self = instance(shift);
	$self->postfix->enable_sender_fqdn_required();
}

sub disable_sender_fqdn_required ($) {
	my $self = instance(shift);
	$self->postfix->disable_sender_fqdn_required();
}


#### AMAVISd Settings ####
# TT: admin/antispam/general/antivirus.inc.tt2
sub warn_recipient_virus ($) {
	my $self = instance(shift);
	return $self->amavis->warn_recipient_virus;
}

sub enable_warn_recipient_virus ($) {
	my $self = instance(shift);
	$self->amavis->warn_recipient_virus(1);
}

sub disable_warn_recipient_virus ($) {
	my $self = instance(shift);
	$self->amavis->warn_recipient_virus(0);
}

sub warn_recipient_banned_file ($) {
	my $self = instance(shift);
	return $self->amavis->warn_recipient_banned_file;
}

sub enable_warn_recipient_banned_file ($) {
	my $self = instance(shift);
	$self->amavis->warn_recipient_banned_file(1);
}

sub disable_warn_recipient_banned_file ($) {
	my $self = instance(shift);
	$self->amavis->warn_recipient_banned_file(0);
}

# TT: admin/antispam/general/spam.inc.tt2
sub notification_admin ($) {
	my $self = instance(shift);
	return $self->amavis->notification_admin;
}

sub set_notification_admin ($$) {
	my $self = instance(shift);
	my $notification_admin = shift;
	return $self->amavis->notification_admin($notification_admin);
}

# TT: admin/antispam/general/spam.inc.tt2
sub quarantine_admin ($) {
	my $self = instance(shift);
	return $self->amavis->quarantine_admin;
}

sub set_quarantine_admin ($$) {
	my $self = instance(shift);
	my $quarantine_admin = shift;
	return $self->amavis->quarantine_admin($quarantine_admin);
}

# TT: admin/antispam/general/spam.inc.tt2
sub spam_subject_tag ($) {
	my $self = instance(shift);
	return $self->amavis->spam_subject_tag;
}

sub set_spam_subject_tag ($) {
	my $self = instance(shift);
	my $spam_subject_tag = shift;
	return $self->amavis->spam_subject_tag($spam_subject_tag);
}

# TT: admin/policy/attachments/attachments.listentries.inc.tt2
sub banned_attachments($) {
	my $self = instance(shift);
	return $self->amavis->banned_attachments;
}

sub add_banned_attachments {
	my $self = instance(shift);
	return $self->amavis->banned_attachments(shift,shift,shift);
}

sub del_banned_attachment($$) {
	my $self = instance(shift);
	my $banned_attachment = shift;
	$self->amavis->del_banned_attachment($banned_attachment);
}

sub quarantine_enabled($$) {
	my $self = instance(shift);
	return $self->amavis->quarantine_enabled(shift);
}

sub banned_attachments_groups($) { 
	my $self = instance(shift); 
	return $self->amavis->banned_attachments_groups; 
} 

sub attachments_groups($){ 
	my $self = instance(shift); 
	return $self->amavis->attachments_groups; 
} 

sub banned_attachments_contenttypes($) { 
	my $self = instance(shift); 
	return $self->amavis->banned_attachments_contenttypes;
}

sub score_map($$) {
	my $self = instance(shift);
	return $self->amavis->score_map(shift);
}

sub set_score($$$$) {
	my $self = instance(shift);
	$self->amavis->set_score(shift,shift,shift);
}

sub mails_destiny {
	my $self = instance(shift);
	return $self->amavis->mails_destiny(shift);
}

sub get_mails_destiny {
	my $self = instance(shift);
	return $self->amavis->get_mails_destiny();
}

sub admin_boxes {
	my $self = instance(shift);
	return $self->amavis->admin_boxes(shift);
}

sub get_admin_boxes {
	my $self = instance(shift);
	return $self->amavis->get_admin_boxes();
}


sub set_max_incoming_connections($$) {
	my $self = instance(shift);
	$self->postfix->max_incoming_connections(shift);
}

# TT: admin/antispam/smtp/advanced.inc.tt2
sub get_max_incoming_connections($) {
	my $self = instance(shift);
	return $self->postfix->max_incoming_connections();
}


# Convert all entries from obsolete sqlgrey-rbl to postfwd xml
sub convert_rbl_sqlgrey2postfwd($){
	my $self = instance(shift);

	# If file isn't existent, return
	return -2 if( ! -e $g->{'rbls_list'} );

	# Get old RBLs or return
	my $rbls_old = new XML::Dumper()->xml2pl($g->{'rbls_list'}) or return -1;

	# Hash keys -> Array
	my @rbls_old_list = keys %$rbls_old;
	return 0 if ((scalar @rbls_old_list) == 0);

	$self->postfwd->load_config();
	$self->postfwd->enable_rbl() if $self->postfix->rbl_checks;

	# Convert to new rbl
	foreach my $rbl_old (@rbls_old_list) {
		my $type = $rbls_old->{$rbl_old}->{'type'} || "system";
		my $enabled = $rbls_old->{$rbl_old}->{'enabled'} || 0;
		$self->postfwd->add_rbl( $rbl_old, $type, $enabled );	
		# delete($rbls_old->{$rbl_old}) ;
	}

	# Commit new list
	$self->postfwd->commit;
	return 1;
}

# Convert old sqlgrey-based black-/whitelists to postfwd and disable sqlgrey afterwards
# The code blocks are only and exactly called once (at first page-load)
sub convert_bwlists_sqlgrey2postfwd($){
	my $self = instance(shift);
	my $change = 0;

	# Convert IP whitelist (given as hash, single IPs)
	if($self->sqlgrey->ip_whitelisting) {
		my $wl_ranges = $self->sqlgrey->read_whitelist_ip;
		while ( my($ip,$desc) = each %$wl_ranges) {
			$self->postfwd->add_entry($desc, $ip, "whitelist");
			$self->sqlgrey->delete_whitelist_ip($ip);
		}
		$self->sqlgrey->disable_ip_whitelisting;
		$change |= 1;
	}

	# Convert IP blacklist (given as array, IP ranges)
	if($self->sqlgrey->ip_blacklisting) {
		my $bl_ranges = $self->sqlgrey->read_blacklist_ip;
		foreach my $ip_range (@$bl_ranges) {
			my $desc = $ip_range->{'description'};
			my $start = $ip_range->{'start'};
			my $end = $ip_range->{'end'};

			if($start eq $end) {
				my $rc = $self->postfwd->add_entry($desc, $start, "blacklist");
			} else {
				my $rc = $self->postfwd->add_entry($desc, $start . " - " . $end, "blacklist");
			}

		}

		foreach my $ip_range (@$bl_ranges) {
			my $start = $ip_range->{'start'};
			$self->sqlgrey->delete_blacklist_ip($start);
		}

		$self->sqlgrey->disable_ip_blacklisting;
		$change |= 1;
	}

	# Convert whitelisted email addresses
	if($self->sqlgrey->addr_whitelisting) {
		my $wl_addrs = $self->sqlgrey->read_whitelist_addr;
		while ( my($addr,$desc) = each %$wl_addrs) {
			$self->postfwd->add_entry($desc, $addr, "whitelist");
			$self->sqlgrey->delete_whitelist_addr($addr);
		}
		$self->sqlgrey->disable_addr_whitelisting;
		$change |= 1;
	}


	# Convert blacklisted email addresses
	if($self->sqlgrey->addr_blacklisting) {
		my $bl_addrs = $self->sqlgrey->read_blacklist_addr;
		while ( my($addr,$desc) = each %$bl_addrs) {
			$self->postfwd->add_entry($desc, $addr, "blacklist");
			$self->sqlgrey->delete_blacklist_addr($addr);
		}
		$self->sqlgrey->disable_addr_blacklisting;
		$change |= 1;
	}

	# Finalize
	if($change) {
		$self->sqlgrey->commit;			# Remove all sqlgrey-based entries
		$self->postfwd->enable_bwman;
		$self->postfwd->commit;
		# $self->commit;
	}
}

sub set_smtpd_timeout($$) {
	my $self = instance(shift);
	$self->postfix->smtpd_timeout(shift);	
}

# TT: admin/antispam/smtp/advanced.inc.tt2
sub get_smtpd_timeout($) {
	my $self = instance(shift);
	return $self->postfix->smtpd_timeout();
}

sub set_smtpd_queuetime($$) {
	my $self = instance(shift);
	$self->postfix->smtpd_queuetime(shift);	
}

# TT: admin/antispam/smtp/advanced.inc.tt2
sub get_smtpd_queuetime($) {
	my $self = instance(shift);
	return $self->postfix->smtpd_queuetime();
}


# TT: admin/antispam/general/greylisting.inc.tt2
### Greylisting through PostFWD
sub greylisting ($) {
	my $self = instance(shift);
	# return $self->sqlgrey->greylisting();
	return $self->postfwd->get_status_greylisting;
}

sub enable_greylisting ($) {
	my $self = instance(shift);
	$self->postfwd->enable_greylisting;
	$self->sqlgrey->enable_greylisting;
	$self->postfix->enable_greylisting;
}

sub disable_greylisting ($) {
	my $self = instance(shift);
	$self->postfwd->disable_greylisting;
	$self->sqlgrey->disable_greylisting;
	$self->postfix->disable_greylisting;
}

# PostFWD Selective Greylisting
sub selective_greylisting ($) {
	my $self = instance(shift);
	# return $self->sqlgrey->greylisting();
	return $self->postfwd->get_status_selective_greylisting;
}

sub enable_selective_greylisting ($) {
	my $self = instance(shift);
	#$self->sqlgrey->enable_greylisting();
	$self->postfwd->enable_selective_greylisting;
	$self->sqlgrey->enable_selective_greylisting;
	$self->postfix->enable_selective_greylisting;
}

sub disable_selective_greylisting ($) {
	my $self = instance(shift);
	# $self->sqlgrey->disable_greylisting();
	$self->postfwd->disable_selective_greylisting;
	$self->sqlgrey->disable_selective_greylisting;
	$self->postfix->disable_selective_greylisting;
}


sub greylisting_authtime {
	my $self = instance(shift);
	return $self->sqlgrey->greylisting_authtime(shift);
}

sub greylisting_triplettime {
	my $self = instance(shift);
	return $self->sqlgrey->greylisting_triplettime(shift);
}

sub greylisting_connectage {
        my $self = instance(shift);
        return $self->sqlgrey->greylisting_connectage(shift);
}

sub greylisting_domainlevel {
        my $self = instance(shift);
        return $self->sqlgrey->greylisting_domainlevel(shift);
}

sub greylisting_message {
        my $self = instance(shift);
        return $self->sqlgrey->greylisting_message(shift);
}

### Obsolete white/blacklists
sub ip_blacklisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->ip_blacklisting();
}

sub enable_ip_blacklisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->enable_ip_blacklisting();
}

sub disable_ip_blacklisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->disable_ip_blacklisting();
}

sub create_blacklist_ip ($$$$) {
	my $self = instance(shift);
	my $range_start = shift;
	my $range_end = shift;
	my $description = shift;

	my $range = {
		start => $range_start,
		end => $range_end
	};

	if( ip_dec( $range->{'start'} ) > ip_dec( $range->{'end'} ) ) {
		throw Underground8::Exception::FalseRange();
	}   

	my $res = $self->check_overlapping( $self->read_blacklist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExists();
	}

	$res = $self->check_overlapping( $self->read_whitelist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_ipwhitelist', $res );
	}

	$res = $self->check_overlapping( $self->get_ip_range_whitelist, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'policy_internal_ip_whitelist', $res );
	}

	$self->sqlgrey->create_blacklist_ip( $range_start, $range_end, $description );
}

# GUI: LimesGUI/Controller/Admin/Antispam/Externalblacklists.pm
sub read_blacklist_ip ($) {
	my $self = instance(shift);
	return $self->sqlgrey->read_blacklist_ip();
	
}

# not used, but good to be here
sub update_blacklist_ip ($$$) {
	my $self = instance(shift);
	my $range_start = shift;
	my $range_end = shift;
	my $description = shift;
	$self->sqlgrey->update_blacklist_ip($range_start, $range_end, $description);
}

sub delete_blacklist_ip ($$) {
	my $self = instance(shift);
	my $address = shift;
	$self->sqlgrey->delete_blacklist_ip($address);
}

sub ip_whitelisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->ip_whitelisting();
}

sub enable_ip_whitelisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->enable_ip_whitelisting();
}

sub disable_ip_whitelisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->disable_ip_whitelisting();
}

sub create_whitelist_ip ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;

	my $range = {
		start => $address,
		end => $address
	};

	my $res = $self->check_overlapping( $self->read_whitelist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExists();
	}

	$res = $self->check_overlapping( $self->read_blacklist_ip, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_ipblacklist', $res );
	}

	$res = $self->check_overlapping( $self->get_ip_range_whitelist, $range );
	if( $res ) {
		throw Underground8::Exception::EntryExistsIn( 'policy_internal_ip_whitelist', $res );
	}

	$self->sqlgrey->create_whitelist_ip($address, $description);
}

sub read_whitelist_ip ($) {
	my $self = instance(shift);
	return $self->sqlgrey->read_whitelist_ip();
}

# not used, but good to be here
sub update_whitelist_ip ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;
	$self->sqlgrey->update_whitelist_ip($address, $description);
}

sub delete_whitelist_ip ($$) {
	my $self = instance(shift);
	my $address = shift;
	$self->sqlgrey->delete_whitelist_ip($address);
}

sub addr_blacklisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->addr_blacklisting();
}

sub enable_addr_blacklisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->enable_addr_blacklisting();
}

sub disable_addr_blacklisting ($) {
	my $self = instance(shift);
	$self->sqlgrey->disable_addr_blacklisting();
}

sub create_blacklist_addr ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;

	if( $self->read_whitelist_addr->{$address} ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_emailaddresswhitelist', $address );
	}

	$address =~ /(\@.*)$/;
	if( ($address !~ /^@/ ) && $self->read_whitelist_addr->{$1} ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_emailaddresswhitelist', $1 );
	}
	
	$self->sqlgrey->create_blacklist_addr( $address, $description );
	
	if( ($address =~ /^@/ ) && $self->check_gapping( $address, $self->read_whitelist_addr ) ) {
		return 'error_entry_gap_blacklist,nav_policy_emailaddresswhitelist';
	}
}

sub read_blacklist_addr ($) {
	my $self = instance(shift);
	return $self->sqlgrey->read_blacklist_addr();
}

# not used, but good to be here
sub update_blacklist_addr ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;
	$self->sqlgrey->update_blacklist_addr($address, $description);
}

sub delete_blacklist_addr ($$) {
	my $self = instance(shift);
	my $address = shift;
	$self->sqlgrey->delete_blacklist_addr($address);
}

sub addr_whitelisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->addr_whitelisting();
}

sub enable_addr_whitelisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->enable_addr_whitelisting();
}

sub disable_addr_whitelisting ($) {
	my $self = instance(shift);
	return $self->sqlgrey->disable_addr_whitelisting();
}

sub create_whitelist_addr ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;

	if( $self->read_blacklist_addr->{$address} ) {
		throw Underground8::Exception::EntryExistsIn( 'nav_policy_emailaddressblacklist', $address );
	}

	if( ($address =~ /^@/ ) && $self->domain_in_blacklist_addr( $address, $self->read_blacklist_addr ) ) {
		throw Underground8::Exception::EntryIllegal( 'nav_policy_emailaddressblacklist', $address );
	}

	$self->sqlgrey->create_whitelist_addr($address, $description);

	if( ($address !~ /^@/ ) && $self->check_gapping( $address, $self->read_blacklist_addr ) ) {
		return 'error_entry_gap_whitelist,nav_policy_emailaddressblacklist';
	}
}

sub read_whitelist_addr ($) {
	my $self = instance(shift);
	return $self->sqlgrey->read_whitelist_addr();
}

# not used, but good to be here
sub update_whitelist_addr ($$$) {
	my $self = instance(shift);
	my $address = shift;
	my $description = shift;
	$self->sqlgrey->update_whitelist_addr($address, $description);
}

sub delete_whitelist_addr ($$) {
	my $self = instance(shift);
	my $address = shift;
	$self->sqlgrey->delete_whitelist_addr($address);
}

sub set_postfixsqlgrey_mysql_username ($@) {
	my $self = instance(shift);
	$self->sqlgrey->mysql_username(shift);
}

sub set_postfixsqlgrey_mysql_database ($@) {
	my $self = instance(shift);
	$self->sqlgrey->mysql_database(shift);
}

sub set_postfixsqlgrey_mysql_host ($@) {
	my $self = instance(shift);
	$self->sqlgrey->mysql_host(shift);
}

sub set_postfixsqlgrey_mysql_password ($@) {
	my $self = instance(shift);
	$self->sqlgrey->mysql_password(shift);
}

#### Import/Export ####

sub load_config ($) {
	my $self = instance(shift);
	$self->load_config_xml_smart();
}

sub create_ca_certificates($) {
	my $self = shift;

	my $capath = "$g->{'cfg_cacert_dir'}";
	my $global_cacert = "$g->{'cfg_cacert_dir'}/ca-certificates.crt";

	# concatenate all the other certificates
	if( ! -f $global_cacert ) {
		safe_system( "$g->{cmd_cat} '$g->{ca_certificates}' '$capath/smtp'* > '$global_cacert'", 0, 1 );
	}
}

sub load_config_xml_smart ($) {
	my $self = instance(shift);
	my $infile = $self->config_filename();

	my $XML = new XML::Smart($infile,'XML::Smart::Parser');
	$XML = $XML->cut_root;

	## Import of Postfix
	my $postfix = $XML->{'postfix'}->tree_pointer_ok;
	my @make_array = qw(smtpd_recipient_restrictions smtpd_sender_restrictions smtpd_client_restrictions);

	foreach my $field (@make_array) {
		$postfix->{'_config'}->{$field} = [];
		foreach my $entry (@{$XML->{'postfix'}->{'_config'}->{$field}}) {
			push @{$postfix->{'_config'}->{$field}}, sprintf('%s',$entry);
		}
	}
	
	if(ref($postfix->{'_ip_range_whitelist'}) eq '') {
		 $postfix->{'_ip_range_whitelist'} = [];
	} elsif (ref($postfix->{'_ip_range_whitelist'}) eq 'HASH') {
		$postfix->{'_ip_range_whitelist'} = [{
			start => $postfix->{'_ip_range_whitelist'}->{'start'},
			end => $postfix->{'_ip_range_whitelist'}->{'end'},
			description => $postfix->{'_ip_range_whitelist'}->{'description'}
		}];
	}

	if(!$postfix->{'_options'}->{'backscatter_key'}) {
		my $new_backscatter_key = $self->create_backscatter_key();
		$postfix->{'_options'}->{'backscatter_key'} = $new_backscatter_key;
	}

	if ($postfix->{'_options'}->{'backscatter_protection'} ne "0" && 
		$postfix->{'_options'}->{'backscatter_protection'} ne "1") {
		$postfix->{'_options'}->{'backscatter_protection'} = 0;
	}

	foreach my $server_id (keys %{$postfix->{'_domains'}->{'relay_smtp'}}) {
		if(ref($postfix->{'_domains'}->{'relay_smtp'}{$server_id}{'ldap_server'}) eq 'ARRAY') {
			my @tmp_ldap_server;
			foreach my $ldap_server (@{$postfix->{'_domains'}->{'relay_smtp'}{$server_id}{'ldap_server'}}) {
				push @tmp_ldap_server, "$ldap_server->{'CONTENT'}";
			}

			$postfix->{'_domains'}->{'relay_smtp'}{$server_id}{'ldap_server'} = \@tmp_ldap_server;
		}
	}

	# here we load the usermaps file ... it's an extra XML file!
	if (-f $g->{'cfg_usermaps'}) {
		my $file = $g->{'cfg_usermaps'};
		my $dump =  new XML::Dumper;
		my $usermaps = $dump->xml2pl( $file );
		$self->postfix->usermaps($usermaps);
	}

	## Import of SQLGrey 
	my $sqlgrey = $XML->{'sqlgrey'}->tree_pointer_ok;
	my @black_white_lists = qw(_addr_whitelist _addr_blacklist _ip_whitelist _ip_blacklist);
	foreach my $list (@black_white_lists) {
		if(	@{$XML->{'sqlgrey'}->{$list}} && 
			$XML->{'sqlgrey'}->{$list}->{'address'} && 
			$XML->{'sqlgrey'}->{$list}->{'address'} ne '')
		{
				$sqlgrey->{$list} = { };
				foreach my $entry (@{$XML->{'sqlgrey'}->{$list}}) {
					$sqlgrey->{$list}->{$entry->{'address'}} = sprintf('%s',$entry->{'description'});
				}
		} elsif(@{$XML->{'sqlgrey'}->{$list}} && 
				$XML->{'sqlgrey'}->{$list}->{'start'} && 
				$XML->{'sqlgrey'}->{$list}->{'start'} ne '')
		{
			$sqlgrey->{$list} = [ ];
			foreach my $entry (@{$XML->{'sqlgrey'}->{$list}}) {
				my $range = {
					start => "$entry->{'start'}",
					end => "$entry->{'end'}",
					description => "$entry->{'description'}",
				};
				my $ranges = $sqlgrey->{$list};
				push( @$ranges, $range );
			}
		} else {
			$sqlgrey->{$list} = { };
		}
	}

	my @string_to_int = qw(addr_blacklisting addr_whitelisting ip_blacklisting ip_whitelisting);
	foreach my $entry (@string_to_int) {
		if($sqlgrey->{'_config'}->{$entry}) {
			$sqlgrey->{'_config'}->{$entry} = sprintf('%d',$sqlgrey->{'_config'}->{$entry});
		}
	}
	
	if(ref($sqlgrey->{'_ip_blacklist'}) eq '') {
		 $sqlgrey->{'_ip_blacklist'} = [];
	} elsif (ref($sqlgrey->{'_ip_blacklist'}) eq 'HASH') {
		if( scalar( keys %{ $sqlgrey->{'_ip_blacklist'} } ) ) {
			$sqlgrey->{'_ip_blacklist'} = [{
				start => $sqlgrey->{'_ip_blacklist'}->{'start'},
				end => $sqlgrey->{'_ip_blacklist'}->{'end'},
				description => $sqlgrey->{'_ip_blacklist'}->{'description'}
			}];
		} else {
			$sqlgrey->{'_ip_blacklist'} = [ ];
		}
	}
	
	## Import of Amavis
	my $amavis = $XML->{'amavis'}->tree_pointer_ok;
	my $ref = ref($amavis->{'_banned_attachments'});
	if(ref($amavis->{'_banned_attachments'}) eq '') {
		$amavis->{'_banned_attachments'} = [];
	} elsif(ref($amavis->{'_banned_attachments'}) eq 'HASH') {
		my $banned = $amavis->{'_banned_attachments'}->{'banned'};
		my $description = $amavis->{'_banned_attachments'}->{'description'};
		$amavis->{'_banned_attachments'} = [{'banned' => $banned, 'description' => $description}];
	}

	my $spamassassin = $XML->{'spamassassin'}->tree_pointer_ok;

	$self->postfix->import_params($postfix);
	$self->sqlgrey->import_params($sqlgrey);
	$self->amavis->import_params($amavis);
	$self->spamassassin->import_params($spamassassin);


	############# Conversion code for: B/W Lists, RBL Lists, Greylisting
	# Convert sqlgrey-style black-/whitelist to postfwd (done only once)
	convert_bwlists_sqlgrey2postfwd($self);

	# Import rbls.xml
	convert_rbl_sqlgrey2postfwd($self);

	# Turn on new greylisting engine if it was before
	if($self->sqlgrey->selective_greylisting) {
		$self->disable_greylisting;
		$self->enable_selective_greylisting;
	} elsif($self->sqlgrey->greylisting) {
		$self->disable_selective_greylisting;
		$self->enable_greylisting;
	} else {
		$self->disable_greylisting;
		$self->disable_selective_greylisting;
	}
}

sub save_config ($) {
	my $self = instance(shift);
	$self->save_config_xml_smart();
}

sub save_config_xml_smart ($) {
	my $self = instance(shift);
	my $outfile = $self->config_filename();
	my $XML = new XML::Smart('','XML::Smart::Parser');
	
	# clone it, or XML::Smart will give you double penetration
	my $postfix = clone($self->postfix->export_params());
	my $sqlgrey = clone($self->sqlgrey->export_params());
	my $amavis  = clone($self->amavis->export_params());
	my $spamass = clone($self->spamassassin->export_params());

	# here we write the usermaps xml file
	my $usermapsfile = $g->{'cfg_usermaps'};
	my $dump = new XML::Dumper;

	$dump->pl2xml( $self->postfix->usermaps(), $usermapsfile)
		or throw Underground8::Exception::FileOpen($usermapsfile); 

	$XML->{'root'}->{'postfix'} = $postfix;
	$XML->{'root'}->{'sqlgrey'} = $sqlgrey;
	$XML->{'root'}->{'amavis'}  = $amavis;
	$XML->{'root'}->{'spamassassin'} = $spamass;

	$XML->save($outfile);
}

#### Commit Changes (write configuration files and restart services) ####
sub has_changes ($) {
	my $self = instance(shift);
	return $self->{'_has_changes'};
}

sub commit ($) {
	my $self = instance(shift);
	my $ldap_override = shift;
	
	# we need this, so ldap.pl commit does not restart ALL antispam services!
	# calling commit with a parameter activates override
	if (! $ldap_override) {
		$ldap_override = 0;
	} else {
		$ldap_override = 1;
	}
	
	
	try {
		if ($self->prepare()) {
			my $sqlgrey_changed = $self->sqlgrey->is_changed;

			# TODO what is this?
			$self->create_ca_certificates();
                        print STDERR "Executed ominous \"create_ca_certificates\"\n";

			$self->clamav->commit() if ($self->clamav->is_changed && !$ldap_override);
                        print STDERR "Commited service clamav\n";
			#$self->kasperskyav->commit() if ($self->kasperskyav->is_changed && !$ldap_override);
			$self->virustotal->commit() if ($self->virustotal->is_changed && !$ldap_override);
                        print STDERR "Commited service virustotal\n";
			$self->spamassassin->commit() if ($self->spamassassin->is_changed && !$ldap_override);
                        print STDERR "Commited service spamassassin\n";
                        
                        # SQL Grey Commit is BROKEN, please investigate
			$self->sqlgrey->commit() if ($sqlgrey_changed && !$ldap_override);
                        print STDERR "Commited service sqlgrey\n";
			$self->amavis->commit() if (($self->amavis->is_changed || $self->spamassassin->is_changed) && (!$ldap_override));
                        print STDERR "Commited service amavis\n";
			$self->postfix->commit() if $self->postfix->is_changed || $sqlgrey_changed || $ldap_override;  # after sqlgrey (whitelists)
                        print STDERR "Commited service postfix\n";
			$self->postfwd->commit();
                        print STDERR "Commited service postfwd\n";
			$self->save_config() if (!$ldap_override);
			$self->{'_has_changes'} = 0;
		}
	} catch Underground8::Exception with {
		my $E = shift;
		$self->xml_restore();
		$self->load_config();

		# rethrow
		throw Underground8::Exception("rethrown",$E);
	} finally {
		$self->del_temp_dir();
	};
}

sub xml_config_file {
	return $g->{'cfg_antispam'};
}

########### CA certificates
sub cacert_assign() {
	my $self = instance(shift);
	my $smtp_name = shift;
	my $cacert = shift;
	return $self->postfix->cacert_assign( $smtp_name, $cacert );
}

sub cacert_unassign() {
	my $self = instance(shift);
	my $smtp_name = shift;
	return $self->postfix->cacert_unassign( $smtp_name );
}

#### Policy Settings
sub set_policy_external {
	my $self = shift;
	my $setting = shift;
	my $value = shift;

	unless ($setting || $value) {
		warn "Setting or Value not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		}
		$self->amavis->policy_external($setting,$value);
	}
}

sub policy_external {
	my $self = shift;
	my $setting = shift;

	unless ($setting) {
		warn "Setting not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		} else {
			return $self->amavis->policy_external($setting);
		}
	}
}

sub set_policy_whitelist {
	my $self = shift;
	my $setting = shift;
	my $value = shift;

	unless ($setting || $value) {
		warn "Setting or Value not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		}
		$self->amavis->policy_whitelist($setting,$value);
	}
}

sub policy_whitelist {
	my $self = shift;
	my $setting = shift;

	unless ($setting) {
		warn "Setting not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		} else {
			return $self->amavis->policy_whitelist($setting);
		}
	}
}

sub set_policy_smtpauth {
	my $self = shift;
	my $setting = shift;
	my $value = shift;

	unless ($setting || $value) {
		warn "Setting or Value not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		}
		$self->amavis->policy_smtpauth($setting,$value);
	}
}

sub policy_smtpauth {
	my $self = shift;
	my $setting = shift;

	unless ($setting) {
		warn "Setting not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		} else {
			return $self->amavis->policy_smtpauth($setting);
		}
	}
}

sub set_policy_internal {
	my $self = shift;
	my $setting = shift;
	my $value = shift;

	unless ($setting || $value) {
		warn "Setting or Value not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		}
		$self->amavis->policy_internal($setting,$value);
	}
}

sub policy_internal {
	my $self = shift;
	my $setting = shift;

	unless ($setting) {
		warn "Setting not defined!";
	} else {
		unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/) {
			warn "No valid setting supplied!"; 
		} else {
			return $self->amavis->policy_internal($setting);
		}
	}
}

###############
sub ip_dec {
	 my $ip = $_[0];
	 if ($ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
		 return (($1 << 24) + ($2 << 16) + ($3 << 8) + $4);
	 } else {
		 return 0;
	 }
}

sub check_range_overlap($$$$$) {
	my $self = shift;
	my $start1 = shift;
	my $end1 = shift;
	my $start2 = shift;
	my $end2 = shift;

	$start1 = ip_dec( $start1 );
	$end1 = ip_dec( $end1 );
	$start2 = ip_dec( $start2 );
	$end2 = ip_dec( $end2 );

	if( ($end2 < $start1) || ($start2 > $end1) ) {
		return 0;
	}
	
	return 1;
}

sub check_overlapping($$$) {
	my $self = shift;
	my $arr_ref = shift;	# [ {start, end, address, description } ]
	my $hash_ref = shift;	# { start, end, address, description }

	my ($start, $end);

	if( $hash_ref->{'address'} ) {
		# single IP
		$start = $hash_ref->{'address'};
		$end = $start;
	} elsif( $hash_ref->{'start'} && $hash_ref->{'end'} ) {
		# IP range
		$start = $hash_ref->{'start'};
		$end = $hash_ref->{'end'};
	} else {
		return "0.0.0.0";
	}

	if( ref( $arr_ref ) eq "HASH" ) {
		for my $item ( keys %$arr_ref )
		{
			# single IP
			if( $self->check_range_overlap( $item, $item, $start, $end ) )
			{
			return $item;
			}
		}
	} elsif( ref( $arr_ref ) eq "ARRAY" ) {
		for my $item ( @$arr_ref ) {
			if( $item->{'address'} ) {
				# single IP
				if( $self->check_range_overlap( $item->{'address'}, $item->{'address'}, $start, $end ) ) {
					return $item->{'address'};
				}
			} elsif( $item->{'start'} && $item->{'end'} ) {
				# IP range
				if( $self->check_range_overlap( $item->{'start'}, $item->{'end'}, $start, $end ) ) {
					return $item->{'start'} . "-" . $item->{'end'};
				}
			}
		}
	} else {
		return "0.0.0.0";
	}
	
	return 0;
}

sub check_gap($$$) {
	my $self = shift;
	my $domain = shift;
	my $address = shift;

	return 0 if( ($address =~ /^@/) && ($domain =~ /^@/) );
	return 0 if( ($address !~ /^@/) && ($domain !~ /^@/) );
	
	($address,$domain) = ($domain,$address) if( ($address =~ /^@/) && ($domain !~ /^@/) );
	
	return 1 if( $address =~ /$domain$/ );
	
	return 0;
}

sub check_gapping($$$) {
	my $self = shift;
	my $addr = shift;
	my $hash_ref = shift;

	foreach my $key ( keys %$hash_ref  ) {
		return 1 if( $self->check_gap( $addr, $key ) );
	}
	
	return 0;
}

sub domain_in_blacklist_addr($$$) {
	my $self = shift;
	my $domain = shift;
	my $hash_ref = shift;
	
	foreach my $key ( keys %$hash_ref ) {
		return 1 if( $domain =~ /$key$/ );
	}
	
	return 0;
}

# return TRUE if there is uploaded a certificat for postfix to be used as SSL certificate
sub postfix_ssl_certificate_present() {
	my $self = instance(shift);
	return $self->postfix->certificate_present();
}

# return TRUE if there is uploaded a private key for postfix to be used as SSL certificate
sub postfix_ssl_privatekey_present() {
	my $self = instance(shift);
	return $self->postfix->privatekey_present();
}

sub assign_cert($$) {
	my $self = instance(shift);
	my $cert = shift;
	
	$self->postfix->assign_cert( $cert );
}

sub assign_pkey($$) {
	my $self = instance(shift);
	my $cert = shift;

	$self->postfix->assign_pkey( $cert );
}

sub delete_cert($) {
	my $self = instance(shift);
	$self->postfix->delete_cert();
}

sub delete_pkey($) {
	my $self = instance(shift);
	$self->postfix->delete_pkey();
}


### Virus Scanning/AMaVis stuff
sub archive_maxfiles {
	my $self = instance(shift);
	return $self->amavis->archive_maxfiles;
}

sub set_archive_maxfiles {
	my $self = instance(shift);
	my $maxfiles = shift;

	if ($maxfiles) {
		$self->amavis->archive_maxfiles($maxfiles);
		$self->clamav->archive_maxfiles($maxfiles);
	}
	return $self->amavis->archive_maxfiles;
}

sub archive_recursion {
	my $self = instance(shift);
	return $self->amavis->archive_recursion;
}

sub set_archive_recursion {
	my $self = instance(shift);
	my $archive_recursion = shift;

	if ($archive_recursion) {
		$self->amavis->archive_recursion($archive_recursion);
		$self->clamav->archive_recursion($archive_recursion);
		#$self->kasperskyav->archive_recursion($archive_recursion);
	}
}

sub archive_maxfilesize {
	my $self = instance(shift);
	return $self->clamav->archive_maxfilesize;
}

sub set_archive_maxfilesize {
	my $self = instance(shift);
	$self->clamav->archive_maxfilesize(shift) if @_;
}

sub unchecked_subject_tag {
	my $self = instance(shift);
	return $self->amavis->unchecked_subject_tag;
}

sub set_unchecked_subject_tag {
	my $self = instance(shift);
	return $self->amavis->unchecked_subject_tag(shift) if @_;
}
 
sub enable_clamav() {
	my $self = instance(shift);
	return $self->amavis->enable_clamav;
}

sub disable_clamav() {
	my $self = instance(shift);
	return $self->amavis->disable_clamav;
}

sub clamav_enabled {
	my $self = instance(shift);
	return $self->amavis->clamav_enabled;
}

### Spamassassin
sub get_gtube($) {
	my $self = instance(shift);
	return $self->spamassassin->get_gtube();
}

sub set_gtube($$) {
	my $self = instance(shift);
	$self->spamassassin->set_gtube(shift) if @_;
	$self->amavis->restart();
}

sub get_gtube_score($) {
	my $self = instance(shift);
	return $self->spamassassin->get_gtube_score();
}

sub set_gtube_score($$) {
	my $self = instance(shift);
	$self->spamassassin->set_gtube_score(shift) if @_;
	$self->amavis->restart();
}

sub enable_language_filter($){
	my $self = instance(shift);
	$self->spamassassin->enable_language_filter();
	$self->amavis->restart();
}

sub disable_language_filter($){
	my $self = instance(shift);
	$self->spamassassin->disable_language_filter();
	$self->amavis->restart();
}

sub get_language_filter_status($){
	my $self = instance(shift);
	$self->spamassassin->get_language_filter_status();
}

sub get_allowed_languages($){
	my $self = instance(shift);
	$self->spamassassin->get_allowed_languages();
}

sub set_allowed_languages($$){
	my $self = instance(shift);
	$self->spamassassin->set_allowed_languages(shift);
	$self->amavis->restart();
}



sub create_ldap_maps {
	my $self = instance(shift);
	my $smtpsrvs = $self->postfix->smtpsrv_read;
	my $tmp_addr;
	my $all_ldap_addr;
	my $all_success = 1;
	my %known_domains;


	foreach my $server_id (keys %{$smtpsrvs}) {
		if ($smtpsrvs->{$server_id}{'ldap_enabled'}) {
			my $domains = $self->domains_linked($server_id);
			foreach my $domain ( @{$domains} ) {
				$all_ldap_addr->{$domain}{'addresses_defined'} = 0;
			}

			$tmp_addr = $self->{'_ldap_report'}->get_addresses($smtpsrvs->{$server_id}{'ldap_server'},
																$smtpsrvs->{$server_id}{'ldap_user'},
																$smtpsrvs->{$server_id}{'ldap_pass'},
																$smtpsrvs->{$server_id}{'ldap_base'},
																$smtpsrvs->{$server_id}{'ldap_filter'},
																$smtpsrvs->{$server_id}{'ldap_property'});
			# We only create new LDAP Maps if we successfully connected!
			foreach my $servertmp (keys %{$tmp_addr}) {
				# we only look further if the connection to a server was successful
				# everything else than bind code 0 (success) is bad!
				# also query code 1 is what we want!
				if ($servertmp ne "addr_list") {
					$all_success = 0 if (	(!$tmp_addr->{$servertmp}{'connection'}) || 
											(!$tmp_addr->{$servertmp}{'mesg'}{'query'} ||
										 	  $tmp_addr->{$servertmp}{'mesg'}{'bind_code'} ne "0"));
				}
			}

			foreach my $addr (@{$tmp_addr->{'addr_list'}}) {
				if ( $addr =~ /^(.+?)@(.+?)$/ ) {
					$known_domains{$2} = 0 unless $known_domains{$2} == 1;
					foreach my $domain (@{$domains}) {
						$known_domains{$domain} = 1;
						if ($domain eq $2) {
							$all_ldap_addr->{$domain}{'addresses_defined'} = 1;
							$all_ldap_addr->{$domain}{'addresses'}{$1}{'accept'} = "ldap";
						}
					}
				}
			}

			# If ldap_autolearn_domains is set, add newly found ones
			if($smtpsrvs->{$server_id}{'ldap_autolearn_domains'} == "1") {
				while(my ($domain_found, $isknown) = each(%known_domains)){
					aslog "info", "Found new domain $domain_found in LDAP -> auto-adding." unless $isknown;
					$self->domain_create($domain_found, $server_id, "yes") unless $isknown;
				}
			}

		}
	}

	if ($all_success) {
		my $ldapmaps_file = $g->{'ldap_maps_dir'}.$g->{'ldap_maps_cache_file'};

		my $dump = new XML::Dumper;
		$dump->pl2xml($all_ldap_addr, $ldapmaps_file);
	}
}

sub create_backscatter_key ($) {
## XXX dummy for as-oss lucid
#	my $self = instance(shift);
#	my $key;
#	my $urandom = new String::Urandom;
#
#	$urandom->str_length(64);
#	$key = uc($urandom->rand_string());
#	return $key;
	return ("x" x 64);
}


1;

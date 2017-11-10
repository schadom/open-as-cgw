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


package LimesGUI::Controller::Admin::System::Security;

use base 'LimesGUI::Controller';
use namespace::autoclean;
use strict;
use warnings;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Utils;
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	# $c->stash->{'system'} = $appliance->system;
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{template} = 'admin/system/security.tt2';
}

sub error {
	my ($c, $E) = @_;
	aslog "warn", "Error, caught exception: $E";
	$c->session->{'exception'} = $E;
	$c->stash->{'redirect_url'} = $c->uri_for('/error');
	$c->stash->{'template'} = 'redirect.inc.tt2';
}


sub add_range : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(range_start range_end)],
		optional => [qw(description)],
		constraint_methods => {
			range_start => FV_net_IPv4(),
			range_end => FV_net_IPv4(),
			description => qr/[\w ]{1,30}$/
		}
	};
	
	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {
		try {
			my ($start, $end, $desc) = ($c->req->param('range_start'), $c->req->param('range_end'), $c->req->param('description'));

			$appliance->system->add_ip_range_whitelist($start, $end, $desc);
			$appliance->system->commit;
			aslog "info", "Added admin range $desc [$start -> $end]";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception::TooBigRange with {
			aslog "warn", "Error: admin range too big";
			$c->stash->{'box_status'}->{'custom_error'} = 'error_too_big_admin_range';
		} catch Underground8::Exception::FalseRange with {
			aslog "warn", "Error: admin range illegal";
			$c->stash->{'box_status'}->{'custom_error'} = 'error_illegal_range';
		} catch Underground8::Exception::EntryExists with {
			aslog "warn", "Error: admin range overlaps entry";
			$c->stash->{'box_status'}->{'custom_error'} = 'error_range_entry_overlap';
		} catch Underground8::Exception with {
			error($c, shift);
		};
	}

	# $c->stash->{'system'} = $appliance->system;
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'disabled'} = $appliance->system->check_revoke_apply;
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();

	$c->stash->{'template'} = 'admin/system/security.tt2';
	$c->stash->{'no_wrapper'} = '1';
}


sub del_range : Local {
	my ($self, $c, $start) = @_;
	my $appliance = $c->config->{'appliance'};

   
	if(defined $start && length $start) {
		try {
			$appliance->system->del_ip_range_whitelist($start);
			$appliance->system->commit;

			aslog "info", "Removed admin range $start";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception::EntryNotExists with {
			aslog "warn", "Error removing admin range, entry does not exist";
			$c->stash->{'box_status'}->{'custom_error'} = 'error_admin_range_entry_doesnt_exist';
		} catch Underground8::Exception with {
			error($c, shift);
		};
	}
	
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'template'} = 'admin/system/security.tt2';
	$c->stash->{'no_wrapper'} = '1';
}

sub ca_assign : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $upload = $c->req->upload('file_pem'); #cacert
	my $smtpsrv = $c->req->param('smtpsrv');
	my $cacert;

	if(defined $upload && $upload->size < 4000 && $upload->filename =~ /.(crt|CRT|pem|PEM)$/) {
		$cacert = $upload->tempname;
		my $tmp_cacert = "/tmp/" . getpgrp(0);

		safe_system( "$g->{cmd_sed} -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' '$cacert' > '$tmp_cacert'" );
		if( -z $tmp_cacert) {
			unlink $tmp_cacert;
			$c->stash->{'box_status'}->{'custom_error'} = 'status_cacert_invalid';
			$c->stash->{'phail'} = "assign";
		} else {
			rename($tmp_cacert, $cacert);
			$appliance->antispam->cacert_assign($smtpsrv, $cacert);
			$appliance->antispam->commit;

			aslog "info", "Assign CA certificate for server $smtpsrv, file $cacert";
			$c->stash->{'box_status'}->{'success'} = 'success';
		}
	} else {
		aslog "warn", "CACert upload exceeded filesize limit";
		$c->stash->{'box_status'}->{'custom_error'} = 'status_cacert_exceeded_size';
		$c->stash->{'phail'} = "assign";
	}

	$c->stash->{'done'} = 'assign';
	$c->stash->{'template'} = 'admin/system/security.tt2';
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
}

sub ca_unassign : Local {
	my ($self, $c, $start) = @_;
	my $appliance = $c->config->{'appliance'};

	my $smtpsrv = $c->req->param('smtpsrv');

	try {
		$appliance->antispam->cacert_unassign($smtpsrv);
		$appliance->antispam->commit;

		aslog "info", "Unassigned CA certificate from SMTP server $smtpsrv";
		$c->stash->{'box_status'}->{'success'} = 'success_unassign';
	} catch Underground8::Exception with {
		aslog "warn", "Error unassigning CA cerficate from SMTP server";
		error($c, shift);
	};

	$c->stash->{'template'} = 'admin/system/security.tt2';
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
}

sub assign_keypair : Local {
	my ($self, $c, $start) = @_;
	my $appliance = $c->config->{'appliance'};
	my $limit = 8000;

	my $crt = $c->req->upload('file_cert');
	my $key = $c->req->upload('file_key');


	try {
		my ($tmp_crt, $tmp_key);

		if(defined($crt) && defined($key) && ($key->size < $limit) && ($crt->size < $limit)) {
			my ($crt_name, $key_name) = ($crt->tempname, $key->tempname);
			$tmp_crt = "/tmp/" . getpgrp(0) . "_crt";
			$tmp_key = "/tmp/" . getpgrp(0) . "_key";
	

			if(system("cat $crt_name | grep CERT")==0 && system("cat $key_name | grep PRIVATE")==0){
				safe_system( "$g->{cmd_sed} -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' '$crt_name' > '$tmp_crt'" );
				if(-z $tmp_crt) {
					$crt = "";
					unlink $tmp_crt;
				}
		
				safe_system( "$g->{cmd_sed} -n '/-----BEGIN RSA PRIVATE KEY-----/,/-----END RSA PRIVATE KEY-----/p' '$key_name' > '$tmp_key'" );
				if(-z $tmp_key) {
					$key = "";
					unlink $tmp_key;
				}
		
				if($crt && $key) {
					$appliance->antispam->assign_cert($tmp_crt);
					$appliance->antispam->assign_pkey($tmp_key);
					$appliance->antispam->commit();
				}
		
				if($appliance->antispam->postfix_ssl_certificate_present && $appliance->antispam->postfix_ssl_privatekey_present) {
					aslog "info", "Assigned keypair to Postfix";
					$c->stash->{'box_status'}->{'success'} = 'success_keypair_assign';
				} else {
					aslog "warn", "Uploaded keypair is invalid";
					$c->stash->{'box_status'}->{'custom_error'} = 'status_cert_invalid';
				}
			} else {
				aslog "warn", "Uploaded keypair is invalid";
				$c->stash->{'box_status'}->{'custom_error'} = 'status_cert_invalid';
			}
		} else {
			aslog "warn", "Certificate status invalid";
			$c->stash->{'box_status'}->{'custom_error'} = 'status_cert_invalid';
		}
	} catch Underground8::Exception::CertificateInvalid with {
		aslog "warn", "Certificate status invalid";
		$c->stash->{'box_status'}->{'custom_error'} = 'status_cert_invalid';
	} catch Underground8::Exception::NoMatchCertificatePrivatekey with {
		aslog "warn", "Keypair does not match (pub vs priv)";
		$c->stash->{'box_status'}->{'custom_error'} = 'status_no_match_cert_pkey';
	} catch Underground8::Exception with {
		aslog "warn", "Error setting Postfix keypair";
		$c->stash->{'box_status'}->{'custom_error'} = 'status_cert_invalid';
		# error($c, shift);
	};

	if($c->stash->{'box_status'}->{'success'} ne 'success_keypair_assign'){
		$c->stash->{'phail'} = "revoke";
	}

	# $c->stash->{'template'} = 'admin/system/security/ssl.inc.tt2';
	$c->stash->{'done'} = 'revoke';
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'template'} = 'admin/system/security.tt2';
}

sub revoke_keypair : Local {
	my ($self, $c, $start) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->antispam->delete_pkey();
		$appliance->antispam->delete_cert();
		$appliance->commit;

		aslog "info", "Revoked Postfix keypair";
		$c->stash->{'box_status'}->{'success'} = 'success_del';
	} catch Underground8::Exception with {
		aslog "warn", "Error revoking Postfix keypair";
		error($c, shift);
	};

	$c->stash->{'done'} = 'revoke_real';
	$c->stash->{'template'} = 'admin/system/security/ssl.inc.tt2';
	$c->stash->{'ip_ranges'} = $appliance->system->get_ip_range_whitelist();
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
}


1;

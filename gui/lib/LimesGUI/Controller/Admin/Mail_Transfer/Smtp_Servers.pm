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


package LimesGUI::Controller::Admin::Mail_Transfer::Smtp_Servers; 

use base 'LimesGUI::Controller';
use strict;
use warnings;
use namespace::autoclean; 
use Error qw(:try);
use Underground8::Exception::SMTPServerExists;
use Underground8::Exception::SMTPServerNotExists;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Utils;
use Underground8::Log;
use Data::Dumper;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{'smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'no_wrapper'} = "1";
}

sub edit : Local {
	my ( $self, $c, $id ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	$c->stash->{'show_details'} = "1";
	update_stash($self, $c);
}

sub delete : Local {
	my ( $self, $c, $smtpsrv_id ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $force_all = 1;
	if ($smtpsrv_id) {
		my @arr = sort @{ $appliance->antispam->domains_linked( $smtpsrv_id ) };
		$c->stash->{'domains_linked'} = \@arr;

		if( scalar @{ $c->stash->{'domains_linked'} } && ! $force_all ) {
			$c->stash->{'template'} = 'admin/antispam/smtp_servers/confirm_delete.inc.tt2';
		} else {
			try {
				# delete all the domains associated with this smtp server
				foreach my $domain ( @{ $c->stash->{'domains_linked'} } ) {
					$appliance->antispam->domain_delete( $domain );
					aslog "debug", "Cascaded delete of domain $domain";
				}

				$appliance->antispam->smtpsrv_delete( $smtpsrv_id );
				$appliance->antispam->commit();
				aslog "info", "Deleted SMTP server $smtpsrv_id, cascading all its domains";
				$c->stash->{'box_status'}->{'success'} = 'del_success';
			} catch Underground8::Exception::SMTPServerNotExists with {
				aslog "warn", "Error deleting smtp server: $smtpsrv_id does not exist";
				$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_smtp_servers_select_notexistent';
			} catch Underground8::Exception with {
				my $E = shift;
				aslog "warn", "Error deleting smtp server, caught exception $E";
				$c->session->{'exception'} = $E;
				$c->stash->{'redirect_url'} = $c->uri_for('/error');
				$c->stash->{'template'} = 'redirect.inc.tt2';
			};
		}
	}

	$c->stash->{'relay_smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'has_changes'} = $appliance->antispam->has_changes();

	my $smtpsrvs = $appliance->antispam->smtpsrv_read();
	$c->stash->{'smtpsrv_name'} = $smtpsrv_id;
	$c->stash->{'smtpsrv_value'} = $smtpsrvs->{$smtpsrv_id};

	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	update_stash($self, $c);
}

sub add_update : Local {
	my ( $self, $c, $smtpsrv_id ) = @_;
	my $appliance = $c->config->{'appliance'};

	if($smtpsrv_id eq "new") {
		$c->stash->{'use_ldap'} = "0";
		$c->stash->{'use_smtpauth'} = "0";
	} else {
		my $smtpsrvs = $appliance->antispam->smtpsrv_read();
		my $srv = $smtpsrvs->{$smtpsrv_id};


		$c->stash->{'use_ldap'} = $srv->{'ldap_enabled'};
		$c->stash->{'smtpauth'} = ($srv->{'auth_enabled'} ? $srv->{'ssl_validation'} : 0);
		$c->stash->{'smtpsrv_name'} = $smtpsrv_id;
		$c->stash->{'description'} = $srv->{'descr'};
		$c->stash->{'address'} = $srv->{'addr'};
		$c->stash->{'port'} = $srv->{'port'};
		$c->stash->{'cutdelim'} = ($srv->{'use_fqdn'}) ? 0 : 1;

		$c->stash->{'ldap_username'} = $srv->{'ldap_user'};
		$c->stash->{'ldap_password'} = $srv->{'ldap_pass'};
		$c->stash->{'ldap_basedn'} = $srv->{'ldap_base'};
		$c->stash->{'ldap_server'} = $srv->{'ldap_server'};
		$c->stash->{'ldap_filter'} = $srv->{'ldap_filter'};
		$c->stash->{'ldap_properties'} = $srv->{'ldap_property'};
		# $c->stash->{'ldap_testmail'} = $srv->{'ldap_'};
		$c->stash->{'ldap_autolearn_domains'} = ($srv->{'ldap_autolearn_domains'} ? "1" : "0");
	}


	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	$c->stash->{'show_details'} = "1";
	update_stash($self, $c);
}

sub save_server : Local {
	my ( $self, $c, $smtpsrv_id ) = @_;
	my $appliance = $c->config->{'appliance'}; 
	my $form_profile = {
		required => [qw(description address port)],
		optional => [qw(ldap_username ldap_password ldap_server ldap_basedn ldap_filter ldap_properties ldap_testmail ldap_autolearn_domains)],
		constraint_methods => {
			description => qr/.+/,
			address => ip_address_or_hostname(),
			port => FV_num_int(),
			smtpauth => qr/^[0-3].$/,

			ldap_username => qr/.+/,
			ldap_password => qr/.+/,
			ldap_server => qr/.+/,
			ldap_basedn => qr/.+/,
			ldap_filter => qr/.+/,
			ldap_properties => qr/.+/,
			ldap_testmail => email(),
		}
	};

	# If LDAP is used, mark as required
	if($c->req->params->{'use_ldap'}) {
		push @{$form_profile->{'required'}}, qw(ldap_server ldap_username ldap_password ldap_basedn ldap_filter ldap_properties ldap_testmail);
	}

	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {
		try {
			my $description = $c->req->params->{'description'};
			my $address = $c->req->params->{'address'};
			my $port = $c->req->params->{'port'};
			my $smtpauth = $c->req->params->{'smtpauth'};
			my $cutdelim = $c->req->params->{'cutdelim'};
			my $auth_methods = 11; # Cram-MD5 (8) + Login(2) + Plain(1)
			my $use_ldap = $c->req->params->{'use_ldap'};

			my $ldap_username = $c->req->params->{'ldap_username'};
			my $ldap_password = $c->req->params->{'ldap_password'};
			my $ldap_server = $c->req->params->{'ldap_server'};
			my $ldap_basedn = $c->req->params->{'ldap_basedn'};
			my $ldap_filter = $c->req->params->{'ldap_filter'};
			my $ldap_properties = $c->req->params->{'ldap_properties'};
			my $ldap_testmail = $c->req->params->{'ldap_testmail'};
			my $ldap_autolearn_domains = $c->req->params->{'ldap_autolearn_domains'};
			my $no_ldap_test = $c->req->params->{'no_ldap_test'};

			# This will raise an exception if unlucky
			if($use_ldap && !$no_ldap_test){
				$appliance->report->ldap->test_query($ldap_server, $ldap_username, $ldap_password,
													 $ldap_basedn, $ldap_filter, $ldap_properties, $ldap_testmail);
			}

			if($smtpsrv_id eq "new") {
				my $smtpsrv = $appliance->antispam->smtpsrv_create(
					$description, 
					$address, 
					$port,
					$smtpauth ? 1 : 0, 
					$auth_methods,
					$smtpauth ? $smtpauth : 1, # senseless backend
					#1, # use fqdn
					$cutdelim ? 0 : 1,
					$use_ldap,
					$ldap_server,
					$ldap_username,
					$ldap_password,
					$ldap_basedn,
					$ldap_filter,
					$ldap_properties,
					$ldap_autolearn_domains ? 1 : 0,
				);
			} else {
				my $smtpsrv = $appliance->antispam->smtpsrv_update(
					$smtpsrv_id,
					$description, 
					$address, 
					$port,
					$smtpauth ? 1 : 0, 
					$auth_methods,
					$smtpauth ? $smtpauth : 1, # senseless backend
					#1, # use fqdn
					$cutdelim ? 0 : 1,
					$use_ldap,
					$ldap_server,
					$ldap_username,
					$ldap_password,
					$ldap_basedn,
					$ldap_filter,
					$ldap_properties,
					$ldap_autolearn_domains ? 1 : 0,
				);
			}

			$appliance->antispam->commit;
			aslog "info", "Saved SMTP server settings for server $description ($address)";
			$c->stash->{'box_status'}->{'success'} = ($smtpsrv_id eq "new" ? 'success_create' : 'success_update');
		} catch Underground8::Exception::SMTPServerNotExists with {
			aslog "warn", "Error saving smtp server settings: Server does not exist";
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_smtp_servers_add_update_error_smtpsrv_not_exists';
		} catch Underground8::Exception::SMTPServerExists with {
			aslog "warn", "Error saving smtp server settings: Server exists";
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_smtp_servers_add_update_error_smtpsrv_exists';
		} catch Underground8::Exception::LDAPTestFailed with {
			aslog "warn", "Error saving smtp server settings: LDAP test failed";
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_smtp_servers_add_update_error_ldap_test';
			$c->stash->{'no_ldap_test'} = "1";
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error saving smtp server settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		}
	} 

	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	update_stash($self, $c);

	$c->stash->{'smtpsrv_name'} = $smtpsrv_id;
	$c->stash->{'smtpauth'} = $c->req->params->{'smtpauth'};
	$c->stash->{'description'} = $c->req->params->{'description'};
	$c->stash->{'address'} = $c->req->params->{'address'};
	$c->stash->{'port'} = $c->req->params->{'port'};
	$c->stash->{'cutdelim'} = $c->req->params->{'cutdelim'};

	$c->stash->{'use_ldap'} = $c->req->params->{'use_ldap'};
	$c->stash->{'use_ldap'} = $c->req->params->{'use_ldap'};
	$c->stash->{'ldap_username'} = $c->req->params->{'ldap_username'};
	$c->stash->{'ldap_password'} = $c->req->params->{'ldap_password'};
	$c->stash->{'ldap_basedn'} = $c->req->params->{'ldap_basedn'};
	$c->stash->{'ldap_server'} = $c->req->params->{'ldap_server'};
	$c->stash->{'ldap_filter'} = $c->req->params->{'ldap_filter'};
	$c->stash->{'ldap_properties'} = $c->req->params->{'ldap_properties'};
	$c->stash->{'ldap_autolearn_domains'} = ($c->req->params->{'ldap_autolearn_domains'} == "1") ? "1" : "0";

	$c->stash->{'show_details'} = "1";
}

sub toggle_ldap : Local {
	my ( $self, $c, $use_ldap, $smtpsrv_id ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'description'} = $c->req->params->{'description'};
	$c->stash->{'port'} = $c->req->params->{'port'};
	$c->stash->{'address'} = $c->req->params->{'address'};

	# If we edit an existing server, refetch known values
	if($smtpsrv_id ne "new") {
		my $smtpsrvs = $appliance->antispam->smtpsrv_read();
		my $srv = $smtpsrvs->{$smtpsrv_id};

		$c->stash->{'smtpsrv_name'} = $smtpsrv_id;
		$c->stash->{'description'} = $srv->{'descr'};
		$c->stash->{'address'} = $srv->{'addr'};
		$c->stash->{'port'} = $srv->{'port'};
		$c->stash->{'cutdelim'} = ($srv->{'use_fqdn'}) ? 0 : 1;
	}

	# En- or disable LDAP?
	if($use_ldap eq "1") {
		$c->stash->{'use_ldap'} = "0";
	} else {
		$c->stash->{'ldap_username'} = "admin";
		$c->stash->{'ldap_filter'} = '(|(othermailbox=smtp$*)(othermailbox=smtp:*)(proxyaddresses=smtp$*)(proxyaddresses=smtp:*)(mail=*)(userPrincipalName=*))';
		$c->stash->{'ldap_properties'} = "proxyAddresses";
		$c->stash->{'use_ldap'} = "1";
	}

	aslog "info", "Toggled LDAP usage (was before: $use_ldap)";
	$c->stash->{template} = 'admin/mail_transfer/smtp_servers.tt2';
	$c->stash->{'show_details'} = "1";
	update_stash($self, $c);
}


1;

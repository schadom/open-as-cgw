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


package LimesGUI::Controller::Admin::Mail_Transfer::Smtp_Settings;

use base 'LimesGUI::Controller';
use namespace::autoclean;
use strict;
use warnings;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Utils;
use Underground8::Log;


sub client_config_params {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $params;
	$params->{'sender_domain_verify'} = $appliance->antispam->sender_domain_verify();
	$params->{'sender_fqdn_required'} = $appliance->antispam->sender_fqdn_required();
	$params->{'helo_required'} = $appliance->antispam->helo_required();
	$params->{'rfc_strict'} = $appliance->antispam->rfc_strict();

	$c->stash->{'client_params'} = $params;
}


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$self->client_config_params($c);
	$c->stash->{'antispam'} = $appliance->antispam;
	$c->stash->{template} = 'admin/mail_transfer/smtp_settings.tt2';
}


sub client : Local {
	my ( $self, $c, $setting ) = @_;
	my $appliance = $c->config->{'appliance'};

	if ($setting eq 'sender_domain_verify') {
		$appliance->antispam->sender_domain_verify() ? 
			$appliance->antispam->disable_sender_domain_verify() :
			$appliance->antispam->enable_sender_domain_verify();
	} elsif ($setting eq 'sender_fqdn_required') {
		$appliance->antispam->sender_fqdn_required() ? 
			$appliance->antispam->disable_sender_fqdn_required() :
			$appliance->antispam->enable_sender_fqdn_required();
	} elsif ($setting eq 'helo_required') {
		$appliance->antispam->helo_required() ? 
			$appliance->antispam->disable_helo_required() :
			$appliance->antispam->enable_helo_required();
	} elsif ($setting eq 'rfc_strict') {
		$appliance->antispam->rfc_strict() ? 
			$appliance->antispam->disable_rfc_strict() :
			$appliance->antispam->enable_rfc_strict();
	} else {
		aslog "warn", "Error setting SMTP setting $setting";
		$c->stash->{'box_status'}->{'custom_error'} = $c->localize('mail_transfer_smtp_settings_client_error');
	}
	
	try {
		$appliance->antispam->commit();
		aslog "info", "Set SMTP setting $setting";
		$c->stash->{'box_status'}->{'custom_success'} = $c->localize('mail_transfer_smtp_settings_client_success');
	}	catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error setting SMTP setting $setting";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$self->client_config_params($c);
	$c->stash->{template} = 'admin/mail_transfer/smtp_settings/client.inc.tt2';
}



sub server : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
 
	my $form_profile = {
		required => [qw(
			smtpd_banner
			max_connections
			smtpd_timeout
			smtpd_queuetime
		)],
		constraint_methods =>  {
			smtpd_banner => qr/^.+$/,
			max_connections => qr/^\d{1,3}$/,
			smtpd_timeout => qr/^[1-9]\d{0,2}$/,
			smtpd_queuetime => qr/^[1-9]\d{0,1}$/,
		}
	};

	my $result = $self->process_form($c, $form_profile);
 
	$c->stash->{'template'} = 'admin/mail_transfer/smtp_settings/server.inc.tt2'; 

	if ($result->success()) {
		try {
			my $smtpd_banner = $c->request->params->{'smtpd_banner'};
			my $max_connections = $c->request->params->{'max_connections'};
			my $smtpd_timeout = $c->request->params->{'smtpd_timeout'};
			my $smtpd_queuetime = $c->request->params->{'smtpd_queuetime'};

			# set the value
			$appliance->antispam->set_smtpd_banner($smtpd_banner);
			$appliance->antispam->set_max_incoming_connections($max_connections);
			$appliance->antispam->set_smtpd_timeout($smtpd_timeout);
			$appliance->antispam->set_smtpd_queuetime($smtpd_queuetime);

			# commit
			$appliance->antispam->commit;
			aslog "info", "Set SMTP server settings";
			$c->stash->{'box_status'}->{'success'} = 'updated';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting SMTP server settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	
	$c->stash->{'antispam'} = $appliance->antispam;
}


# ***************** O L D   C O D E ******************

sub add_pem : Local
{
	my ( $self, $c ) = @_;
	my ($upload, $filename, $target);

	my $appliance = $c->config->{'appliance'};
	my $expand = "";

	$c->stash->{'template'} = 'admin/mail_transfer/smtp_settings/ssl.inc.tt2';

	my $form_profile = {
		required => [qw(pem_file)],
		constraint_methods => {
			pem_file => qr/\.(crt|key|pem)$/i
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if ($result->success())
	{
		try
		{
			my $cert = "";
			my $pkey = "";
			my $tmp_cert = "";
			my $tmp_pkey = "";
			my $upload = $c->request->upload('pem_file');
			if ($upload)
			{
				if ($upload->size < 8000)
				{
					$cert = $upload->tempname;
					$pkey = $cert;

					$tmp_cert = "/tmp/" . getpgrp( 0 ) . "_cert";
					$tmp_pkey = "/tmp/" . getpgrp( 0 ) . "_pkey";

					# we create a file that contain only the certificate part so that we check if it is ok
					safe_system("$g->{cmd_sed} -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' '$cert' > '$tmp_cert'");
					if (-z $tmp_cert)
					{
						$cert = "";
						unlink ($tmp_cert);
					}

					# we create a file that contain only the private key part so that we check if it is ok
					safe_system("$g->{cmd_sed} -n '/-----BEGIN RSA PRIVATE KEY-----/,/-----END RSA PRIVATE KEY-----/p' '$pkey' > '$tmp_pkey'");
					if (-z $tmp_pkey)
					{
						$pkey = "";
						unlink ($tmp_pkey);
					}
				} 
				else
				{
					$c->stash->{'box_status'}->{'custom_error'} = $c->localize('status_cert_exceded_size');
					unlink ($upload->tempname);
				}
			}

			# set the values
			if ($cert || $pkey)
			{
				$appliance->antispam->assign_cert($tmp_cert) if $cert;
				$appliance->antispam->assign_pkey($tmp_pkey) if $pkey;
				$appliance->antispam->commit();
			}

			if (($cert && $appliance->antispam->postfix_ssl_certificate_present)
				||
				($pkey && $appliance->antispam->postfix_ssl_privatekey_present)
				)
			{
				$c->stash->{'box_status'}->{'custom_success'} = $c->localize('status_cert_assigned');
			} 
			else 
			{
				$c->stash->{'box_status'}->{'custom_error'} = $c->localize('status_cert_invalid');
			}
		}
		catch Underground8::Exception::CertificateInvalid with
		{
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize('status_cert_invalid');
		}
		catch Underground8::Exception::NoMatchCertificatePrivatekey with
		{
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize('status_no_match_cert_pkey');
		}
		catch Underground8::Exception with
		{
			my $E = shift;
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'antispam'} = $appliance->antispam;
}



 
sub del_certificate : Local
{
	my ($self, $c, $helo_required) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'template'} = 'admin/mail_transfer/smtp_settings/ssl.inc.tt2';
	try
	{
		$appliance->antispam->delete_cert();
		$appliance->antispam->commit;
		$c->stash->{'status'}->{'message'} = $c->localize('status_cert_unassigned');
	}
	catch Underground8::Exception with
	{
		my $E = shift;
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{'antispam'} = $appliance->antispam;
}



sub del_privatekey : Local {
	my $self = shift;
	my $c = shift;
	my $helo_required = shift;

	my $appliance = $c->config->{'appliance'};
	
	$c->stash->{'template'} = 'admin/antispam/smtp/ssl.inc.tt2';
	try {
		$appliance->antispam->delete_pkey();
	$appliance->antispam->commit;
	$c->stash->{'status'}->{'message'} = $c->localize('status_cert_unassigned');
	}
	catch Underground8::Exception with
	{
		my $E = shift;
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};
	$c->stash->{'antispam'} = $appliance->antispam;
	$c->stash->{'showbox'}->{'smtp_ssl'} = 'show';
}

1;

=cut
package LimesGUI::Controller::Admin::Antispam::Smtp;

use strict;
use warnings;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Underground8::Exception;
use Underground8::Utils;


	
=cut 

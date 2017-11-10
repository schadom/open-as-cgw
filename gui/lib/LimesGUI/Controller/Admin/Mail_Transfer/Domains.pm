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


package LimesGUI::Controller::Admin::Mail_Transfer::Domains;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::SMTPServerExists;
use Underground8::Exception::SMTPServerNotExists;
use Underground8::Exception::DomainExists;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Log;
use IO::File;



sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	$c->stash->{'relay_domains'} = $appliance->antispam->domain_read();
	$c->stash->{'relay_smtpsrvs'} = $appliance->antispam->smtpsrv_read();
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'relay_domains'} = $appliance->antispam->domain_read();
	$c->stash->{'relay_smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'no_wrapper'} = "1";
}

sub toggle_status : Local {
	my ( $self, $c, $domain, $operation ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		if($operation eq "disable") {
			$appliance->antispam->domain_disable($domain);
			$c->stash->{'box_status'}->{'success'} = 'disable_success';
		} else {
			$appliance->antispam->domain_enable($domain);
			$c->stash->{'box_status'}->{'success'} = 'enable_success';
		}

		$appliance->antispam->commit;
		aslog "info", "Toggled status of domain $domain, operation was $operation";
	} catch Underground8::Exception::DomainNotExists with {
		aslog "warn", "Error toggling domain status, domain <$domain> does not exist";
		$c->stash->{'box_status'}->{'custom_error'} = 'not_existent';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling domain status, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	update_stash($self, $c);
}

sub delete : Local {
	my ( $self, $c, $domain ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->antispam->domain_delete($domain);
		$appliance->antispam->commit;
		aslog "info", "Deleted domain $domain";
	} catch Underground8::Exception::DomainNotExists with {
		aslog "warn", "Error deleting domain <$domain>, domain doesn't exist";
		$c->stash->{'box_status'}->{'custom_error'} = 'delete_success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error deleting domain <$domain>, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};
	
	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	update_stash($self, $c);
}

# Edit existing domain
sub edit : Local {
	my ( $self, $c, $domain ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'domain_new'} = $domain;
	$c->stash->{'smtpsrv_preselect'} = $appliance->antispam->domain_read->{$domain}->{'dest_mailserver'};

	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	update_stash($self, $c);
}

# Save New or update existing domain stuff
sub save : Local {
	my ( $self, $c, $domain ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(domain address)],
		constraint_methods => {
			address => validate_smtp_srv(),
			domain => validate_domain(),
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if ($result->success()){
		try {

			my $given_domain = $c->req->params->{'domain'};
			my $smtpsrv = $c->req->params->{'address'};
			my $instant_enable = $c->req->params->{'instant_enable'} == "1" ? "yes" : "no";

			$domain eq "new" 
				? $appliance->antispam->domain_create($given_domain, $smtpsrv, $instant_enable)
				: $appliance->antispam->domain_update($given_domain, $smtpsrv);

			$appliance->antispam->commit;
			aslog "info", "Added/Updated domain $given_domain, handled by $smtpsrv (" . ($domain eq "new" ? "new" : "update") . ")";
			$c->stash->{'box_status'}->{'success'} = 'create_success';
		} catch Underground8::Exception::DomainExists with {
			aslog "warn", "Error saving domain setting, domain exists.";
			$c->stash->{'box_status'}->{'custom_error'} = 'create_error';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting domain settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}


	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	update_stash($self, $c);
}

sub reassign : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(smtpsrv_from smtpsrv_to)],
		constraint_methods => {
			smtpsrv_from => validate_smtp_srv(),
			smtpsrv_to => validate_smtp_srv(),
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $smtpsrv_from = $c->req->params->{'smtpsrv_from'};
			my $smtpsrv_to = $c->req->params->{'smtpsrv_to'};
	
			if($smtpsrv_from eq $smtpsrv_to) {
				aslog "warn", "Error reassigning SMTP servers, source = destination";
				$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_reassign_sameservers_error';
			} else {
				if($appliance->antispam->domains_bulk_assign($smtpsrv_from, $smtpsrv_to)){
					$appliance->antispam->commit;
					aslog "info", "Reassigned domains from $smtpsrv_from to $smtpsrv_to";
					$c->stash->{'box_status'}->{'success'} = 'success';
				} else {
					aslog "warn", "Error reassigning domains to different smtp server";
					$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_reassign_error';
				}
			}
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error reassigning domains, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{template} = 'admin/mail_transfer/domains.tt2';
	update_stash($self, $c);
}

sub multiple_add : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $limit = 1024000;

	my $form_profile = {
		required => [qw(smtpsrv)],
		optional => [qw(predelete csvfile)],
		constraint_methods => {
			smtpsrv => validate_smtp_srv(),
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		my $upload = $c->request->upload('csvfile');
		my $smtpsrv = $c->req->params->{'smtpsrv'};
		my $predelete = $c->req->params->{'predelete'};

		if($predelete && $predelete eq "yes") {
			my $pre_domains = $appliance->antispam->domain_read();
			foreach my $dom_tmp (keys(%$pre_domains)) {
				try {
					$appliance->antispam->domain_delete($dom_tmp);
				} catch Underground8::Exception with {
					my $E = shift;
					aslog "warn", "Error pre-deleting domains, caught exception $E";
					$c->session->{'exception'} = $E;
					$c->stash->{'redirect_url'} = $c->uri_for('/error');
					$c->stash->{'template'} = 'redirect.inc.tt2';
				};
			}
		}

		if($upload) {
			if($upload->size < $limit and $upload->filename =~ /(csv|CSV)$/ and $upload->size > 20) {
				my $fh = $upload->fh;
				my ($line, $list, $enabled, $domain) = (undef, undef, undef, undef); 
				my @part = undef;
				my $line_nr = 0;

				while ($line = <$fh>) {
					chomp $line;
					$line =~ s/\r$//;
					$line_nr++;

					if(length($line) > 0) {
						@part = split(/,/, $line);
						if(scalar @part == 1) {
							$domain = $part[0];
							$enabled = "yes";
						} elsif(scalar @part == 2){
							$domain = $part[0];

							if($part[1] =~ m/^(yes|1|on)$/) {
								$enabled = "yes" ;
							} elsif($part[1] =~ m/^(no|0|off)$/) {
								$enabled = "no";
							} else {
								$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_add_bulk_upload_error';
								aslog "warn", "Error uploading domain CSV file, second field invalid";
								unlink($upload);
								return;
							}
						} else {
							$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_add_bulk_upload_error';
							aslog "warn", "Error uploading domain CSV file, wrong line-format";
							unlink($upload);
							return;
						}

						if(!($domain =~ /^[a-z0-9][a-z0-9\-]*(\.[a-z0-9\-]+)*\.[a-z0-9\-]*[a-z0-9]$/i)) {
							$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_add_bulk_upload_error';
							aslog "warn", "Error uploading domain CSV file, no regex match";
							unlink($upload);
							return;
						}

						$list->{$domain} = $enabled;
					}
				}

				foreach my $domain (keys %$list) {
					try {
						if(!$appliance->antispam->domain_exists($domain)) {
							$appliance->antispam->domain_create($domain, $smtpsrv, $list->{$domain});
							aslog "debug", "Created domain $domain for server $smtpsrv";
						}
					} catch Underground8::Exception with {
						my $E = shift;
						aslog "warn", "Error adding domain, caught exception $E";
						$c->session->{'exception'} = $E;
						$c->stash->{'redirect_url'} = $c->uri_for('/error');
						$c->stash->{'template'} = 'redirect.inc.tt2';
					};
				}

				try {
					$appliance->antispam->commit;
					aslog "info", "CSV multi domain-add successful";
				} catch Underground8::Exception with {
					my $E = shift;
					aslog "warn", "CSV multi-domain-add failed, caught exception $E";
					$c->session->{'exception'} = $E;
					$c->stash->{'redirect_url'} = $c->uri_for('/error');
					$c->stash->{'template'} = 'redirect.inc.tt2';
				};

				$c->stash->{'box_status'}->{'success'} = 'success';
			} else {
				# upload bigger than allowed
				$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_add_bulk_toobig_error';
				aslog "warn", "Error uploading CSV domain file, filesize too big";
			}

			unlink($upload);
		} else {
				$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_domains_multiple_add_nofile';
		}
	}

	$c->stash->{'relay_domains'} = $appliance->antispam->domain_read();
	$c->stash->{'relay_smtpsrvs'} = $appliance->antispam->smtpsrv_read();
	$c->stash->{'template'} = 'admin/mail_transfer/domains.tt2';
}


1;

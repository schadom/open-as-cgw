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


package LimesGUI::Controller::Admin::Mail_Transfer::Recipients;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Log;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use IO::File;
use Data::Dumper;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/mail_transfer/recipients.tt2';
	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	
	$c->stash->{'relay_domains'} = $appliance->antispam->domain_read();
}

sub error {
	my ( $c, $E ) = @_;
	aslog "warn", "Caught exception $E";
	$c->session->{'exception'} = $E;
	$c->stash->{'redirect_url'} = $c->uri_for('/error');
	$c->stash->{'template'} = 'redirect.inc.tt2';
}


sub update_ldapcache : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$c->stash->{'ldap_response'} = $appliance->antispam->create_ldap_maps;
		$appliance->antispam->commit("override_ldap");
		aslog "info", "Updated LDAP cache";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception with {
		aslog "warn", "Error updaing LDAP cache";
		error($c, shift);
	};

	$c->stash->{'template'} = 'admin/mail_transfer/recipients/ldap_cache.inc.tt2';
	update_stash($self, $c);
}

sub show_recipients : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(domain)],
		optional => [qw(showcache)],
		constraint_methods => {
			domain => validate_domain(),
			showcache => qr/^1$/,
		}
	};

	update_stash($self, $c);

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		my $domain = $c->req->params->{'domain'};
		my $ldap = $c->req->params->{'showcache'} ? "1" : "0";


		my $usermaps = $ldap
			? $appliance->antispam->usermaps($domain, $ldap)
			: $appliance->antispam->usermaps($domain);

		$c->stash->{'usermaps'} = (defined $usermaps) ? $usermaps : 'UNDEF';

		$c->stash->{'current_domain'} = $domain;
		aslog "debug", "Showing recipients of $domain (ldap = $ldap)";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} else {
		aslog "debug", "No recipients to show, usermap empty";
		$c->stash->{'usermaps'} = ();
		$c->stash->{'domain'} = "none";
	}

	$c->stash->{'template'} = 'admin/mail_transfer/recipients.tt2';
	$c->stash->{'no_wrapper'} = "1";
}


sub add_bulk : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $limit = 1024000;

	$c->stash->{'template'} = 'admin/mail_transfer/recipients.tt2';

	my $form_profile = {
		required => [qw(csvfile)],
		optional => [qw(predelete)],
		constraint_methods => {
			predelete => qr/yes/,
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()) {
		my $upload = $c->req->upload('csvfile');

		# No file uploaded
		unless($upload){
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_nofile';
			aslog "warn", "Could not find uploaded file";
			return;
		}

		# File too big
		unless($upload->size < $limit) {
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_filetoobig';
			aslog "warn", "Filesize of uploaded CSV file too big";
			return;
		}

		unless($upload->filename =~ /(csv|CSV)$/) {
			$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_nocsv';
			aslog "warn", "Filesize of uploaded CSV file too big";
			return;
		}

		my ($line, $list, $accept, $whole_address, $domain, $address, @part);
		my $fh = $upload->fh;
		my $line_nr = 0;

		while($line = <$fh>){
			chomp $line;
			$line =~ s/\r$//;
			$line_nr++;

			if(length($line) > 0) {
				@part = split(/,/, $line);
				
				if(scalar @part == 1) {
					$whole_address = $part[0];
					$accept = "1";
				} elsif(scalar @part == 2) {
					$whole_address = $part[0];
					if($part[1] =~ m/^(yes|1|on)$/) {
						$accept = "1";
					} elsif($part[1] =~ m/^(no|0|off)$/) {
						$accept = "0";
					} else {
						$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_parseline';
						aslog "warn", "CSV: Line parsing error";
						unlink $upload;
						return;
					}
				} else {
					$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_parseline';
					aslog "warn", "CSV: Line parsing error";
					unlink $upload;
					return;
				}

				if($whole_address =~ m/^(.+?)\@([a-z0-9][a-z0-9\-]*(\.[a-z0-9\-]+)*\.[a-z0-9\-]*[a-z0-9])$/i) {
					($address, $domain) = ($1, $2);
				} else {
					$c->stash->{'box_status'}->{'custom_error'} = 'mail_transfer_recipients_bulk_add_error_parseline';
					aslog "warn", "CSV: Line parsing error";
					unlink $upload;
					return;
				}

				if($appliance->antispam->domain_exists($domain)) {
					$list->{$domain}{$address}{'accept'} = $accept;
				}
			}
		}
		unlink $upload;

		foreach my $domain (keys %$list) {
			if($c->req->params->{'predelete'}) {
				$appliance->antispam->usermaps_delete_domain($domain) if $c->req->params->{'predelete'} eq "yes";
			}

			foreach my $address (keys %{$list->{$domain}}){
				try {
					$appliance->antispam->usermaps_update_addr($domain, $address, $list->{$domain}{$address}{'accept'});
					aslog "debug", "Successfully added $address for domain $domain";
				} catch Underground8::Exception with {
					aslog "warn", "Error adding e-mail address";
					error($c, shift);
				};
			}
		}

		try {
			$appliance->antispam->commit();
			aslog "info", "Parsed and added recipient CSV file";
		} catch Underground8::Exception with {
			aslog "warn", "Error adding recipient CSV file";
			error($c, shift);
		};

		update_stash($self, $c);
	}
}


sub add : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(domain user)],
		optional => [qw(accept)],
		constraint_methods => {
			domain => validate_domain(),
			user => qr/^[a-zA-Z0-9_\+-\.]+$/,
			accept => qr/^1$/,
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()) {
		try {
			my $domain = $c->req->params->{'domain'};
			my $user = $c->req->params->{'user'};
			my $accept = $c->req->params->{'accept'} ? '1' : '0';

			$appliance->antispam->usermaps_update_addr($domain, $user, $accept);
			$appliance->antispam->commit;
			
			aslog "info", "Added recipient $user for domain $domain";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error adding recipient, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	update_stash($self, $c);
	$c->stash->{'template'} = 'admin/mail_transfer/recipients/add.inc.tt2';
}

sub delete : Local {
	my ($self, $c, $user, $domain) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		($user)
			? $appliance->antispam->usermaps_delete_addr($domain, $user)
			: $appliance->antispam->usermaps_delete_domain($domain);

		my $ldap = $c->req->param('showcache');
		$c->stash->{'usermaps'} = $ldap
			? $appliance->antispam->usermaps($domain, $ldap)
			: $appliance->antispam->usermaps($domain);

		$appliance->antispam->commit;
		aslog "info", "Deleted recipient $user for domain $domain";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception with {
		aslog "warn", "Error deleting recipient $user for domain $domain";
		error($c, shift);
	};

	update_stash($self, $c);
	#$c->stash->{'template'} = 'admin/mail_transfer/recipients/list.inc.tt2';
	$c->stash->{'template'} = 'admin/mail_transfer/recipients.tt2';
	$c->stash->{'no_wrapper'} = '1';
	$c->stash->{'current_domain'} = $domain;
}


1;

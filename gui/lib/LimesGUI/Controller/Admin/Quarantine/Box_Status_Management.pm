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


package LimesGUI::Controller::Admin::Quarantine::Box_Status_Management;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Log;

# It looks dirty, but it's actually really elegant. Think about it.
my ($filter_domain, $filter_status);

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/quarantine/box_status_management.tt2';
	$c->stash->{'domains'} = $appliance->antispam->domain_read();
}

sub update_stash {
	my ($self, $c) = @_;
	$appliance = $c->config->{'appliance'};

	$c->stash->{'q_state'} = $appliance->quarantine->quarantine_state();
	$c->stash->{'no_wrapper'} = "1";
	$c->stash->{'settings'} = $appliance->quarantine->quarantineNG();
	$c->stash->{'domains'} = $appliance->antispam->domain_read();
	$c->stash->{'filter_domain'} = $filter_domain;
	$c->stash->{'filter_status'} = $filter_status;
	if($c->stash->{'q_state'} == 1) {
		$c->stash->{'emails_list'} = $appliance->quarantine->recipients_list($appliance->antispam->domain_read());
	}
}

# Called by GUI, sets $filter_domain and $filter_status
sub change_filter : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $domain = $c->req->param('domain_filter');
	my $boxstatus = $c->req->param('box_status');
	($filter_domain, $filter_status) = ($domain, $boxstatus);

	update_filter($self, $c);
	update_stash($self, $c);
	aslog "debug", "Changed Q:BSM filter to $filter_domain (status: $filter_status)";
}

# Called by all other subs to re-build address list
sub update_filter {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $emails;
	my @filtered;

	my ($domain, $boxstatus) = ($filter_domain, $filter_status);

	try {
		$emails = ($domain eq "all")
			? $appliance->quarantine->recipients_list($appliance->antispam->domain_read())
			: $appliance->quarantine->recipients_list_by_domain($domain);

		# Filter type: QON | QOFF
		if($boxstatus eq 1 || $boxstatus eq 2){
			foreach my $email (@$emails){
				push (@filtered, $email) if (defined $email->{'decision'} and $email->{'decision'}==$boxstatus );
			}
			$emails = \@filtered;
		} elsif($boxstatus ne "all"){
			foreach my $mess (@$emails){
				push (@filtered, $mess) if $mess->{'quarantiny'} == 0;
			}
			$emails = \@filtered;
		}

		if (scalar(@filtered) > 0) {
			$c->stash->{'box_status'}->{'success'} = 'success';
		} else {
			$c->stash->{'box_status'}->{'custom_error'} = 'quarantine_box_status_management_filter_empty';
		}

		aslog "info", "Updated Q:BSM filter for $domain";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error updating Q:BSM filter for $domain";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{'recipient_list'} = $emails;
	$c->stash->{template} = 'admin/quarantine/box_status_management.tt2';
}

sub reset : Local {
	my ($self, $c, $email) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->quarantine->reset_counters($email);
		aslog "info", "Reset Q:BSM e-mail counters";
		$c->stash->{'box_status'}->{'success'} = 'reset_success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error resetting Q:BSM e-mail counters";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_filter($self, $c);
	update_stash($self, $c);
}

sub notify : Local {
	my ($self, $c, $email) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->quarantine->notify_recipient($email);
		aslog "info", "Sending Q:BSM notification to $email";
		$c->stash->{'box_status'}->{'success'} = 'notify_success';

		my  ($user, $domain) = split /\@/, $email;
		$c->stash->{'re_user'} = $user;
		$c->stash->{'re_domain'} = $domain;
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error sending Q:BSM notification to $email";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_filter($self, $c);
	update_stash($self, $c);
}

sub enable : Local {
	my ($self, $c, $email) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->quarantine->toggle_quarantine_recipient(1, $email);
		$appliance->quarantine->commit;
		aslog "info", "Enabling Q:BSM quarantine for $email";

		my  ($user, $domain) = split /\@/, $email;
		$c->stash->{'re_user'} = $user;
		$c->stash->{'re_domain'} = $domain;
		$c->stash->{'box_status'}->{'custom_success'} = 'enable_success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error enabling Q:BSM quarantine for $email, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_filter($self, $c);
	update_stash($self, $c);
}

sub disable : Local {
	my ($self, $c, $email) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->quarantine->toggle_quarantine_recipient(0, $email);
		$appliance->quarantine->commit;
		aslog "info", "Disabling Q:BSM quarantine for $email";

		my  ($user, $domain) = split /\@/, $email;
		$c->stash->{'re_user'} = $user;
		$c->stash->{'re_domain'} = $domain;
		$c->stash->{'box_status'}->{'custom_success'} = 'enable_success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error disabling Q:BSM quarantine for $email, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_filter($self, $c);
	update_stash($self, $c);
}

1;

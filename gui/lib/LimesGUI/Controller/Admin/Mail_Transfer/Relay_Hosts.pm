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


package LimesGUI::Controller::Admin::Mail_Transfer::Relay_Hosts;

use base 'LimesGUI::Controller';
use strict;
use warnings;
use namespace::autoclean;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Exception;
use Underground8::Exception::EntryExistsIn;
use Underground8::Log;
use Data::Dumper;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->log->debug(Dumper $appliance->antispam->get_ip_range_whitelist());
	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam;
	$c->stash->{template} = 'admin/mail_transfer/relay_hosts.tt2';
}


sub enlist : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(range_start range_end)],
		optional => [qw(description)],
		constraint_methods => {
		range_start => FV_net_IPv4(),
		range_end => FV_net_IPv4(),
		description => qr/\w{1,30}$/
		}
	};
	
	my $result = $self->process_form($c, $form_profile);
	
	$c->stash->{'no_wrapper'} = 'yes';
	$c->stash->{'template'} = 'admin/mail_transfer/relay_hosts.tt2';

	if ($result->success()) {
		try {
			my $range_start = $c->request->params->{'range_start'};
			my $range_end = $c->request->params->{'range_end'};
			my $description = $c->request->params->{'description'};

			$appliance->antispam->add_ip_range_whitelist($range_start, $range_end, $description);
			$appliance->antispam->commit();

			aslog "info", "Addeded relay host range $description [$range_start -> $range_end]";
			$c->stash->{'box_status'}->{'success'} = 'added';
		} catch Underground8::Exception::TooBigRange with {
			aslog "warn", "Error adding relay host range: range too bid";
			$c->stash->{'box_status'}->{'custom_error'} = 'too_big_range';
		} catch Underground8::Exception::FalseRange with {
			aslog "warn", "Error adding relay host range: Range Invalid";
			$c->stash->{'box_status'}->{'custom_error'} = 'false_range';
		} catch Underground8::Exception::EntryExists with {
			aslog "warn", "Error adding relay host range: Entry exists";
			$c->stash->{'box_status'}->{'custom_error'} = 'entry_exists';
		} catch Underground8::Exception::EntryExistsIn with {
			my $E = shift;
			aslog "warn", "Error adding relay host range: Entry exists (caught exception $E)";
			$c->stash->{'box_status'}->{'custom_error'} = 'entry_exists';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error adding relay host range: Caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	$c->stash->{'antispam'} = $appliance->antispam;
}


sub delist : Local {
	my ($self, $c, $start) = @_;
	my $appliance = $c->config->{'appliance'};
   
	$c->stash->{'no_wrapper'} = 'yes';
#	$c->stash->{'bind_infobar'} = 'mail_transfer_relay_hosts_table';
	$c->stash->{'template'} = 'admin/mail_transfer/relay_hosts.tt2';

	if (defined $start && length $start) {
		try {
			$appliance->antispam->del_ip_range_whitelist($start);
			$appliance->antispam->commit();

			aslog "info", "Deleted relay host range $start";
			$c->stash->{'box_status'}->{'success'} = 'deleted';
		} catch Underground8::Exception::EntryNotExists with {
			aslog "warn", "Error deleting relay host range $start";
			$c->stash->{'box_status'}->{'custom_error'} = 'entry_not_exists';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error deleting relay host range $start, caught Exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	$c->stash->{'antispam'} = $appliance->antispam;
}


1;


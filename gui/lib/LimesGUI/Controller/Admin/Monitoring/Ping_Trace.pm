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


package LimesGUI::Controller::Admin::Monitoring::Ping_Trace;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Log;

sub index : Private {
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    $c->stash->{template} = 'admin/monitoring/ping_trace.tt2';
}


sub ping : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{template} = 'admin/monitoring/ping_trace/ping.inc.tt2';

	my $form_profile = {
		required => [qw(hostname)],
		constraint_methods => {
			hostname => $self->FV_domain_or_net_IPv4()
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {
		try {
			my $ping_host = $c->request->params->{'hostname'};

			# Perform ping
			my ($time,$loss,$ip) = $appliance->report->ping_host($ping_host, 1);

			my $status_msg = ($time != -1)
				? $ping_host . sprintf($c->localize('monitoring_ping_trace_ping_success_text'), $ip, $time, $loss)
				: $ping_host . $c->localize('monitoring_ping_trace_ping_failure');

			# Show result
			($time != -1)
				? $c->stash->{'box_status'}->{'custom_success'} = $status_msg
				: $c->stash->{'box_status'}->{'custom_error'} = $status_msg;

			aslog "info", ($time!=-1 ? "Ping to host $ping_host successful" : "Ping to host $ping_host did not succeed");
		}

		catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error pinging host, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
}

sub trace : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{template} = 'admin/monitoring/ping_trace/trace.inc.tt2';


	my $form_profile = {
		required => [qw(hostname)],
		constraint_methods => {
			hostname => $self->FV_domain_or_net_IPv4()
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {
		try {
			my $trace_host = $c->request->params->{'hostname'};
			my $noreverselookup = ($c->request->params->{'noreverselookup'}) ? 0 : 1;
			my $trace_result = $appliance->report->trace_host($trace_host, $noreverselookup);

			if ($trace_result == 0) {
				$c->stash->{'box_status'}->{'custom_error'} = $c->localize('monitoring_ping_trace_trace_error');
				aslog "info", "Could not trace back host $trace_host";
			} else {
				$c->stash->{'box_status'}->{'success'} = "success";
				aslog "info", "Tracing back host $trace_host succeeded";
				$c->stash->{'trace_data'} = $trace_result;
			}
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error tracing back host, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'system'} = $appliance->system;
}

1

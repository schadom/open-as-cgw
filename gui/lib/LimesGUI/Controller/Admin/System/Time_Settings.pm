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


package LimesGUI::Controller::Admin::System::Time_Settings;

use base LimesGUI::Controller;
use namespace::autoclean;
use Error qw(:try);
use strict;
use warnings;
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $system = $appliance->system;

	$c->stash->{'system'} = $system;
	$c->stash->{'timeservers'} = $appliance->system->time_servers;
	$c->stash->{template} = 'admin/system/time_settings.tt2';
}


sub timezone : Local {
	my $self = shift;
	my $c = shift;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(timezone)],
		constraint_methods => {
		timezone => qr/\w+?\/\w+?/,
		},
	};

	my $result = $self->process_form($c,$form_profile);

	$c->stash->{'template'} = 'admin/system/time_settings/timezone.inc.tt2';

	if ($result->success()) {   
		try {
			my $timezone = $c->request->params->{'timezone'};
			$appliance->system->set_tz($timezone);
			$appliance->system->commit;

			# we need to restart postfix because it copies the timezone for itself
			$appliance->antispam->postfix->slave->service_restart();   
			$self->set_status_msg($c, 'status_updated');
			aslog "info", "Timezone has been set to $timezone";
		} catch Underground8::Exception with {   
			my $E = shift;
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'system'} = $appliance->system;
}


sub ntp : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $constraint_methods = {};
	my $optional = ();
	my $num_ntp_servers = 0;

	foreach my $key ( keys(%{$c->request->params}) ) {
		$num_ntp_servers++ if $key =~ /^server\d+$/i;
	}
	
	foreach my $key ( keys(%{$c->request->params}) ) {
		$constraint_methods->{$key}->{'constraint_method'} = $self->FV_domain_or_net_IPv4();
		$constraint_methods->{$key}->{'params'}[0] = $key;
		push(@{$optional}, $key) if( $num_ntp_servers > 1 );
	}

	my $form_profile = {
		required => ($num_ntp_servers <= 1) ? [qw( server1 )] : [],
		optional => $optional,
		constraint_methods => $constraint_methods,
		missing_optional_valid => 1,
	};

	$c->stash->{'template'} = 'admin/system/time_settings/ntp.inc.tt2';
	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {   
		try {
			my %ntp_hash;
			my $j = 0;

			for (my $i = 1; $i <= (scalar keys(%{$c->request->params}))-1; $i++ ) {   
				my $tmp = "server" . $i;
				if ( $c->request->params->{$tmp} && ! $ntp_hash{ $c->request->params->{$tmp} } ) {   
					my $change = $c->request->params->{$tmp};
					$appliance->system->change_ntp_server(($i-1-$j),$change);
					$ntp_hash{ $change } = 1;
				} else {   
					$appliance->system->del_ntp_server(($i-1-$j));
					$j++;
					aslog "info", "Deleted NTP server " . ($i-1-$j);
				}
			}

			if ( $c->request->params->{'addserver'} ) {
				if ( ! $ntp_hash{ $c->request->params->{'addserver'} } ) {   
					my $add = $c->request->params->{'addserver'};
					$appliance->system->add_ntp_server($add);
					aslog "info", "Added NTP server $add";
				} else {
					push @{$c->stash->{'status'}->{'errors'}}, $c->localize('error_ntp_exists');
				}
			}   

			# commit
			$appliance->system->commit;
			$c->stash->{'box_status'}->{'success'} = 'status_set';

		} catch Underground8::Exception with {   
			my $E = shift;
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	$c->stash->{'system'} = $appliance->system;
}

1;

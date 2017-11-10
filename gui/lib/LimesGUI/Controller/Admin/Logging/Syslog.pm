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


package LimesGUI::Controller::Admin::Logging::Syslog;

#use Moose;
use namespace::autoclean;
#BEGIN { extends 'LimesGUI::Controller'; };
use base 'LimesGUI::Controller';
#use strict;
#use warnings;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Log;
use Underground8::Exception;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'syslog'} = $appliance->system->syslog;
	$c->stash->{template} = 'admin/logging/syslog.tt2';
}


sub set_syslog : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(host port proto)],
		optional => [qw(enabled)],
		constraint_methods => {
			host => qr/^[a-zA-Z0-9\.-]{1,128}$/,
			port => qr/^\d+$/,
			proto => qr/(udp|tcp)/,
		}
	};

	# $c->stash->{template} = 'admin/logging/syslog/remote.inc.tt2';
	$c->stash->{template} = 'admin/logging/syslog.tt2';
	$c->stash->{'no_wrapper'} = "1";

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my ($host, $port, $proto, $enabled) = 
				($c->req->param('host'), $c->req->param('port'), $c->req->param('proto'), $c->req->param('enabled'));

			if(defined($host) and defined($port) and defined($proto)) {
				$appliance->system->syslog->host($host);
				$appliance->system->syslog->port($port);
				$appliance->system->syslog->proto($proto);

				($enabled eq "enabled")
					? $appliance->system->syslog->enabled(1)
					: $appliance->system->syslog->enabled(0);

				$appliance->system->commit();

				aslog "info", "Enabled external syslog server: $host:$port via $proto";
				$c->stash->{'box_status'}->{'success'} = 'success';
			} else {
				$c->stash->{'box_status'}->{'error'} = 'lol';
				$c->stash->{'syslog'} = $appliance->system->syslog;
				#$c->stash->{template} = 'admin/logging/syslog/remote.inc.tt2';
				$c->stash->{template} = 'admin/logging/syslog.tt2';
				$c->stash->{'no_wrapper'} = "1";
				return;
			}
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting external syslog server, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'syslog'} = $appliance->system->syslog;
	$c->stash->{'infobar'} = "1";
}

1;

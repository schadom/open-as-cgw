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


package LimesGUI::Controller::Admin::Logging::Live_Log;

use namespace::autoclean;
use base 'LimesGUI::Controller';


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/logging/live_log.tt2';
}


sub update : Local {
	my ($self, $c, $limit) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'mails'} = $appliance->report->mail->livelog($limit)->mails;
	$c->stash->{'template'} = 'admin/logging/live_log/livelog.inc.tt2';
}

1;

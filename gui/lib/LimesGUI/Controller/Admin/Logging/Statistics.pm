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


package LimesGUI::Controller::Admin::Logging::Statistics;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use DateTime;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};


	my $stats_24h = $appliance->report->mail->mail_last24h->chart_data;
	my $stats_week = $appliance->report->mail->mail_lastweek->chart_data;
	my $stats_month = $appliance->report->mail->mail_lastmonth->chart_data;
	my $stats_year = $appliance->report->mail->mail_lastyear->chart_data;

	
	# This is the xml we start with ... could be changed to something else than 24h
	$self->write_statistics_xml($c, "entire_traffic", $stats_24h);

	# All the other stat files
	$self->write_statistics_xml($c, "entire_traffic_24h", $stats_24h);
	$self->write_statistics_xml($c, "entire_traffic_week", $stats_week);
	$self->write_statistics_xml($c, "entire_traffic_month", $stats_month);
	$self->write_statistics_xml($c, "entire_traffic_year", $stats_year);
	
 
	$c->stash->{'mail_types'} = $g->{'available_mail_types'};
	my $antispam = $appliance->antispam;

	$c->stash->{template} = 'admin/logging/statistics.tt2';
}

1;

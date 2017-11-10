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


package LimesGUI::Controller::Admin::Monitoring::Mail_Queue;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Underground8::Log;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $time = time;
	$time -= $time % 300;

	my $mailq_live = $appliance->report->mailqueue_live;
	my $mailq = $appliance->report->mailqueue;
	my $totals = $mailq->{'history'}->{$time}->[1];

	$c->stash->{'mailcount'} = $mailq->{'history'}->{$time}->[0];
	$c->stash->{'queuesize'} = $totals;
	$c->stash->{'mailqueue_live'} = $mailq_live;
	$c->stash->{template} = 'admin/monitoring/mail_queue.tt2';
}


sub stats : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $time = time;
	$time -= $time % 300;

	my $mailq = $appliance->report->mailqueue;
	my $mailq_live = $appliance->report->mailqueue_live;
	my $totals = $mailq->{'history'}->{$time}->[1];

	$appliance->mailq->purge();
	aslog "info", "Flushed MailQ";

	$c->stash->{'mailcount'} = $mailq->{'history'}->{$time}->[0];
	$c->stash->{'queuesize'} = $totals;
	$c->stash->{'mailqueue_live'} = $mailq_live;
	$c->stash->{'box_status'}->{'success'} = 'success';
	$c->stash->{template} = 'admin/monitoring/mail_queue/stats.inc.tt2';
}

1;

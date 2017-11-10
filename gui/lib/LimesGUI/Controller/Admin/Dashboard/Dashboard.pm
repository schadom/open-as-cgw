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


package LimesGUI::Controller::Admin::Dashboard::Dashboard;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Underground8::Utils;
use File::stat;
use File::Slurp;
use Data::Dumper;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $current_stats = $appliance->report->mail->current_stats->current_stats();
	my $sysinfo = $appliance->report->sysinfo();
	my $advanced_sysinfo = $appliance->report->advanced_sysinfo();
	
	$self->write_statistics_xml($c, "mail_traffic", $current_stats);

	$sysinfo->{'mem_used_percentage'} = sprintf "%.02f", $sysinfo->{'mem_used_percentage'};
	$sysinfo->{'mem_used_percentage'} =~ s/\./,/;
	$sysinfo->{'cpu_avg_1h'} = sprintf "%.02f", $sysinfo->{'cpu_avg_1h'};
	$sysinfo->{'cpu_avg_1h'} =~ s/\./,/;
	$sysinfo->{'loadavg_15'} = sprintf "%.02f", $sysinfo->{'loadavg_15'};
	$sysinfo->{'loadavg_15'} =~ s/\./,/;
	$sysinfo->{'uptime'} =~ s/^(.+?d .+?h .+?m).*$/$1/;
	$c->stash->{'sysinfo'} = $sysinfo;
	$c->stash->{'advanced_sysinfo'} = $advanced_sysinfo;
	$c->stash->{'versions'} = $appliance->report->versions;


	my @processarr = ('amavisd', 'clamd', 'master', 'mysqld', 'rtlogd', 'saslauthd');
	my $processes = $appliance->report->process_running(\@processarr);
	$c->stash->{'processes'} = $processes;


	$c->stash->{'current_stats'} = $current_stats;
	$c->stash->{'mail_types'} = $g->{'available_mail_types'};
	$c->stash->{template} = 'admin/dashboard/dashboard.tt2';

	# For notification stuff
	$c->config->{'no_smtpsrvs'} = (defined($appliance->antispam->smtpsrv_read()) && keys(%{ $appliance->antispam->smtpsrv_read() })) ? "0" : "1";
	$c->config->{'no_domains'} = ( defined($appliance->antispam->domain_read) && keys(%{ $appliance->antispam->domain_read })  ) ? "0" : "1";
	$c->config->{'high_mailq_level'}  = ( $appliance->report->mailqueue->{'history'}->{$time}->[0] > 500) ? "1" : "0";
	$c->config->{'update_running'} = $appliance->report->update_running();
	# $c->config->{'no_domains'}  = (keys(%{ $appliance->antispam->domain_read() })) ? "0" : "1";
}


1;

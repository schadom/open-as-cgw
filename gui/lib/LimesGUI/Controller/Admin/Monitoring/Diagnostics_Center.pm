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


package LimesGUI::Controller::Admin::Monitoring::Diagnostics_Center;

use namespace::autoclean;
use base 'LimesGUI::Controller';

use strict;
use Error qw(:try);
use Underground8::Log;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'report'} = $appliance->report->advanced_sysinfo();
	$c->stash->{template} = 'admin/monitoring/diagnostics_center.tt2';
}


sub start_diagnostics : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'result'} = "1";
	$c->stash->{template} = 'admin/monitoring/diagnostics_center/self_diagnostics.inc.tt2';

	my $fqdn =  $appliance->system->hostname . "." . $appliance->system->domainname;
	$c->stash->{'system'} = $appliance->system;

	# Network-related self-diagnostics
	$c->stash->{'pri_dns_reachable'} = 
		$appliance->report->test_dns_server( 'openas.org', $appliance->system->primary_dns );
	$c->stash->{'sec_dns_reachable'} = 
		$appliance->report->test_dns_server( 'openas.org', $appliance->system->secondary_dns );
	$c->stash->{'default_gw_reachable'} = 
		$appliance->report->ping_host( $appliance->system->default_gateway );

	# Perform self-lookup and self-reverse-lookup
	$c->stash->{'self_lookup'} = $appliance->report->test_dns_server(
		$fqdn, $appliance->system->primary_dns, $appliance->system->secondary_dns); 
	$c->stash->{'self_rlookup'} = $appliance->report->test_reverse_lookup(
		$fqdn, $appliance->system->primary_dns, $appliance->system->secondary_dns); 

	# Check availability of configured SMTP servers  
	my $smtpsrv_status = {};  
	my $smtpsrvs = $appliance->antispam->smtpsrv_read();
	while (my ($smtpsrv_name, $smtpsrv_value) = each(%$smtpsrvs)) {
		my $newkey = ($smtpsrv_value->{'descr'} eq "") ? $smtpsrv_value->{'addr'} : $smtpsrv_value->{'descr'};
		$smtpsrv_status->{ $newkey }
			= $appliance->report->check_smtpsrv_availability( $smtpsrv_value->{'addr'}, $smtpsrv_value->{'port'} );
	}
	$c->stash->{'smtpsrv_status'} = $smtpsrv_status;
	$c->stash->{'smtpsrvs'} = $smtpsrvs;

	# Check DNS + rDNS entries of MX records of configured domains
	my $domain_mx_checked = {}; 
	my $domains = $appliance->antispam->domain_read();
	while( my ($domain_name, $domain_value) = each(%$domains) ){
		$domain_mx_checked->{$domain_name}
		= $appliance->report->check_domain_mx_record($fqdn, $domain_name,
			$appliance->system->primary_dns,
			$appliance->system->secondary_dns);
	}

	$c->stash->{'domain_mx_checked'} = $domain_mx_checked;
	$c->stash->{'last_update_diff_secs'} = Underground8::Utils::time_diff( 0,
		date1 => $appliance->report->versions->{'last_update'}, 
		date2 =>  Underground8::Utils::get_localtime);

	aslog "info", "Performed self-diagnostics checkup";
}


1;

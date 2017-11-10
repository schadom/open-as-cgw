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


package LimesGUI::Controller::Admin::System::Remote_Assistance;

use Moose;
use namespace::autoclean;
use Underground8::Log;
use TryCatch;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Exception;

BEGIN 
{
	extends 'LimesGUI::Controller';
};


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/system/remote_assistance.tt2';
	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my ($snmp_community, $snmp_network, $snmp_location, $snmp_contact) = $appliance->system->snmp_configure();
	$c->stash->{'snmp_network'} = $snmp_network;
	$c->stash->{'snmp_community'} = $snmp_community;
	$c->stash->{'snmp_location'} = $snmp_location;
	$c->stash->{'snmp_contact'} = $snmp_contact;
	$c->stash->{'snmp_status'} = $appliance->system->snmp_status();

	$c->stash->{'system'} = $appliance->system;
}

sub configure_snmp : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(network community contact location)],
		constraints => {
			network => qr/^[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d(\/\d\d?)?$/,
			community => qr/^[a-zA-Z0-9]{4,20}$/,
			location => qr/^.{4,20}$/,
			contact => qr/^.{0,30}$/,
		},
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {

			# Get params
			my $enabled = $c->req->params->{'status'};
			my $network = $c->req->params->{'network'};
			my $community = $c->req->params->{'community'};
			my $contact = $c->req->params->{'contact'};
			my $location = $c->req->params->{'location'};

			# $appliance->system->save_config;
			aslog "info", "Toggled SNMP ";

			$appliance->system->snmp_configure($community, $network, $location, $contact);
			if($enabled eq 'yes'){
				$appliance->system->snmp_enable();
			} else {
				$appliance->system->snmp_disable();
			}

			$appliance->system->iptables->commit( $appliance->system->net_name );
			$appliance->system->commit;
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch (Underground8::Exception $E) {
			#my $E = shift;
			aslog "warn", "Error setting up snmp configuration, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{template} = 'admin/system/remote_assistance/snmp.inc.tt2';
	update_stash($self, $c);
}


sub configure_sshd : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $port = 22;


	# Get params
	my $enabled = $c->req->params->{'ssh'};

	# Just doit
	if ($enabled) {
		if($enabled eq 'yes') {
			$appliance->system->set_additional_ssh_port( $port );
		} else {
			$appliance->system->set_additional_ssh_port(0);
		}
	} else {
		$appliance->system->set_additional_ssh_port(0);
	}

	$appliance->system->iptables->commit( $appliance->system->net_name );
	$appliance->system->save_config;
	aslog "info", "Set SSH port 22 to be active: " . ($enabled eq "yes" ? "yes" : "no");

	$c->stash->{'box_status'}->{'success'} = 'status_set';

	$c->stash->{template} = 'admin/system/remote_assistance/ssh.inc.tt2';
	update_stash($self, $c);
}


1;

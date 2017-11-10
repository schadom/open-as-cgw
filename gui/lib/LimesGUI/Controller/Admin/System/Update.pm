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


package LimesGUI::Controller::Admin::System::Update;

use Moose;
use namespace::autoclean;
use Underground8::Log;

BEGIN 
{
	extends 'LimesGUI::Controller';
};


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'versions'} = $appliance->report->versions();

	# For up2date box
	$c->stash->{'update_settings_list'} = ["update", "download", "upgrade", "auto_newest"];
	$c->stash->{'update_settings_params'} = $appliance->system->updateservice_parameters();

	# For upgrade box
	$c->stash->{'new_sec_version'} = $appliance->report->new_sec_version_available;
	$c->stash->{'new_main_version'} = $appliance->report->new_main_version_available;

	$c->stash->{template} = 'admin/system/update.tt2';
}


# TODO: Exception handling
sub settings : Local {
	my ( $self, $c, $service ) = @_;
	my $appliance = $c->config->{'appliance'};


	if ($service =~ /^(update|upgrade|auto_newest|download)$/) {
		$appliance->system->toggle_updateservice_parameters($service);
		$appliance->system->commit();

		aslog "info", "Toggled update service parameter $service";
		$c->stash->{'box_status'}->{'success'} = 'automation_settings_configured';
	} else {
		$c->stash->{'box_status'}->{'custom_error'} = "Automation service unknown";
	}

	$c->stash->{'update_settings_list'} = ["update", "download", "upgrade", "auto_newest"];
	$c->stash->{'update_settings_params'} = $appliance->system->updateservice_parameters();

	$c->stash->{'system'} = $appliance->system;
	$c->stash->{template} = 'admin/system/update/settings.inc.tt2';

}

sub status : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'system'} = $appliance->system;
	$c->stash->{template} = 'admin/system/update/status.inc.tt2';
}

sub usus : Local {
	my ( $self, $c, $action, $params ) = @_;
	my $appliance = $c->config->{'appliance'};

	# Initiate update process
	if($action =~ /^(update|upgrade|install_new)$/){
		$appliance->system->initiate_usus($action, $params);
		aslog "info", "Initiated USUS for action $action, params $params";
	} 

	$c->stash->{'versions'} = $appliance->report->versions();
	$c->stash->{'update'} = $appliance->report->update();
	$c->stash->{template} = 'admin/system/update/versions.inc.tt2';
	$c->stash->{template} = 'admin/system/update/upgrade.inc.tt2' if $action eq "upgrade";
}


1;

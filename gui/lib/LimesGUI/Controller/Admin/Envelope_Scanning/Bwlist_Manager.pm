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


package LimesGUI::Controller::Admin::Envelope_Scanning::Bwlist_Manager;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'engine_status'} = $appliance->antispam->postfwd->get_status_bwman();
	$c->stash->{'config'} = $appliance->antispam->postfwd->load_config();
	$c->stash->{template} = 'admin/envelope_scanning/bwlist_manager.tt2';
}


sub toggle : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $engine_status = $appliance->antispam->postfwd->get_status_bwman();
	#$c->stash->{template} = 'admin/envelope_scanning/bwlist_manager/control.inc.tt2';
	$c->stash->{template} = 'admin/envelope_scanning/bwlist_manager.tt2';
	$c->stash->{'no_wrapper'} = "1";
	$c->stash->{'config'} = $appliance->antispam->postfwd->load_config();
	$c->stash->{'engine_status'} = $appliance->antispam->postfwd->get_status_bwman();

	try {
		if($engine_status eq "enabled") {
			$appliance->antispam->postfwd->disable_bwman();
			$c->stash->{'engine_status'} = "disabled";
			$c->stash->{'box_status'}->{'success'} = "disabled";
		} else {
			$appliance->antispam->postfwd->enable_bwman();
			$c->stash->{'engine_status'} = "enabled";
			$c->stash->{'box_status'}->{'success'} = "enabled";
		}

		$appliance->antispam->postfwd->commit;
		aslog "info", "Toggled BWlist status (was before: $engine_status)";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling BWlist status, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	}
}

sub enlist : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/envelope_scanning/bwlist_manager.tt2';
	$c->stash->{'no_wrapper'} = "1";
	$c->stash->{'bind_infobar'} = "envelope_scanning_bwlist_manager_control";
	$c->stash->{'config'} = $appliance->antispam->postfwd->load_config();
	$c->stash->{'engine_status'} = $appliance->antispam->postfwd->get_status_bwman();

	my $form_profile = {
		required => [qw(addnew_desc addnew_entry addnew_modality)],
		constraint_methods => {
			addnew_desc => qr/\w*/,
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $desc  = $c->req->params->{'addnew_desc'};
			my $entry = $c->req->params->{'addnew_entry'};
			my $list  = $c->req->params->{'addnew_modality'};

			if( $appliance->antispam->postfwd->add_entry($desc, $entry, $list) == 1) {
				$appliance->antispam->postfwd->commit;
				
				aslog "info", "Adding new BWlist rule to $list: $desc ($entry)";
				$c->stash->{'box_status'}->{'custom_success'} = "envelope_scanning_bwlist_manager_control_addnew_success";
			} else {
				aslog "warn", "Error adding new BWlist rule: Format error";
				$c->stash->{'box_status'}->{'custom_error'} = 'envelope_scanning_bwlist_manager_control_addnew_formaterror';
			}

		} catch Underground8::Exception with {
			aslog "warn", "Error adding new BWlist rule: Error adding new entry";
			push @{$c->stash->{'status'}->{'errors'}}, "Error adding new entry.";
		};
	}
}


sub delist : Local {
	my ( $self, $c, $id ) = @_;
	my $appliance = $c->config->{'appliance'};
    $c->stash->{'no_wrapper'} = 'yes';
	$c->stash->{template} = 'admin/envelope_scanning/bwlist_manager.tt2';
	$c->stash->{'config'} = $appliance->antispam->postfwd->load_config();
	$c->stash->{'engine_status'} = $appliance->antispam->postfwd->get_status_bwman();

	try {
		if ($appliance->antispam->postfwd->del_entry($id)) {
			$appliance->antispam->postfwd->commit;

			aslog "info", "Deleted BWlist entry $id";
			$c->stash->{'box_status'}->{'success'} = "del_success";
		} else {
			aslog "warn", "Error deleting BWlist entry $id";
			$c->stash->{'box_status'}->{'custom_error'} = 'envelope_scanning_bwlist_manager_control_del_error';
		}
	} catch Underground8::Exception with {
		aslog "warn", "Error deleting BWlist entry $id";
		push @{$c->stash->{'status'}->{'errors'}}, "Error delete entry.";
	};
}


1;

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


package LimesGUI::Controller::Admin::Envelope_Scanning::Dnsl_Manager;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Underground8::Exception;
use Underground8::Log;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();
	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager.tt2';
}


sub toggle_rbl_checks : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager.tt2';
	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();
	$c->stash->{'no_wrapper'} = "1";

	try {
		if($appliance->antispam->postfwd->get_status_rbl eq "enabled"){
			$appliance->antispam->postfwd->disable_rbl;
			aslog "info", "Toggled RBL status: Is now disabled";
			$c->stash->{'box_status'}->{'success'} = 'rbls_disabled';
		} else  {
			$appliance->antispam->postfwd->enable_rbl;
			aslog "info", "Toggled RBL status: Is now enabled";
			$c->stash->{'box_status'}->{'success'} = 'rbls_enabled';
		}
	
		$appliance->antispam->postfwd->commit;
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling RBL status, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{template} = 'redirect.inc.tt2';
	}
}


sub enlist : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $form_profile = {
		required => [qw(newrbl)],
		constraint_methods => {
			newrbl => validate_domain(),
		}
	};

	#$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager/control.inc.tt2';
	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager.tt2';
	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();
	$c->stash->{'no_wrapper'} = "1";

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $user_rbl = $c->req->params->{'newrbl'};
			$appliance->antispam->postfwd->add_rbl($user_rbl);
			$appliance->antispam->postfwd->commit;

			aslog "info", "Added new RBL $user_rbl";
			$c->stash->{'box_status'}->{'success'} = 'addnew_success';
		} catch Underground8::Exception with {
			aslog "warn", "Error adding RBL, entry already exists";
			$c->stash->{'box_status'}->{'error'} = 'addnew_error_entryexists';
		} catch Error with {
			my $E = shift;
			aslog "warn", "Error adding RBL, caught Exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{template} = 'redirect.inc.tt2';
		};
	}
}

sub delist : Local {
	my ($self, $c, $rbl) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();
	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager.tt2';
	$c->stash->{'no_wrapper'} = "1";

	try {
		$appliance->antispam->postfwd->del_rbl($rbl);
		$appliance->antispam->postfwd->commit;

		aslog "info", "Deleted RBL $rbl";
		$c->stash->{'box_status'}->{'success'} = 'del_success';
		$c->stash->{'deleted'} = "1";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error deleting RBL $rbl, caught exception $E";
		$c->session->{'exception'} = $E; 
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
    }; 

}

sub blocking_threshold : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $form_profile = {
		required => [qw(blockthreshold)],
		constraint_methods => {
			blockthreshold => qr(^[1-9]$),
		}
	};

	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager/control.inc.tt2';
	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		my $threshold = $c->req->params->{'blockthreshold'};

		try {
			$appliance->antispam->postfwd->rbl_threshold($threshold);
			$appliance->antispam->postfwd->commit;

			aslog "info", "Set RBL blocking threshold to $threshold";
			$c->stash->{'box_status'}->{'success'} = 'blockthreshold_success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting blocking threshold, caught exception $E";
			$c->session->{'exception'} = $E; 
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		}; 
	}
}


sub toggle_entry : Local {
	my ($self, $c, $rbl) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		if(defined( $appliance->antispam->postfwd->load_config->{'rbls'}->{$rbl} )){
			$appliance->antispam->postfwd->toggle_entry_rbl($rbl);
			$appliance->antispam->postfwd->commit;

			aslog "info", "Toggled RBL status for entry $rbl";
			$c->stash->{'box_status'}->{'success'} = 'toggle_success';
		}
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling RBL status, caught exception $E";
		$c->session->{'exception'} = $E; 
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	}; 


	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam();
	$c->stash->{template} = 'admin/envelope_scanning/dnsl_manager.tt2';
	$c->stash->{'no_wrapper'} = "1";
}

1;

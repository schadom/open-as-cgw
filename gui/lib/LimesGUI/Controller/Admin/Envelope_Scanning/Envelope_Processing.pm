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


package LimesGUI::Controller::Admin::Envelope_Scanning::Envelope_Processing;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Underground8::Exception;
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	$c->stash->{'antispam'} = $appliance->antispam;

	$c->stash->{template} = 'admin/envelope_scanning/envelope_processing.tt2';
}



sub toggle_greylisting : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/envelope_scanning/envelope_processing/greylisting.inc.tt2';
	$c->stash->{'antispam'} = $appliance->antispam;

	try {
		if($appliance->antispam->greylisting eq "disabled"){
			$appliance->antispam->disable_selective_greylisting();
			$appliance->antispam->enable_greylisting();
		} else {
			$appliance->antispam->disable_greylisting();
		}

		$appliance->antispam->commit;
		$c->stash->{'box_status'}->{'success'} = ($appliance->antispam->greylisting eq "enabled") 
			? 'greylisting_enable_success'
			: 'greylisting_disable_success';

		aslog "info", "Toggle Greylisting state";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling greylisting state, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{template} = 'redirect.inc.tt2';
	}
}


sub toggle_selective_greylisting : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/envelope_scanning/envelope_processing/greylisting.inc.tt2';
	$c->stash->{'antispam'} = $appliance->antispam;

	try {
		if($appliance->antispam->selective_greylisting eq "disabled"){
			$appliance->antispam->disable_greylisting();
			$appliance->antispam->enable_selective_greylisting();
		} else {
			$appliance->antispam->disable_selective_greylisting();
		}

		$appliance->antispam->commit;
		$c->stash->{'box_status'}->{'success'} = ($appliance->antispam->greylisting eq "enabled") 
			? 'botnetblocker_enable_success'
			: 'botnetblocker_disable_success';

		aslog "info", "Toggle Selective Greylisting/Botnetblocker state";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling selective greylisting/botnetblocker state, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{template} = 'redirect.inc.tt2';
	}

}


sub set_greylisting_params : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(triplettime message authtime)],
		constraint_methods => {
			triplettime => qr/^[1-9]?\d$/,
			authtime => qr/^[1-9]?[1-9]?\d$/,
			connectage => qr/^[1-9]?[1-9]?\d$/,
			domainlevel => qr/^[1-9]?\d$/, 
			message => qr/^.{5,80}$/,
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $triplettime = $c->req->param('triplettime');
			my $message= $c->req->param('message');
			my $authtime = $c->req->param('authtime');

			print STDERR " *** trying to set triplettime:$triplettime authtime:$authtime message:$message\n";
			$appliance->antispam->greylisting_authtime($authtime);
			$appliance->antispam->greylisting_triplettime($triplettime);
                        $appliance->antispam->greylisting_connectage($connectage);
                        $appliance->antispam->greylisting_domainlevel($domainlevel);
			$appliance->antispam->greylisting_message($message);
			$appliance->antispam->commit;

			aslog "info", "Set greylisting params (triplettime = $triplettime, authtime = $authtime, connectage = $connectage, domainlevel = $domainlevel, msg = $message)";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting greylisting params, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{template} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{template} = 'admin/envelope_scanning/envelope_processing/greylisting.inc.tt2';
	$c->stash->{'antispam'} = $appliance->antispam;
}


1;

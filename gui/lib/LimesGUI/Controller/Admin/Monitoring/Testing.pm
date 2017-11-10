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


package LimesGUI::Controller::Admin::Monitoring::Testing;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Data::FormValidator::Constraints::Underground8 qw(special_char_count valid_gtube valid_gtube_score);
use Underground8::Exception;
use Underground8::Log;
use Error qw(:try);

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/monitoring/testing.tt2';
	$c->stash->{'gtube_score'} = $appliance->antispam->get_gtube_score();
	$c->stash->{'gtube_string'} = $appliance->antispam->get_gtube();
}


sub spam : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(gtube_string gtube_score)],
		constraint_methods => {
			gtube_string => valid_gtube(5,25),
			gtube_score => valid_gtube_score(),
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $gtube_string = $c->req->params->{'gtube_string'};
			my $gtube_score  = $c->req->params->{'gtube_score'};

			$appliance->antispam->set_gtube($gtube_string);
			$appliance->antispam->set_gtube_score($gtube_score);
			$appliance->antispam->commit;

			aslog "info", "Saved spam-testing settings gtube string/score";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error saving spam-testing settings gtube string/score, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
		
	}

	$c->stash->{'gtube_score'} = $appliance->antispam->get_gtube_score();
	$c->stash->{'gtube_string'} = $appliance->antispam->get_gtube();
	$c->stash->{template} = 'admin/monitoring/testing/spam.inc.tt2';
}

1;

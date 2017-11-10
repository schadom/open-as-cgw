package LimesGUI::Controller::Admin::Monitoring::Connection_Status;

use namespace::autoclean;
use base 'LimesGUI::Controller';

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/monitoring/connection_status.tt2';
}

1;

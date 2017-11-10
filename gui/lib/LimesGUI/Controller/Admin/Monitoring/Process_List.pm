package LimesGUI::Controller::Admin::Monitoring::Process_List;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'template'} = 'admin/monitoring/process_list.tt2';
	$c->stash->{'plist'}    = $appliance->report->processlist();
	$c->stash->{'psubst'}   = Underground8::Utils::get_process_substitutions();
	$c->stash->{'pdmask'}   = Underground8::Utils::get_process_deletemask();

	aslog "info", "Called process-list";
}

sub order : Local {
	my ( $self, $c, $order ) = @_;
	$c->stash->{'order'} = $order;
	$c->forward('index');
}

sub update : Local {
	my ( $self, $c, $order ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'order'} = $order;
	$c->stash->{'template'} = 'admin/monitoring/process_list/plist.inc.tt2';
	$c->stash->{'plist'}  = $appliance->report->processlist();;
	$c->stash->{'psubst'} = Underground8::Utils::get_process_substitutions();
	$c->stash->{'pdmask'} = Underground8::Utils::get_process_deletemask();
}

1;

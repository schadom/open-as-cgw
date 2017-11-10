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


package LimesGUI::Controller::Admin::System::General_Settings;

use namespace::autoclean;
use Error qw(:try);
use base 'LimesGUI::Controller';
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $versions = $appliance->report->versions();

	$versions->{'last_update'}->set_locale('de');
	$versions->{'time_clamav'}->set_locale('de');
	$versions->{'last_update_printable'} = $versions->{'last_update'}->strftime("%c");
	$versions->{'time_clamav_printable'} = $versions->{'time_clamav'}->strftime("%c");

	$c->stash->{versions} = $versions;
	$c->stash->{template} = 'admin/system/general_settings.tt2';
}


sub reboot_shutdown : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(action)],
		constraint_methods => {
			action => qr/^(reboot|shutdown)$/,
		}
	};
	
	my $result = $self->process_form($c, $form_profile);

	if ($result->success()) {
		$c->session->{'action'} = $c->request->params->{'action'};
		$c->stash->{'notify'} = 'yes';
		$c->stash->{'notification_url'} = $c->uri_for('/admin/system/general_settings/reboot_shutdown_notification');
	} 
	$c->stash->{'template'} = 'admin/system/general_settings/reboot_shutdown.inc.tt2';
}


sub reboot_shutdown_notification : Local {
	my ( $self, $c ) = @_;
	my $action = '';

	$c->stash->{'template'} = 'admin/system/general_settings/reboot_shutdown_notification.inc.tt2';
 
	if ($c->session->{'action'}) {
		$action = $c->session->{'action'};
	}

	if ($action eq 'reboot') {
		$c->stash->{'heading'} = 'reboot';
		$c->stash->{'text'} = 'reboot_action_message';
		$c->stash->{'link_text'} = 'reboot';
		$c->stash->{'link_url'} = '/admin/system/general_settings/reboot_action';
	} elsif ($action eq 'shutdown') {
		$c->stash->{'heading'} = 'shutdown';
		$c->stash->{'text'} = 'shutdown_action_message';
		$c->stash->{'link_text'} = 'shutdown';
		$c->stash->{'link_url'} = '/admin/system/general_settings/shutdown_action';
	} else {
		# no valid action specified
		$c->stash->{'redirect_url'} = $c->uri_for('/');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	}

	delete($c->session->{'action'});
}


sub reboot_action : Local {
	my ( $self, $c ) = @_;
	$c->stash->{'message'} = 'is_rebooting';
	$c->stash->{'template'} = 'admin/system/general_settings/reboot_shutdown_progress.inc.tt2';

	aslog "info", "Restarting appliance";
	$c->config->{'appliance'}->system->reboot(); 
}

sub shutdown_action : Local {
	my ( $self, $c ) = @_;
	$c->stash->{'message'} = 'is_shutting_down';
	$c->stash->{'template'} = 'admin/system/general_settings/reboot_shutdown_progress.inc.tt2';

	aslog "info", "Shutting down appliance";
	$c->config->{'appliance'}->system->shutdown(); 
}

sub reset : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};	
	
	my $form_profile = {
		required => [qw(type)],
		constraint_methods => {
			type => qr/^(statistics|soft|hard)$/,
		}
	};
	
	my $result = $self->process_form($c,$form_profile);
	$c->stash->{'template'} = 'admin/system/general_settings/reset.inc.tt2';

	if ($result->success()) {
		$c->session->{'reset_type'} = $c->request->params->{'type'};
		$c->stash->{'notify'} = 'yes';
		$c->stash->{'notification_url'} = $c->uri_for('/admin/system/general_settings/reset_notification');
	}
}

sub reset_notification : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};	
  
	my $reset_type = '';

	$c->stash->{'template'} = 'admin/system/general_settings/reset_notification.inc.tt2';
	$c->stash->{'link_url'} = '/admin/system/general_settings/reset_action';

	if ($c->session->{'reset_type'}) {
		$reset_type = $c->session->{'reset_type'};
	}
	
	if ($reset_type eq 'statistics') {
		$c->stash->{'heading'} = 'reset_statistics';
		$c->stash->{'text'} = 'reset_statistics_action_message';
		$c->stash->{'link_text'} = 'reset_statistics';
	} elsif ($reset_type eq 'soft') {
		$c->stash->{'heading'} = 'reset_soft';
		$c->stash->{'text'} = 'reset_soft_action_message';
		$c->stash->{'link_text'} = 'reset_soft';
	} elsif ($reset_type eq 'hard') {
		$c->stash->{'heading'} = 'reset_hard';
		$c->stash->{'text'} = 'reset_hard_action_message';
		$c->stash->{'link_text'} = 'reset_hard';
	} else {
		#TODO error handling
	}
}

sub reset_action : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $reset_type = '';

	if ($c->session->{'reset_type'}) {
		$reset_type = $c->session->{'reset_type'};
		delete($c->session->{'reset_type'});
	}
	 
	try {
		if ($reset_type eq 'statistics') {
			$appliance->system->reset_statistics(); 
		} elsif ($reset_type eq 'soft') {
			$appliance->system->reset_soft(); 
		} elsif ($reset_type eq 'hard') {
			$appliance->system->reset_hard(); 
		}

		aslog "info", "Resetting appliance, type <$reset_type>";
		$c->stash->{'template'} = 'admin/system/general_settings/reset_progress.inc.tt2';
		$c->stash->{'redirect_url'} = $c->uri_for('/');
		$c->stash->{'redirect_timeout'} = '5000';
		$c->delete_session('logout');
		$c->logout();
	} catch Underground8::Exception with {
			my $E = shift;
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
	};
}

1;

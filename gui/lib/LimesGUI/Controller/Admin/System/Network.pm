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


package LimesGUI::Controller::Admin::System::Network;

use base 'LimesGUI::Controller';
use namespace::autoclean;
use strict;
use warnings;
use Error qw(:try);
use NetAddr::IP;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::Dumper;
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'system'} = $appliance->system;
	$c->stash->{template} = 'admin/system/network.tt2';
}

sub configure_hostname : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(hostname domainname)],
		constraint_methods => {
		hostname => FV_net_domain(-nospace),
		domainname => FV_net_domain(-nospace),
		}
	};

	$c->stash->{'template'} = 'admin/system/network/hostname.inc.tt2';
	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {   
		try {
			my $hostname = $c->request->params->{'hostname'};
			my $domainname = $c->request->params->{'domainname'};
			# set the values;
			$appliance->system->set_hostname($hostname);
			$appliance->system->set_domainname($domainname);
			# commit
			$appliance->system->commit;

			#Needed for Amavis to restart -after- system->commit set host/domain
			$appliance->antispam->commit;
			aslog "info", "Successfully changed sytem hostname/domainname to $hostname/$domainname";
			$c->stash->{'box_status'}->{'success'} = 'status_updated';
		} catch Underground8::Exception with {   
			my $E = shift;
			aslog "warn", "Error changining system hostname/domainname";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'system'} = $appliance->system;
}



sub configure_interface : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	# Profile for FormValidator
	my $form_profile = {
		required	=> [qw( 
			ip_address 
			subnet_mask 
			default_gateway
		)],
		constraint_methods => {
		ip_address	  => ip_address(),
		subnet_mask	 => ip_address(),
		default_gateway => [ip_address(),{
							 constraint_method  => $self->gateway_in_subnet(),
							 params	  => [qw( ip_address subnet_mask default_gateway )]
						 }]
		},
		msgs => {
			constraints => {
				'gateway_in_subnet' => 'err_subnet',
			},
		}
	};
	
	# process the form
	my $result = $self->process_form($c, $form_profile);
	
	$c->stash->{'template'} = 'admin/system/network/ip.inc.tt2';
	$c->stash->{'system'} = $appliance->system;


	# on success, the following steps should be taken:
	# - notification do you really want to?
	# - cancel removes the notification
	# - ok triggers the action and loading is displayed
	# - loading shows the new uri and automatically redirects after 8sec
	#   to the new uri
	if ($result->success()) {
		$c->session->{'new_interface'}->{'ip_address'} = $c->request->params->{'ip_address'};
		$c->session->{'new_interface'}->{'subnet_mask'} = $c->request->params->{'subnet_mask'};
		$c->session->{'new_interface'}->{'default_gateway'} = $c->request->params->{'default_gateway'};
		 
		$c->stash->{'notify'} = 'yes';
		$c->stash->{'notification_url'} = $c->uri_for('/admin/system/network/ip_notification');
	}
}


sub ip_notification : Local
{
	my ($self, $c) = @_;

	$c->stash->{'heading'} = 'system_network_ip_notification_heading';
	$c->stash->{'text'} = 'system_network_ip_notification_text';
	$c->stash->{'link_text'} = 'system_network_ip_notification_link_text';
	$c->stash->{'link_url'} = '/admin/system/network/ip_action';
	$c->stash->{'template'} = 'admin/system/network/ip_notification.inc.tt2';
}


sub ip_action : Local
{
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $ip_address =$c->session->{'new_interface'}->{'ip_address'};
	my $subnet_mask =$c->session->{'new_interface'}->{'subnet_mask'};
	my $default_gateway = $c->session->{'new_interface'}->{'default_gateway'};

	$c->stash->{'template'} = 'admin/system/network/ip_progress.inc.tt2';

	# fallback defaults
	$c->stash->{'redirect_url'} = $c->uri_for('/admin/dashboard/dashboard');
	$c->stash->{'redirect_timeout'} = "6000";

	try {
		$appliance->system->net_newconf_to_oldconf();
		# set the values;
		$appliance->system->set_ip_address($ip_address);
		$appliance->system->set_subnet_mask($subnet_mask);
		$appliance->system->set_default_gateway($default_gateway);
		# commit
		$appliance->system->net_notify('1');
		$appliance->system->set_net_user_change(1);

		aslog "info", "Changed network settings to ip:$ip_address, sm:$subnet_mask, gw:$default_gateway, committing...";

		if ($appliance->system->commit) {
			# delete session and generate redirect url
			$appliance->set_alert_notify_nic_change();

			$c->delete_session('ip_changed');

			my $login_uri = $c->uri_for('/');
			$login_uri =~ s/\:\/\/.+\:(\d+)/\:\/\/$ip_address\:$1/;

			$c->stash->{'redirect_url'} = $login_uri;
			$c->stash->{'redirect_timeout'} = "6000";
			aslog "info", "...network settings successfully changed.";
		} else {
			# TODO error handling if commit returns false ?!
			# of course this should never happen
		}
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error setting network settings, caught expection $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};
}


sub configure_dns : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	
	my $form_profile = {
		required => [qw(primary_dns secondary_dns)],
		constraint_methods => {
		primary_dns => FV_net_IPv4(),
		secondary_dns => FV_net_IPv4()
		}
	};
	
	$c->stash->{'template'} = 'admin/system/network/dns.inc.tt2';
	my $result = $self->process_form($c, $form_profile);

	if ($result->success()) {
		try {
			my $primary_dns = $c->request->params->{'primary_dns'};
			my $secondary_dns = $c->request->params->{'secondary_dns'};
			# set the values;
			$appliance->system->set_primary_dns($primary_dns);
			$appliance->system->set_secondary_dns($secondary_dns);
			# commit
			$appliance->system->commit;
			aslog "info", "Successfully changed pri/sec DNS to $primary_dns/$secondary_dns";
			$c->stash->{'box_status'}->{'success'} = 'status_set';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error changing DNS settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	
	$c->stash->{'system'} = $appliance->system;
}


sub configure_proxy : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
   
	my $form_profile = {
		optional => [qw(proxy_username proxy_password)],
		required => [qw(proxy_server proxy_port)],
		constraint_methods => {
			proxy_server => FV_max_length(32),
			proxy_port => qr/^\d+$/,
			proxy_username => FV_max_length(64),
			proxy_password => FV_max_length(64),
		}
	};
	
	
	$c->stash->{'template'} = 'admin/system/network/proxy.inc.tt2';
	my $result = $self->process_form($c, $form_profile);

	if ($result->success()) {
		try {
			# get parameters
			my $proxy_server = $c->request->params->{'proxy_server'};
			my $proxy_port = $c->request->params->{'proxy_port'};
			my $proxy_username = $c->request->params->{'proxy_username'};
			my $proxy_password = $c->request->params->{'proxy_password'};
			my $proxy_enabled = $c->request->params->{'proxy_enabled'};
			
			# set the values;
			$appliance->system->set_proxy_server($proxy_server);
			$appliance->system->set_proxy_port($proxy_port);
			$appliance->system->set_proxy_username($proxy_username);
			$appliance->system->set_proxy_password($proxy_password);

			if ($proxy_enabled) {
				if ($proxy_enabled eq 'enabled') {
					$appliance->system->set_proxy_enabled(1);
				} else {
					$appliance->system->set_proxy_enabled(0);
				}
			} else {
				$appliance->system->set_proxy_enabled(0);
			}

			# commit
			$appliance->system->commit;
			aslog "info", "Changed proxy-settingsto use server:$proxy_server user:$proxy_username pw:$proxy_password enabled:$proxy_enabled";
			$c->stash->{'box_status'}->{'success'} = 'status_set';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting proxy-settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}
	
	$c->stash->{'system'} = $appliance->system;
}


1;

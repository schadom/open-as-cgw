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


package LimesGUI::Controller::Admin::Quarantine::General_Settings;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Underground8::Exception;
use Underground8::Log;

sub index : Private {
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    $c->stash->{template} = 'admin/quarantine/general_settings.tt2';
	update_stash($self, $c);
}

sub update_stash {
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    $c->stash->{'q_state'} = $appliance->quarantine->quarantine_state();
    $c->stash->{'notify_unconfirmees_enabled'} = $appliance->quarantine->notification_sending_state();
    $c->stash->{'send_spamreport_enabled'} = $appliance->quarantine->report_sending_state();
    $c->stash->{'show_virus'} = $appliance->quarantine->show_virus_state();
    $c->stash->{'show_banned'} = $appliance->quarantine->show_banned_state();
    $c->stash->{'show_spam'} = $appliance->quarantine->show_spam_state();
    $c->stash->{'hide_links_virus'} = $appliance->quarantine->hide_links_virus_state();
    $c->stash->{'hide_links_banned'} = $appliance->quarantine->hide_links_banned_state();
    $c->stash->{'hide_links_spam'} = $appliance->quarantine->hide_links_spam_state();
    $c->stash->{'settings'} =$appliance->quarantine->quarantineNG();

    $c->stash->{'spam_report_enabled'} = $appliance->quarantine->get_notification_state('send_reports_enabled');
    $c->stash->{'spam_report_hours'} = $appliance->quarantine->get_interval("send_spamreport")->{'h'};
    $c->stash->{'spam_report_days'} = $appliance->quarantine->get_interval("send_spamreport")->{'d_of_w'};

    $c->stash->{'activation_request_enabled'} = $appliance->quarantine->get_notification_state('send_notifications_enabled');
    $c->stash->{'activation_request_hours'} = $appliance->quarantine->get_interval("notify_unconfirmees")->{'h'};
    $c->stash->{'activation_request_days'} = $appliance->quarantine->get_interval("notify_unconfirmees")->{'d_of_w'};

}


sub toggle_notification_state : Local {
	my ( $self, $c, $type, $value ) = @_;
	my $appliance = $c->config->{'appliance'};

	$appliance->quarantine->toggle_notifications( ($type eq "spam_report") 
		? "send_reports_enabled" : "send_notifications_enabled", $value );
	$appliance->quarantine->commit;

	aslog "info", "Toggled quarantine notification state type=$type, value=$value";

	$c->stash->{template} = 'admin/quarantine/general_settings/' . $type . '.inc.tt2';
	$c->stash->{'box_status'}->{'success'} = "success";
	update_stash($self, $c);
}


sub change_settings : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my ($max_retries, $max_interval, $global_lifetime, $user_lifetime, $sender_name, $sizelimit_address);

	my $form_profile = {
		required => [qw(max_confirm_retries max_confirm_interval global_item_lifetime user_item_lifetime sender_name sizelimit_address)],
		constraints => {
			max_confirm_retries => qr/^\d+$/,
			max_confirm_interval => qr/^\d+$/,
			global_item_lifetime => qr/^\d+$/,
			user_item_lifetime => qr/^\d+$/,
			sizelimit_address => qr/^[-!#$%&'*+\/0-9=?A-Z^_a-z{|}~](\.?[-!#$%&'*+\/0-9=?A-Z^_a-z{|}~])*@[a-zA-Z](-?[a-zA-Z0-9])*(\.[a-zA-Z](-?[a-zA-Z0-9])*)+$/, 
			sender_name => qr/^[-a-zA-Z0-9_.:* ]{1,128}$/,
		},
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		my $params = {
			max_confirm_retries   => $c->req->param('max_confirm_retries'),
			max_confirm_interval  => $c->req->param('max_confirm_interval'),
			global_item_lifetime  => ($c->req->param('global_item_lifetime') > 28 ? 28 : $c->req->param('global_item_lifetime')),
			user_item_lifetime    => ($c->req->param('user_item_lifetime') > 28 ? 28 : $c->req->param('user_item_lifetime')),
			sender_name           => $c->req->param('sender_name'),
			sizelimit_address     => $c->req->param('sizelimit_address'),
		};

		try {
			$appliance->quarantine->change_multiple_settings($params);
			$appliance->quarantine->commit();
			aslog "info", "Changed quarantine general settings";

			update_stash($self, $c);
			$c->stash->{'box_status'}->{'success'} = 'success';
			$c->stash->{template} = 'admin/quarantine/general_settings/timing_options.inc.tt2';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error changing quarantine general settings, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	update_stash($self, $c);
	$c->stash->{template} = 'admin/quarantine/general_settings/timing_options.inc.tt2';
}

sub change_intervals : Local {
	my ($self, $c, $type) = @_;
	my $appliance = $c->config->{'appliance'};

	my $day_hours = $c->req->param('day_hours');
	my @week_days = $c->req->param('week_days');
	my $to_change = { 'h' => $day_hours, 'd_of_w' => \@week_days, };

	try {
		$appliance->quarantine->change_intervals({ "notify_unconfirmees_interval" => $to_change, }) if $type eq "activation_request";
		$appliance->quarantine->change_intervals({ "send_spamreport_interval" => $to_change, }) if $type eq "spam_report";
		$appliance->quarantine->commit();
		aslog "info", "Changed quarantine time intervals for type $type";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error changing quarantine time intervals for type $type, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};


	update_stash($self, $c);
	$c->stash->{'box_status'}->{'success'} = "success";
	$c->stash->{template} = 'admin/quarantine/general_settings/' . $type . '.inc.tt2';
}

sub change_language : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $language = $c->req->param('language');

	try {
		$appliance->quarantine->language($language);
		$appliance->quarantine->commit();

		aslog "info", "Changed quarantine language settings to $language";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error changing quarantine language settings, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_stash($self, $c);
	$c->stash->{'box_status'}->{'success'} = "success";
	$c->stash->{template} = 'admin/quarantine/general_settings/language_options.inc.tt2';
}

1;

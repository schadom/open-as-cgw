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


package LimesGUI::Controller::Admin::Quarantine::Quarantining_Options;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Exception;
use Underground8::Log;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/quarantine/quarantining_options.tt2';
	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'q_state'} = $appliance->quarantine->quarantine_state();
	$c->stash->{'mails_destiny'} = $appliance->antispam->get_mails_destiny() ;
	$c->stash->{'admin_boxes'} = $appliance->antispam->get_admin_boxes();
	$c->stash->{'domains'} = $appliance->antispam->domain_read();

	my @wl = split(',', $appliance->quarantine->whitelisted_domains() );
	$c->stash->{'whitelisted_domains_array'} = \@wl;
	$c->stash->{'whitelisted_domains'} = $appliance->quarantine->whitelisted_domains();

	$c->stash->{'report_show'}->{'virus'} = $appliance->quarantine->show_virus_state();
	$c->stash->{'report_show'}->{'banned'} = $appliance->quarantine->show_banned_state();
	$c->stash->{'report_show'}->{'spam'} = $appliance->quarantine->show_spam_state();
	$c->stash->{'report_hidelinks'}->{'virus'} = $appliance->quarantine->hide_links_virus_state();
	$c->stash->{'report_hidelinks'}->{'banned'} = $appliance->quarantine->hide_links_banned_state();
	$c->stash->{'report_hidelinks'}->{'spam'} = $appliance->quarantine->hide_links_spam_state();
} 



sub change_destiny : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $new_destiny = {
		spam_destiny => $c->req->param('destiny_spam'),
		virus_destiny => $c->req->param('destiny_virus'),
		banned_destiny => $c->req->param('destiny_banned'),
	};

	try {
		my $use_quarantine = 0;
		my $admin_boxes_condition = 1;

		foreach my $key (keys %$new_destiny) {
			if($new_destiny->{$key} == 2) {
				$use_quarantine = 1;
			} elsif($ney_destiny->{$key} == 1) {
				my $box_type = $key;
				my $admin_boxes = $appliance->antispam->get_admin_boxes();
				$box_type =~ s/destiny/box/;
			
				if((not $admin_boxes->{$box_type}) || $admin_boxes->{$box_type} eq '') {
					$admin_boxes_condition = 0;
				}
			}
		}

		if($admin_boxes_condition == 0) {
			$c->stash->{'box_status'}->{'custom_error'} = $c->localize('error_give_admin_email_adress');
		} elsif($admin_boxes_condition == 1){
			my $admin_boxes = $appliance->antispam->get_admin_boxes();
			my $mails_destiny = $appliance->antispam->get_mails_destiny();
			my $q_state = $appliance->quarantine->quarantine_state();
			
			if($q_state != $use_quarantine) {
				if($q_state == 0) {
					$appliance->antispam->quarantine_enabled(1);
					$appliance->quarantine->global_enable($admin_boxes, $mails_destiny);
				} else {
					$appliance->antispam->quarantine_enabled(0);
					$appliance->quarantine->global_disable($admin_boxes, $mails_destiny);
				}
			}

			$appliance->antispam->mails_destiny($new_destiny);
			$appliance->antispam->commit;
			
			$admin_boxes = $appliance->antispam->get_admin_boxes();
			$mails_destiny = $appliance->antispam->get_mails_destiny();
			$appliance->quarantine->update_sql_quarantine_location($admin_boxes, $mails_destiny);
			$appliance->quarantine->commit;

			aslog "info", "Changed quarantine destinies";
			$c->stash->{'box_status'}->{'success'} = "success";
		}


	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error changing quarantine destinies, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_stash($self, $c);
	$c->stash->{template} = 'admin/quarantine/quarantining_options/mail_handling.inc.tt2';
}

sub change_admin_boxes : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $mails_destiny = $appliance->antispam->get_mails_destiny;
	my $required = [];
	my $optional = [];

	foreach my $key (keys %$mails_destiny) {
		my $box = $key;
		$box =~ s/destiny/box/;
		if($mails_destiny->{$key} eq 1) {
			push @$required, $box ;
		} else {
			push @$optional, $box ;
		}
	}


	my $form_profile = {
		required => $required,
		optional => $optional,
			constraint_methods => {
				spam_box => email(),
				virus_box => email(),
				banned_box => email(),
			}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()) {
		my $new_admin_boxes = {
			spam_box => $c->req->param('spam_box'),
			virus_box => $c->req->param('virus_box'),
			banned_box => $c->req->param('banned_box'),
		};

		try {
			$appliance->antispam->admin_boxes($new_admin_boxes);
			$appliance->antispam->commit;

			$c->stash->{'box_status'}->{'success'} = "success";
			$appliance->quarantine->update_sql_quarantine_location(
				$appliance->antispam->get_admin_boxes, 
				$appliance->antispam->get_mails_destiny
			);
			aslog "info", "Changed quarantine admin mailboxes";
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error changing quarantine admin mailboxes, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	update_stash($self, $c);
	$c->stash->{template} = 'admin/quarantine/quarantining_options/global_mailboxes.inc.tt2';
}

sub change_quarantine_domains : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my @domains = $c->req->param('domains');
	my $enabled = $c->req->param('enabled');

	try {
		$appliance->quarantine->update_quarantine_whitelist(@domains);
		$appliance->quarantine->commit;

		aslog "info", "Changed quarantine domains (@domains)";
		$c->stash->{'box_status'}->{'success'} = "success";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error changing quarantine domains";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};


	update_stash($self, $c);
	$c->stash->{template} = 'admin/quarantine/quarantining_options/domains.inc.tt2';
}

sub change_report_options : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $my_virus = $c->request->param('virus');
	my $my_banned = $c->request->param('banned');
	my $my_spam = $c->request->param('spam');

	my ($virus_st, $virus_hide);
	($virus_st, $virus_hide) = (1,0) if $my_virus eq "full";
	($virus_st, $virus_hide) = (0,0) if $my_virus eq "mail";
	($virus_st, $virus_hide) = (0,1) if $my_virus eq "links";

	my ($banned_st, $banned_hide);
	($banned_st, $banned_hide) = (1,0) if $my_banned eq "full";
	($banned_st, $banned_hide) = (0,0) if $my_banned eq "mail";
	($banned_st, $banned_hide) = (0,1) if $my_banned eq "links";

	my ($spam_st, $spam_hide);
	($spam_st, $spam_hide) = (1,0) if $my_spam eq "full";
	($spam_st, $spam_hide) = (0,0) if $my_spam eq "mail";
	($spam_st, $spam_hide) = (0,1) if $my_spam eq "links";

	my $params = {
		"hide_links_virus" => $virus_hide,
		"hide_links_banned" => $banned_hide,
		"hide_links_spam" => $spam_hide,
		"show_virus" => $virus_st,
		"show_banned" => $banned_st,
		"show_spam" => $spam_st,
	};

	try {
		$appliance->quarantine->change_multiple_settings($params);
		$appliance->quarantine->commit();
		aslog "info", "Changed quarantine report options (v:$my_virus, b:$my_banned, s:$my_spam)";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error changing quarantine report options";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_stash($self, $c);
	$c->stash->{template} = 'admin/quarantine/quarantining_options/visibility.inc.tt2';
}

1;

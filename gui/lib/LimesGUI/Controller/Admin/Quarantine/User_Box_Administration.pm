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


package LimesGUI::Controller::Admin::Quarantine::User_Box_Administration;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Log;

my ($filter_domain, $filter_user);

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/quarantine/user_box_administration.tt2';
	$c->stash->{'domains'} = $appliance->antispam->domain_read();
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'q_state'} = $appliance->quarantine->quarantine_state();
	$c->stash->{'settings'} = $appliance->quarantine->quarantineNG();
	$c->stash->{'domains'} = $appliance->antispam->domain_read();
	$c->stash->{'no_wrapper'} = "1";
} 

sub recipient_mails : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $form_profile = {
		required => [qw(domain username)],
		constraint_methods => {
			username => valid_username(),
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		my $recipient = $c->req->param('username');
		my $domain = $c->req->param('domain');
		my $email = $recipient . '@' . $domain;
		my $mails;

		($filter_domain, $filter_user) = ($domain, $recipient);
		my $res = $appliance->quarantine->valid($email);
		
		try {
			if($res != -1) {
				$mails = $appliance->quarantine->recipient_mails($email);
				$c->stash->{'mails'} = $mails;
				$c->stash->{'q_size'} = defined $mails ? scalar @$mails : 0;
			} else {
				$c->stash->{'q_size'} = 0;
			}

			$c->stash->{'recipient_state'} = $res;
			$c->stash->{'recipient'} = $email;
			$c->session->{'recipient'} = $email;
			$c->stash->{'redirected'} = 1;
			$c->stash->{'re_user'} = $recipient;
			$c->stash->{'re_domain'} = $domain;

			if($res == -1) {
				$c->stash->{'box_status'}->{'custom_error'} =
					$c->localize('quarantine_user_box_administration_status_information_unknown');
				aslog "warn", "Error getting recipient mails for quarantine: Status information unknown";
			} else {
				$c->stash->{'box_status'}->{'success'} = "success";
				aslog "info", "Updated recipient mails for quarantine";
			}
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error getting recipient mails for quarantine, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{'template'} = 'admin/quarantine/user_box_administration.tt2';
	update_stash($self, $c);
}

sub update_recipient_mails  {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my ($recipient, $domain) = ($filter_user, $filter_domain);
	my $email = $recipient . '@' . $domain;
	my $emails;

	my $res = $appliance->quarantine->valid($email);
	try {
		if($res != -1) {
			$mails = $appliance->quarantine->recipient_mails($email);
			$c->stash->{'mails'} = $mails;
			$c->stash->{'q_size'} = defined $mails ? scalar @$mails : 0;
		} else {
			$c->stash->{'q_size'} = 0;
		}

		$c->stash->{'recipient_state'} = $res;
		$c->stash->{'recipient'} = $email;
		$c->session->{'recipient'} = $email;
		$c->stash->{'redirected'} = 1;
		$c->stash->{'re_user'} = $recipient;
		$c->stash->{'re_domain'} = $domain;
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error updating recipient mails, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{'template'} = 'admin/quarantine/user_box_administration.tt2';
	update_stash($self, $c);
}

sub change_current_recipient : Local{
	my ($self, $c, $email) = @_;
	my $appliance = $c->config->{'appliance'};

	$email =~ /^(.+)@(.+)$/;
	$filter_user = $1;
	$filter_domain = $2;

	update_recipient_mails($self, $c);
}

sub delete : Local {
	my ( $self, $c ,$mail_id) = @_; 
	my $appliance = $c->config->{'appliance'};

	try {   
		my $res = $appliance->quarantine->valid($c->session->{'recipient'});
		$appliance->quarantine->delete_mail($c->session->{'recipient'},$mail_id);

		my $mails = $appliance->quarantine->recipient_mails($c->session->{'recipient'});
		$appliance->quarantine->commit();

		$c->stash->{'q_size'} = defined $mails ? scalar @$mails : 0;
		$c->stash->{'mails'} = $mails;
		$c->stash->{'recipient_state'} =  $res ;
		$c->stash->{'box_status'}->{'success'} = "mail_deleted";
		aslog "info", "Deleted quarantined email $mail_id";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error deleting quarantined email $mail_id, caught exception $E";
		$c->session->{'exception'} = $E; 
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_recipient_mails($self, $c);
}

sub release : Local {
	my ( $self, $c ,$mail_id) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		my $res = $appliance->quarantine->valid($c->session->{'recipient'});
		my $output = $appliance->quarantine->release_mail($c->session->{'recipient'},$mail_id);
		my $mails = $appliance->quarantine->recipient_mails($c->session->{'recipient'});
		$appliance->quarantine->commit();

		$c->stash->{'q_size'} = defined $mails ? scalar @$mails : 0;
		$c->stash->{'mails'} = $mails;
		$c->stash->{'recipient_state'} =  $res ;

		aslog "info", "Released quarantined mail $mail_id";
		$c->stash->{'box_status'}->{'success'} = "mail_released";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error releasing quarantined mail $mail_id";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	update_recipient_mails($self, $c);
}

sub delete_all : Local {
	my ( $self, $c, $email ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		my $res = $appliance->quarantine->valid($email);
		my $output = $appliance->quarantine->delete_all_mails($email);
		my $mails = $appliance->quarantine->recipient_mails($email);
		$appliance->quarantine->commit();

		my  ($user, $domain) = split /\@/, $email;
		$c->stash->{'re_user'} = $user;
		$c->stash->{'re_domain'} = $domain;
		$c->stash->{'q_size'} =defined $mails ? scalar @$mails : 0;
		$c->stash->{'mails'} = $mails;
		$c->stash->{'recipient_state'} = $res;

		aslog "info", "Deleted all quarantined e-mails for $email";
		$c->stash->{'box_status'}->{'success'} = "all_mails_deleted";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error deleting all quarantined e-mails for $email";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{'template'} = 'admin/quarantine/user_box_administration.tt2';
	update_stash($self, $c);
}

1;

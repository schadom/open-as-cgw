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


package LimesGUI::Controller::Admin::System::Notifications;

use Moose;
use namespace::autoclean;
BEGIN { extends 'LimesGUI::Controller'; };
use strict;
use warnings;
use TryCatch;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Log;
use Underground8::Exception;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my ($i, $limit);

	$c->stash->{'notification'} = $appliance->notification;
	$c->stash->{'notification_account_list'} = [];
	$limit = scalar @{$appliance->notification->email_accounts()};

	for ($i = 0; $i < $limit; $i++) {
		$c->stash->{'notification_account_list'}->[$i]->{'name'} = $appliance->notification->email_accounts_name($i);
		$c->stash->{'notification_account_list'}->[$i]->{'address'} = $appliance->notification->email_accounts_address($i);
		$c->stash->{'notification_account_list'}->[$i]->{'type'} = $appliance->notification->email_accounts_type($i);
		$c->stash->{'notification_account_list'}->[$i]->{'smtp_login'} = $appliance->notification->email_accounts_smtp_login($i);
		$c->stash->{'notification_account_list'}->[$i]->{'smtp_password'} = $appliance->notification->email_accounts_smtp_password($i);
		$c->stash->{'notification_account_list'}->[$i]->{'smtp_server'} = $appliance->notification->email_accounts_smtp_server($i);
		$c->stash->{'notification_account_list'}->[$i]->{'smtp_use_ssl'} = $appliance->notification->email_accounts_smtp_use_ssl($i);
	}

	$c->stash->{template} = 'admin/system/notifications.tt2';
}


sub add_recipient : Local {
	my ( $self, $c, $index ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(email name)],
		optional => [qw(smtpsrv)],
		constraint_methods => {
			email => email(),
			name => qr/^.+$/,
			smtpsrv => ip_address_or_hostname(),
		}
	};

	my ($email, $name, $smtpsrv, $login, $password, $usetls, $type);
	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			$name = $c->req->params->{'name'};
			$smtpsrv = $c->req->params->{'smtpsrv'};
			$email = $c->req->params->{'email'};
			$login = $c->req->params->{'login'};
			$password = $c->req->params->{'password'};
			$usetls = $c->req->params->{'usetls'};

			if(defined $smtpsrv && length $smtpsrv) {
				if(defined $login && length $login && defined $password && length $password) {
					$type = 'smtpauth';
					$usetls = 0 if $usetls != 1;
				} else {
					$login = '';
					$password = '';
					$usetls = 0;
					$type = 'smtp';
				}
			} else {
				$login = $password = $smtpsrv = '';
				$usetls = 0;
				$type = 'smtp';
			};

			$appliance->notification->email_set_account($email, $name, $type, $smtpsrv, $login, $password, $usetls);
			$appliance->notification->commit();
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch (Underground8::Exception $E) {
			#my $E = shift;
			aslog "warn", "Error adding new notifications recipient.";
			$c->session->{'exception'} = $E; 
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
			$c->stash->{'box_status'}->{'custom_error'} = 'add_error';
		}
	}

	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = 1;
}

sub delete : Local {
	my ($self, $c, $index) = @_;
	my $appliance = $c->config->{'appliance'};
	my ($i, $limit, $address);

	if(defined $index && $index =~ /^\d+$/ && $index >= 0 && $index < scalar @{$appliance->notification->email_accounts()}){
		$address = $appliance->notification->email_accounts_address($index);
		$appliance->notification->email_account_delete($index);
		$appliance->notification->commit;
		$c->stash->{'box_status'}->{'success'} = 'del_success';
	} else {
		$c->stash->{'box_status'}->{'custom_error'} = 'system_notifications_list_del_error';
	}

	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = 1;
}

sub edit : Local {
	my ($self, $c, $index) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'edit_mode'} = 1;
	$c->stash->{'edit_index'} = $index;
	$c->stash->{'edit_name'} = $appliance->notification->email_accounts_name($index);
	$c->stash->{'edit_email'} = $appliance->notification->email_accounts_address($index);
	$c->stash->{'edit_type'} = $appliance->notification->email_accounts_type($index);
	$c->stash->{'edit_login'} = $appliance->notification->email_accounts_smtp_login($index);
	$c->stash->{'edit_password'} = $appliance->notification->email_accounts_smtp_password($index);
	$c->stash->{'edit_smtpsrv'} = $appliance->notification->email_accounts_smtp_server($index);
	$c->stash->{'edit_usetls'} = $appliance->notification->email_accounts_smtp_use_ssl($index);

	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = 1;
}


1;

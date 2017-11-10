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


package LimesGUI::Controller::Admin::System::User;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;

use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Log;


sub index : Private {
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    $c->stash->{template} = 'admin/system/user.tt2';
}

sub error {
	my ($c, $E) = @_;
	$c->session->{'exception'} = $E;
	$c->stash->{'redirect_url'} = $c->uri_for('/error');
	$c->stash->{'template'} = 'redirect.inc.tt2';
}

sub change_password : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(username pw_current pw_new pw_new_verify)],
		constraint_methods => {
			pw_current    => [{ constraint_method => password_valid($c), params => [qw(username pw_current)], }],
			pw_new        => [{ constraint_method => newpass_valid(),    params => [qw(pw_new pw_new_verify)], }],
			pw_new_verify => [{ constraint_method => newpass_secure(),   params => [qw(pw_new)], }],
		},

		msgs => {
			constraints => {
				'password_valid' => 'error_password_invalid',
				'newpass_valid'  => 'error_newpass_nomatch',
				'newpass_secure' => 'error_newpass_insecure',
			},
			login => $c->login
		}
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()) {
		try {
			my ($user, $pw) = ($c->req->param('username'), $c->req->param('pw_new'));

			$appliance->system->set_user_password($user, $pw);
			$appliance->system->commit;

			$c->stash->{'box_status'}->{'success'} = 'success';
			$c->stash->{'loggedinuser'} = $c->session->{'username'};

			$c->delete_session('password change') if $user eq $c->session->{'username'};
			aslog "info", "Changed password for user $user";
		} catch Underground8::Exception with {
			aslog "warn", "Error changing password, caught exception";
			error($c, shift);
		};
	}

	$c->stash->{'system'} = $appliance->system;
	$c->stash->{'template'} = 'admin/system/user/pw_gui.inc.tt2';
}

sub password_valid {
	my $c = shift;
	my $login_sub = sub{$c->login(@_)}; # create anonymous sub ref

	return sub {
		my ($dfv, $username, $password) = (shift, shift, shift);

		$dfv->name_this('password_valid');
		my $valid = &$login_sub($username,$password);
		return $valid;
	}
}

sub newpass_valid {
	return sub {
		my ($dfv, $newpassword1, $newpassword2) = (shift, shift, shift);

		$dfv->name_this('newpass_valid');
		return ($newpassword1 eq $newpassword2 ? 1 : 0);
   }
}

sub newpass_secure {
	return sub {
		my ($dfv, $newpassword) = (shift, shift);
		$dfv->name_this('newpass_secure');

		if((length($newpassword) >= 8) && ($newpassword =~ /.*[\Q!@%-_.:,;#+*\E].*/) && ($newpassword =~ /.*[0-9].*/)) {
			return 1
		} else {
			return 0;
		}
	}
}




1;

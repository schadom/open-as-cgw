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


package LimesGUI::Controller::Admin::Modules::Email_Encryption;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Log;


sub index : Private {
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};
	my $config = $appliance->system->smtpcrypt_loadconfig;

    $c->stash->{template} = 'admin/modules/email_encryption.tt2';
	update_stash($self, $c);
}


sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'ctrl_cryptotag'}  = $appliance->system->smtpcrypt->get_cryptotag;
	$c->stash->{'ctrl_packtype'}   = $appliance->system->smtpcrypt->get_packtype;
	$c->stash->{'ctrl_enctype'}    = $appliance->system->smtpcrypt->get_pwhandling;
	$c->stash->{'ctrl_password'}   = $appliance->system->smtpcrypt->get_presetpw;
	$c->stash->{'ctrl_enabled'}    = $appliance->system->smtpcrypt->get_enabled;
}

sub toggle_status : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		my $isenabled = $appliance->system->smtpcrypt->get_enabled;

		$appliance->system->smtpcrypt->set_enabled( ($isenabled) ? 0 : 1 );
		$appliance->system->smtpcrypt->commit;

		$appliance->antispam->postfix->smtpcrypt($isenabled ? 0 : 1);
		$appliance->antispam->postfix->commit;

		$c->stash->{'ctrl_enabled'} = ($isenabled) ? 0 : 1;
		$c->stash->{'status'}->{'message'} =
			($isenabled) ? "Mail Encryption Engine disabled" : "Mail Encryption Engine enabled";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling BWlist status, caught exception $E";
		push @{$c->stash->{'status'}->{'errors'}}, "Error toggling email encryption status.";
	};

    # $c->stash->{template} = 'admin/modules/email_encryption/control.inc.tt2';
	$c->stash->{'no_wrapper'} = "1";
    $c->stash->{template} = 'admin/modules/email_encryption.tt2';
	update_stash($self, $c);
}


sub global_conf : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	# TODO: validate form
	my $form_profile = {
		required => [qw(id_cryptotag id_packtype id_enctype)],
		optional => [qw(id_password)],
		constraint_methods => {
			id_cryptotag => qr/^[a-zA-Z]{2,10}$/,
			id_packtype => qr/(pdf|zip)/,
			id_enctype => qr/(generate_pw|preset_pw)/,
			id_password => qr/(^$|^[a-zA-Z0-9_-]{2,25}$)/,
		}
	};

	my $result = $self->process_form($c, $form_profile);	
	if($result->success()) {	
		try {
			my $smtpcrypt_tag = $c->request->params->{'id_cryptotag'};
			my $smtpcrypt_pt  = $c->request->params->{'id_packtype'};
			my $smtpcrypt_pwh = $c->request->params->{'id_enctype'};
			my $smtpcrypt_pw  = $c->request->params->{'id_password'};

			$appliance->system->smtpcrypt->set_cryptotag( $smtpcrypt_tag );
			$appliance->system->smtpcrypt->set_packtype( $smtpcrypt_pt );
			$appliance->system->smtpcrypt->set_pwhandling( $smtpcrypt_pwh );
			$appliance->system->smtpcrypt->set_presetpw( $smtpcrypt_pw );
			$appliance->system->smtpcrypt->set_enabled( 1 );
			#$appliance->antispam->postfix->set_smtpcrypt_cryptotag( $smtpcrypt_tag );

			$appliance->system->smtpcrypt->commit;
			$appliance->antispam->postfix->commit;

			$c->stash->{'ctrl_cryptotag'} = $smtpcrypt_tag;
			$c->stash->{'ctrl_packtype'}  = $smtpcrypt_pt;
			$c->stash->{'ctrl_enctype'}   = $smtpcrypt_pwh;
			$c->stash->{'ctrl_password'}  = $smtpcrypt_pw;
			$c->stash->{'ctrl_enabled'}  = 1;

			# $c->stash->{'status'}->{'message'} = $c->localize('smtpcrypt_status_setglobals');
			$c->stash->{'box_status'}->{'success'} = "success";
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting smtpcrypt global settings, caught exception $E";
			push @{$c->stash->{'status'}->{'errors'}}, "Some error occured.";
		};
	}

	$c->stash->{'system'} = $appliance->system;
    # $c->stash->{template} = 'admin/modules/email_encryption.tt2';
    $c->stash->{template} = 'admin/modules/email_encryption/control.inc.tt2';
	# update_stash($self, $c);
}



1;

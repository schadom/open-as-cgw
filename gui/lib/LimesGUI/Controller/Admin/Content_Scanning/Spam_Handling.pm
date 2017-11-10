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


package LimesGUI::Controller::Admin::Content_Scanning::Spam_Handling;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Error qw(:try);
use Underground8::Exception;
use Underground8::Log;
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Data::Dumper;

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	update_stash($self, $c);
	$c->stash->{template} = 'admin/content_scanning/spam_handling.tt2';
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
		
	$c->stash->{'default'}     = $appliance->antispam->amavis->score_map->{DEFAULT};
	$c->stash->{'smtpauth'}    = $appliance->antispam->amavis->score_map->{SMTPAUTH};
	$c->stash->{'relayhosts'}  = $appliance->antispam->amavis->score_map->{RELAYHOSTS};
	$c->stash->{'whitelist'}   = $appliance->antispam->amavis->score_map->{WHITELIST};
	$c->stash->{'defaultqon'}  = $appliance->antispam->amavis->score_map->{DEFAULTQON};
	$c->stash->{'defaultqoff'} = $appliance->antispam->amavis->score_map->{DEFAULTQOFF};

	$c->stash->{'quarantine_enabled'} = $appliance->antispam->get_mails_destiny->{'spam_destiny'};
}


sub save_matrix : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(default defaultqon defaultqoff relayhosts smtpauth whitelist)],
	};

	my @order = qw(tag block cutoff dsn);
	my @default     = $c->req->params->{'default'};
	my @defaultqon  = $c->req->params->{'defaultqon'};
	my @defaultqoff = $c->req->params->{'defaultqoff'};
	my @smtpauth    = $c->req->params->{'smtpauth'};
	my @whitelist   = $c->req->params->{'whitelist'};
	my @relayhosts  = $c->req->params->{'relayhosts'};


	my $invalid = 0;
	# Yes, i know we have constraint subs. No, i do not use them here. Period.
	for (0..$#order) { $invalid++ if $default[0][$_]     !~ /^\d?\d(\.\d)?$/; }
	for (0..$#order) { $invalid++ if $defaultqon[0][$_]  !~ /^\d?\d(\.\d)?$/; }
	for (0..$#order) { $invalid++ if $defaultqoff[0][$_] !~ /^\d?\d(\.\d)?$/; }
	for (0..$#order) { $invalid++ if $smtpauth[0][$_]    !~ /^\d?\d(\.\d)?$/; }
	for (0..$#order) { $invalid++ if $whitelist[0][$_]   !~ /^\d?\d(\.\d)?$/; }
	for (0..$#order) { $invalid++ if $relayhosts[0][$_]  !~ /^\d?\d(\.\d)?$/; }

	my $result = $self->process_form($c, $form_profile);
	if ($result->success() && !$invalid) {
		try {
			for (0..$#order) { $appliance->antispam->set_score("DEFAULT",     $order[$_], $default[0][$_]); }
			for (0..$#order) { $appliance->antispam->set_score("DEFAULTQON",  $order[$_], $defaultqon[0][$_]); }
			for (0..$#order) { $appliance->antispam->set_score("DEFAULTQOFF", $order[$_], $defaultqoff[0][$_]); }
			for (0..$#order) { $appliance->antispam->set_score("SMTPAUTH",    $order[$_], $smtpauth[0][$_]); }
			for (0..$#order) { $appliance->antispam->set_score("WHITELIST",   $order[$_], $whitelist[0][$_]); }
			for (0..$#order) { $appliance->antispam->set_score("RELAYHOSTS",  $order[$_], $relayhosts[0][$_]); }

			$appliance->antispam->commit;
			aslog "info", "Saved new spam handling matrix (score-matrix) values";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my ( $c, $E ) = @_;
			aslog "warn", "Error saving new spam handling matrix (score-matrix) values, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	} else {
		$c->stash->{'box_status'}->{'custom_error'} = "The score matrix contains $invalid " . ($invalid>1 ? "values":"value") . " with incorrect scoring.";
	}

	update_stash($self, $c);
	$c->stash->{template} = 'admin/content_scanning/spam_handling/matrix.inc.tt2';
}


1;

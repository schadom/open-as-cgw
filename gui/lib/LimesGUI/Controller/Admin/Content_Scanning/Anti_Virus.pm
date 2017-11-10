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


package LimesGUI::Controller::Admin::Content_Scanning::Anti_Virus;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Exception;
use Underground8::Log;
use strict;
use warnings;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/content_scanning/anti_virus.tt2';
	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'clamav'} = $appliance->antispam->clamav();

	$c->stash->{'clamav_enabled'} = $appliance->antispam->clamav_enabled();

	$c->stash->{'unchecked_tag'} = $appliance->antispam->unchecked_subject_tag;
	$c->stash->{'recursion_level'} = $appliance->antispam->archive_recursion;
	$c->stash->{'max_archive_files'} = $appliance->antispam->archive_maxfiles;
	$c->stash->{'max_archive_size'} = $appliance->antispam->archive_maxfilesize;
}

sub toggle_scanner : Local {
	my ( $self, $c, $av_engine ) = @_;
	my $appliance = $c->config->{'appliance'};
	my $status_msg;

	try {
		if($av_engine eq "clamav") {
			$appliance->antispam->clamav_enabled
				? $appliance->antispam->disable_clamav()
				: $appliance->antispam->enable_clamav();
		}

		$appliance->antispam->commit;
		aslog "info", "Toggled AV-engine $av_engine state";
		$c->stash->{'box_status'}->{'success'} = "success";
	} catch Underground8::Exception with {
		my $E = shift;
		aslog "warn", "Error toggling AV-engine state for $av_engine, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};


	$c->stash->{template} = 'admin/content_scanning/anti_virus/scanners.inc.tt2';
	update_stash($self, $c);
}

sub change_options : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(recursion_level unchecked_tag max_archive_files max_archive_size)],
		constraints => {
			unchecked_tag => qr/^[\s\w\*\+#\?=\(\)%\$\!-\{\}]{4,30}$/,
			recursion_level => qr/^\d{1,3}$/,
			max_archive_files => qr/^\d{1,6}$/,
			max_archive_size => qr/^\d{1,5}$/,
		},
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $unchecked_tag = $c->req->param('unchecked_tag');
			my $recursion_level = $c->req->param('recursion_level');
			my $max_archive_files = $c->req->param('max_archive_files');
			my $max_archive_size = $c->req->param('max_archive_size');

			$appliance->antispam->set_unchecked_subject_tag( $unchecked_tag );
			$appliance->antispam->set_archive_recursion( $recursion_level );
			$appliance->antispam->set_archive_maxfiles( $max_archive_files );
			$appliance->antispam->set_archive_maxfilesize( $max_archive_size );

			$appliance->antispam->commit;
			aslog "info", "Changed archive scanning options (tag=$unchecked_tag, reclev=$recursion_level, maxfiles=$max_archive_files, maxsize=$max_archive_size)";
			$c->stash->{'box_status'}->{'success'} = "success";
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error setting archive scanning options, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{template} = 'admin/content_scanning/anti_virus/options.inc.tt2';
	update_stash($self, $c);
}

1;

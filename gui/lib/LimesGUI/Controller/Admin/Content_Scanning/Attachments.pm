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


package LimesGUI::Controller::Admin::Content_Scanning::Attachments;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Underground8::Exception;
use Underground8::Log;
use Data::Dumper;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam;
	$c->stash->{'template'} = 'admin/content_scanning/attachments.tt2';

	$c->stash->{'banned_attachments'} = $appliance->antispam->banned_attachments();
	$c->stash->{'banned_attachments_groups_items'} = $appliance->antispam->attachments_groups();

	my @ba_groups = $appliance->antispam->banned_attachments_groups();
	$c->stash->{'banned_attachments_groups'} = \@ba_groups;
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my @ba_groups = $appliance->antispam->banned_attachments_groups();
	$c->stash->{'banned_attachments_groups'} = \@ba_groups;
	$c->stash->{'banned_attachments'} = $appliance->antispam->banned_attachments();
	$c->stash->{'banned_attachments_groups_items'} = $appliance->antispam->attachments_groups();

	$c->stash->{'antispam'} = $c->config->{'appliance'}->antispam;
	$c->stash->{'template'} = 'admin/content_scanning/attachments.tt2';
	$c->stash->{'no_wrapper'} = '1';

}

sub error {
	my ( $c, $E ) = @_;
	aslog "warn", "Caught exception $E";
	$c->session->{'exception'} = $E;
	$c->stash->{'redirect_url'} = $c->uri_for('/error');
	$c->stash->{'template'} = 'redirect.inc.tt2';
}


sub toggle_warn_virus : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		if ($appliance->antispam->warn_recipient_virus() == 1) {
			$appliance->antispam->disable_warn_recipient_virus();
			$c->stash->{'box_status'}->{'success'} = 'virus_disabled';
		} elsif($appliance->antispam->warn_recipient_virus() == 0) {
			$appliance->antispam->enable_warn_recipient_virus();
			$c->stash->{'box_status'}->{'success'} = 'virus_enabled';
		}
		$appliance->antispam->commit();
		aslog "info", "Toggled warn_on_virus";
	} catch Underground8::Exception with {
		aslog "warn", "Error toggling warn_on_virus";
		error($c, shift);
	};

	$c->stash->{'antispam'} = $appliance->antispam;
	$c->stash->{'template'} = 'admin/content_scanning/attachments/warnings.inc.tt2';
}


sub toggle_warn_banned : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		if ($appliance->antispam->warn_recipient_banned_file() == 1) {
			$appliance->antispam->disable_warn_recipient_banned_file();
			$c->stash->{'box_status'}->{'success'} = 'banned_disabled';
		} elsif($appliance->antispam->warn_recipient_banned_file() == 0) {
			$appliance->antispam->enable_warn_recipient_banned_file();
			$c->stash->{'box_status'}->{'success'} = 'banned_enabled';
		}

		$appliance->antispam->commit();
		aslog "info", "Toggling warn_on_banned";
	} catch Underground8::Exception with {
		aslog "warn", "Error toggling warn_on_banned";
		my $E = shift;
		$c->log->debug("banned exception");
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};
	
	$c->stash->{'antispam'} = $appliance->antispam;
	$c->stash->{'template'} = 'admin/content_scanning/attachments/warnings.inc.tt2';
}

sub enlist_extension : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	
	my $form_profile = {
		required => [qw(extension desc)],
		constraint_methods => {
			extension => qr/^[a-zA-Z0-9]{1,20}$/,
			desc => qr/^[a-zA-Z0-9 ]{1,30}$/
		}
	};
	
	my $result = $self->process_form($c, $form_profile);
	if ($result->success()) {
		try {
			my $banned_attachment = $c->request->params->{'extension'};
			my $description = $c->request->params->{'desc'};

			$appliance->antispam->add_banned_attachments($banned_attachment,$description);
			$appliance->antispam->commit();

			aslog "info", "Added attachment blocking rule (filext) $description for $banned_attachment";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception::EntryExists with {
			aslog "warn", "Error adding attachment blocking rule (filext): Entry exists";
			$c->stash->{'box_status'}->{'custom_error'} = 'content_scanning_attachments_block_mime_types_error_entry_exists';
		} catch Underground8::Exception with {
			aslog "warn", "Error adding attachment blocking rule (filext)";
			$c->stash->{'box_status'}->{'custom_error'} = 'content_scanning_attachments_block_mime_types_error_entry_exists';
			#error($c, shift);
		};
	}

	update_stash($self, $c);
}


sub enlist_contenttype : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $ct_description = "Blocked Content-Type";
	
	try { 
		my @content_types = $c->req->param('content_types');
		my $banned_att = $appliance->antispam->banned_attachments();

		# Block newly added CTs
		foreach my $ctype (@content_types) {
			my $inlist = 0;
			foreach my $banned (@$banned_att) {
				if($banned->{'banned'} eq $ctype) { $inlist = 1; last; }
			}

			next if $inlist;
			$appliance->antispam->add_banned_attachments($ctype, $ct_description);
		}

		# Unblock newly deleted CTs
		foreach my $banned (@$banned_att) {
			next if $banned->{'description'} ne $ct_description;

			my $inlist = 0;
			foreach my $ctype (@content_types) {
				if($banned->{'banned'} eq $ctype) { $inlist = 1; last }
			}

			next if $inlist;
			$appliance->antispam->del_banned_attachment($banned->{'banned'});
		}

		$appliance->antispam->commit();
		aslog "info", "Updated attachment blocking rule-table (mime)";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception::EntryExists with {
		aslog "warn", "Error updating attachment blocking rule-table (mime): Entry exists";
		$c->stash->{'box_status'}->{'custom_error'} = 'content_scanning_attachments_block_mime_types_error_entry_exists';
	} catch Underground8::Exception with {
		aslog "warn", "Error updating attachment blocking rule-table (mime)";
		error($c, shift);
	};

	update_stash($self, $c);
	$c->stash->{'template'} = 'admin/content_scanning/attachments.tt2';
}

sub enlist_grouptypes : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my $gt_description = "Blocked Filegroup-Type";

	my @group_types = $c->req->param('group_list');
	my $banned_att = $appliance->antispam->banned_attachments();

	try {
		# Block newly added GTs
		foreach my $gtype (@group_types) {
			my $inlist = 0;
			foreach my $banned (@$banned_att) {
				if($banned->{'banned'} eq $gtype) { $inlist = 1; last; }
			}

			next if $inlist;
			$appliance->antispam->add_banned_attachments($gtype, $gt_description);
		}

		# Unblock newly deleted GTs
		foreach my $banned (@$banned_att) {
			next if $banned->{'description'} ne $gt_description;

			my $inlist = 0;
			foreach my $gtype (@group_types) {
				if($banned->{'banned'} eq $gtype) { $inlist = 1; last }
			}

			next if $inlist;
			$appliance->antispam->del_banned_attachment($banned->{'banned'});
		}

		$appliance->antispam->commit();
		aslog "info", "Updated attachment blocking rules table (grouptype)";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception::EntryExists with {
		aslog "warn", "Error updating attachment blocking rule table (gruoptype): Entry exists";
		$c->stash->{'box_status'}->{'custom_error'} = 'content_scanning_attachments_block_group_error_entry_exists';
	} catch Underground8::Exception with {
		aslog "warn", "Error updating attachment blocking rule table (gruoptype)";
		error($c, shift);
	};

	update_stash($self, $c);
	$c->stash->{'template'} = 'admin/content_scanning/attachments.tt2';
}

sub delist : Local {
	my ($self, $c, $id) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->antispam->del_banned_attachment( $id );
		$appliance->antispam->commit;
		
		aslog "info", "Deleted banned attachment $id";
		$c->stash->{'box_status'}->{'success'} = 'success';
	} catch Underground8::Exception::EntryExists with {
		aslog "warn", "Error deleting banned attachment $id: Entry exists";
		$c->stash->{'box_status'}->{'custom_error'} = 'content_scanning_attachments_block_group_error_entry_exists';
	} catch Underground8::Exception with {
		aslog "warn", "Error deleting banned attachment $id";
		error($c, shift);
	};

	update_stash($self, $c);
}

1;

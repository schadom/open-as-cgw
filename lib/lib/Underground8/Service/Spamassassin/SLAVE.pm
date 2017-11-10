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


package Underground8::Service::Spamassassin::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Error;
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Template;
use Data::Dumper;


sub write_config ($) {
	my $self = shift;
	my $gtube_string = shift;
	my $gtube_score = shift;
	my $languages_allowed = shift;
	my $language_filter_status = shift;


	my $template = Template->new({INCLUDE_PATH=>$g->{'cfg_template_dir'}});
	my $options = {
		gtube_string_cleaned => quotemeta($gtube_string),
		gtube_score => $gtube_score,
		language_filter_status => $language_filter_status,
		languages_allowed => $languages_allowed,
	};

	my $config_content;
	$template->process($g->{'template_spamassassin_local_cf'},$options,\$config_content)
		or throw Underground8::Exception($template->error);

	open(SPAMASSASSIN_GTUBE,'>',$g->{'file_spamassassin_local_cf'})
		or throw Underground8::Exception::FileOpen($g->{'file_spamassassin_local_cf'});

	print SPAMASSASSIN_GTUBE $config_content;

	close SPAMASSASSIN_GTUBE;
}

sub write_value($$);

sub read_config ();

sub read_value($);

1;


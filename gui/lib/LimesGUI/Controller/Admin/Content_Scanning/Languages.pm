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


package LimesGUI::Controller::Admin::Content_Scanning::Languages;

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

my %langs = (
	"af" => "Afrikaans",  "sq" => "Albanian",   "am" => "Amharic",    "ar" => "Arabic",      "hy" => "Armenian",
	"eu" => "Basque",     "bs" => "Bosnian",    "bg" => "Bulgarian",  "be" => "Belorussian", "ca" => "Catalan",
	"zh" => "Chinese",    "hr" => "Croatian",   "cs" => "Czech",      "da" => "Danish",      "nl" => "Dutch",
	"en" => "English",    "eo" => "Esperanto",  "et" => "Estonian",   "fi" => "Finnish",     "fr" => "Frensh",
	"fy" => "Frisian",    "ka" => "Georgian",   "de" => "German",     "el" => "Greek",       "he" => "Hebrew",
	"hu" => "Hungarian",  "hi" => "Hindi",      "is" => "Icelandic",  "id" => "Indonesian",  "ga" => "Irish Gaelic",
	"it" => "Italian",    "ja" => "Japanese",   "ko" => "Korean",     "la" => "Latin",       "lv" => "Latvian",
	"lt" => "Lithuanian", "ms" => "Malay",      "mr" => "Marathi",    "ne" => "Nepali",      "no" => "Norwegian",
	"fa" => "Persian",    "pl" => "Polish",     "pt" => "Portuguese", "qu" => "Quechua",     "rm" => "Rhaeto-Romance",
	"ro" => "Romanian",   "ru" => "Russian",    "sa" => "Sanskrit",   "sco"=> "Scots",       "gd" => "Scottish Gaelic",
	"sr" => "Serbian",    "sk" => "Slovak",     "sl" => "Slovenian",  "es" => "Spanish",     "sw" => "Swahili",
	"sv" => "Swedish",    "tl" => "Tagalog",    "ta" => "Tamil",      "th" => "Thai",        "tr" => "Turkish",
	"uk" => "Ukrainian",  "vi" => "Vietnamese", "cy" => "Welsh",      "yi" => "Yiddish",
);

sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/content_scanning/languages.tt2';
	update_stash($self, $c);
}

sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my @lang_allowed = split(/ /, $appliance->antispam->get_allowed_languages());
	$c->stash->{'languages_allowed'} = \@lang_allowed;
	$c->stash->{'language_filter_status'} = $appliance->antispam->get_language_filter_status();
	$c->stash->{'langs'} = \%langs;
}

sub save_language_prefs : Local {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	my $form_profile = {
		required => [qw(langs)],
		constraints => { },
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my @allowed_langs = $c->req->param('langs');
			$appliance->antispam->set_allowed_languages( join(" ", @allowed_langs) );
			$appliance->antispam->commit();

			aslog "info", "Set allowed languages to: " . join(" ", @allowed_langs);
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my ( $c, $E ) = @_;
			aslog "warn", "Error saving language filter prefs, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	$c->stash->{template} = 'admin/content_scanning/languages/language_filter.inc.tt2';
	update_stash($self, $c);
}

sub toggle_language_filter : Local {
	my ( $self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		($appliance->antispam->get_language_filter_status eq "enabled")
			? $appliance->antispam->disable_language_filter()
			: $appliance->antispam->enable_language_filter();

		$appliance->antispam->commit();
		aslog "info", "Language filter status has been altered, is now" . $appliance->antispam->get_language_filter_status();
	} catch Underground8::Exception with {
		my ( $c, $E ) = @_;
		aslog "warn", "Error toggling language filter status, caught exception $E";
		$c->session->{'exception'} = $E;
		$c->stash->{'redirect_url'} = $c->uri_for('/error');
		$c->stash->{'template'} = 'redirect.inc.tt2';
	};

	$c->stash->{template} = 'admin/content_scanning/languages/language_filter.inc.tt2';
	update_stash($self, $c);
}

1;

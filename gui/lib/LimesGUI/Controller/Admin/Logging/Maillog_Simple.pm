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


package LimesGUI::Controller::Admin::Logging::Maillog_Simple;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Date::Format;
use Time::Local;
use LWP::UserAgent;
use Underground8::Utils;
use Underground8::Log;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::FormValidator::Constraints::Underground8;
use Data::Dumper;
use Underground8::Exception;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};


	$c->stash->{template} = 'admin/logging/maillog_simple.tt2';
	update_stash($self, $c);
}


sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	my %stats = $appliance->report->simple_maillog_stats();
	
	my @log_range;
	my $log = $g->{"mailsimple_log"};
	my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

	my ($max_year, $min_year) = ( $stats{ @{$stats{files}}[0] }{last_date_y}, $stats{ @{$stats{files}}[-1] }{first_date_y} );
	my ($current_year, $current_month) = ( (localtime())[5] + 1900, (localtime())[4] + 1);

	my $max_date = sprintf("$current_year%02d", $current_month);
	my $min_date = $stats{ @{$stats{files}}[-1] }{first_date_y} . $stats{@{$stats{files}}[-1]}{first_date_m};


	for my $year ($min_year..$max_year) {
		my $month_numeric = 0;
		foreach my $month_text (@months) {
			$month_numeric++;
			my $val = sprintf("$year%02d", $month_numeric);
			push @log_range, { label => "$month_text $year", value => $val } if ($val <= $max_date && $val >= $min_date);
		}
	}

	$c->stash->{"log_range"} = \@log_range;
}

sub search : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my %stats = $appliance->report->simple_maillog_stats();
	$c->stash->{template} = 'admin/logging/maillog_simple/search.inc.tt2';
	my $maxlines = 4000;

	my $form_profile = {
		required => [qw(from to pattern yield)],
		optional => [qw(ignore_case reverse)],
		constraints => {
			from => qr/^\d{6}$/,
			to => [qr/^\d{6}$/,{
				constraint_method => $self->verify_interval(),
				params => [qw/from to/]
			}],
			pattern => qr/^.+$/,
		},
	};


	my %yield_map = ( 
		"all" => "", 
		"relayed" => "RELAYED", 
		"accepted" => "ACCEPTED", 
		"greylist" => "GREYLISTED",
		"blacklist" => "BLACKLISTED", 
		"spam" => "SPAM", 
		"virus" => "VIRUS", 
		"banned" => "BANNED_ATT"
	);

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $from = $c->req->param('from');
			my $to= $c->req->param('to');
			my $pattern = $c->req->param('pattern');
			my $yield = $c->req->param('yield');
			my $ignore_case = $c->req->param('ignore_case') == "1" ? 1 : 0;
			my $reverse = $c->req->param('reverse') == "1" ? 1 : 0;

			$from =~ /^(\d\d\d\d)(\d\d)$/;
			my ($from_year, $from_mon) = ($1, $2);

			$to =~ /^(\d\d\d\d)(\d\d)$/;
			my ($to_year, $to_mon) = ($1, $2);

			# Determine the exact search interval
			my @interpolated_dates;
			foreach my $y ($from_year..$to_year) {
				if($from_year == $to_year) {
					push @interpolated_dates, sprintf("$y%02d", $_) foreach ($from_mon..$to_mon);
					last;
				}

				if($y == $from_year) {
					push @interpolated_dates, sprintf("$y%02d", $_) foreach ($from_mon..12);
					next;
				}

				if($y == $to_year) {
					push @interpolated_dates, sprintf("$y%02d", $_) foreach (1..$to_mon);
					last;
				}

				push @interpolated_dates, { year => $y, mon => $_} foreach (1..12);
			}

			my @result;

			# Deny jailbreak
			$pattern =~ s/'/\\'/;

			# Actual search routine (sanitizing pattern before)
			my $grep = "/bin/grep";
			$grep .= " -i" if $ignore_case;

			my $yielding = ($yield_map{$yield}) ? " | grep mail-status=".$yield_map{$yield} : "";

			my @files = @{ $stats{files} };
			for my $file (@files) {
				my $cat = ($file =~ /\.gz$/) ? "/bin/zcat" : "/bin/cat";
				for (@interpolated_dates){
					next unless $_ >= sprintf($stats{$file}{"first_date_y"}."%02d", $stats{$file}{"first_date_m"}) && 
								$_ <= sprintf($stats{$file}{"last_date_y"}."%02d",  $stats{$file}{"last_date_m"});

					/^(....)(..)/;
					my $month_in_current_file = "$1-$2";
					unshift @result, `$cat $file | $grep '$pattern' $yielding | $grep $month_in_current_file`;
				}

				# Give up if result has too many entries
				if(scalar(@result) > $maxlines) {
					$c->stash->{'box_status'}->{'custom_error'} = 'logging_maillog_simple_search_error_toomanylines';
					aslog "warn", "Error searching simple-maillog: Too many lines (". scalar(@result) .")";
					update_stash($self, $c);
					return;
				}
			}

			# Error msg if result is empty
			if(scalar(@result) == 0) {
				$c->stash->{'box_status'}->{'custom_error'} = 'logging_maillog_simple_search_error_nolines';
				aslog "warn", "Error searching simple-maillog: No matches";
				update_stash($self, $c);
				return;
			}

			# Make output a little bit nicer
			map { $_ =~ s/^(\d{4}-\d\d-\d\d)T(\d\d:\d\d:\d\d)\+\d\d:\d\d.+mail-status=(.+?)(<.*)/$1 $2 $3 $4/g } @result;
			map { $_ =~ s/^(.+), timestamp=.+?(,.+)$/$1$2/g } @result;

			my @aresult;
			foreach(@result){
				/^(....-..-.. ..:..:..) (.+?) <(.+?)> -> <(.+?)>/;
				my ($ts, $decision, $from, $to) = ($1, $2, $3, $4);

				my $qnr = "(Unqueued)";
				if(/queuenr/) {
					/queuenr=(.+?),/;
					$qnr = $1;
				}

				my $subject = "-";
				if(/subject/){
					/subject=<(.+?)>$/;
					$subject = $1;
				}

				push @aresult, { ts => $ts, yield => $decision, from => $from, to => $to, qnr => $qnr, subject => $subject };
			}

			$c->stash->{'search_result'} = \@aresult;
			$c->stash->{'reverse_output'} = 1 if $reverse;

			aslog "info", "Simple maillog successfully crawled through";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error searching simple-maillog, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	update_stash($self, $c);
}



sub download {
	my ($c, $url) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(1000);

	my $response = $ua->get(
		$url,
		':content_cb' => sub { my ($data,$resp) = @_; $c->res->write($data);  }
	);
}

sub byteshuman {
	my @m = ('B', 'KB', 'MB', 'GB', 'TB', 'PB');
	my ($self, $n) = @_;
	my $m = 0;

	while($n > 1024 and $m < $#m) {
		$n /= 1024;
		$m++;
	}

	return sprintf('%0.01f %s', $n, $m[$m]);
}

sub verify_interval {
	return sub {
		my ($dfv, $from, $to) = @_;
		$dfv->name_this('verify_interval');
		
		return ($from <= $to) ? 1 : 0;
	}
}


1;

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


package LimesGUI::Controller::Admin::Logging::Log_Viewer;

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
use Underground8::Exception;


sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	$c->stash->{template} = 'admin/logging/log_viewer.tt2';
	update_stash($self, $c);
}


sub update_stash {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};
	
	my $logdir = $c->config->{'home'} . "/root/static/log";
	my ($min_year, $max_year);

	my $command = "/bin/gzip -c " . $g->{'mail_log'} ." > $logdir/mail.log.gz";
	system($command);

	my %logs;
	my @absolute_files = <$logdir/*.gz>;

	foreach my $file (@absolute_files) {
		my @paths = split(/\//, $file);
		my $name = pop @paths;

		if($file =~ qr/mail\.log\-(\d{8})(_v\d+)?\.gz/){
			my ($year, $month, $day) = (substr($1,2,2), substr($1,4,2), substr($1,6,2));
			my $size_human = $self->byteshuman((stat($file))[7]);

			# get available interval of years
			$min_year = $year if $year<$min_year or !defined($min_year);
			$max_year = $year if $year>$max_year or !defined($max_year);

			$logs{$year+2000}{$month}{$day} = $name;
		}

		if($file =~ /\/mail.log.gz$/){
			$c->stash->{'file_today'} = { 
				name => "mail.log.gz", 
				time => ($c->localize('today')), 
				size => ($self->byteshuman((stat($file))[7]))
			};
		}
	}

	my @log_range;
	my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

	for my $year ($min_year+2000..$max_year+2000) {
		my $month_numeric = 0;
		foreach my $month_text (@months) {
			$month_numeric++;
			push @log_range, { label => "$month_text $year", value => sprintf("$year%02d", $month_numeric) } 
				if defined $logs{$year}{ sprintf("%02d", $month_numeric) };
		}
	}

	$c->stash->{'logs'} = \%logs;
	$c->stash->{'log_range'} = \@log_range;
}

sub search : Local {
	my ($self, $c) = @_;
	$c->stash->{template} = 'admin/logging/log_viewer/search.inc.tt2';

	my $form_profile = {
		required => [qw(from to pattern)],
		optional => [qw(use_regex ignore_case reverse)],
		constraints => {
			from => qr/^\d{6}$/,
			to => [qr/^\d{6}$/,{
				constraint_method => $self->verify_interval(),
				params => [qw/from to/]
			}],
			pattern => qr/^.+$/,
		},
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			my $from = $c->req->param('from');
			my $to= $c->req->param('to');
			my $pattern = $c->req->param('pattern');
			my $use_regex = $c->req->param('use_regex') == "1" ? 1 : 0;
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
					push @interpolated_dates, sprintf("$y%02d",$_) foreach ($from_mon..$to_mon);
					last;
				}

				if($y == $from_year) {
					push @interpolated_dates, sprintf("$y%02d", $_) foreach ($from_mon..12);
					#foreach my $m ($from_mon..12){ push @interpolated_dates, sprintf("$y%02d", $m); }
					next;
				}

				if($y == $to_year) {
					foreach my $m (1..$to_mon){ push @interpolated_dates, sprintf("$y%02d", $m); }
					last;
				}

				foreach my $m (1..12){
					push @interpolated_dates, sprintf("$y%02d", $m);
				}
			}

			my $logdir = $c->config->{'home'} . "/root/static/log";
			my @result;


			# Deny jailbreak
			$pattern =~ s/'/\\'/;

			# Escape characters, default-grep would handle as regex-patterns
			if(!$use_regex) { 
				$pattern =~ s/\^/\\\^/;
				$pattern =~ s/\$/\\\$/;
				$pattern =~ s/\[/\\\[/;
				$pattern =~ s/\]/\\\]/;
				$pattern =~ s/\./\\\./;
				$pattern =~ s/\*/\\\*/;
				$pattern =~ s/\?/\\\?/;
			}

			# Actual search routine (sanitizing pattern before)
			my $grep = "/bin/grep";
			foreach my $part (@interpolated_dates) {
				my @files = <$logdir/*$part*.gz>;
				my @hits;

				$grep .= " -E" if $use_regex;
				$grep .= " -i" if $ignore_case;

				foreach my $file (@files) { 
					@hits = `/bin/zcat $file | $grep '$pattern'`;  
					unshift @result, $_ foreach (@hits);
				}

				# Give up if result has too many entries
				if(scalar(@result) > 5000) {
					$c->stash->{'box_status'}->{'custom_error'} = 'logging_log_viewer_search_error_toomanylines';
					aslog "warn", "Error searching logs: Too many lines found (" . scalar(@result) . ")";
					update_stash($self, $c);
					return;
				}
			}

			# Error msg if result is empty
			if(scalar(@result) == 0) {
				$c->stash->{'box_status'}->{'custom_error'} = 'logging_log_viewer_search_error_nolines';
				aslog "warn", "Error searching logs: No lines matched";
				update_stash($self, $c);
				return;
			}

			$c->stash->{'search_result'} = \@result;
			$c->stash->{'reverse_output'} = 1 if $reverse;

			aslog "info", "Successfully searched logfiles (pattern:$pattern, from:$from, to:$to)";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			my $E = shift;
			aslog "warn", "Error searching logs, caught exception $E";
			$c->session->{'exception'} = $E;
			$c->stash->{'redirect_url'} = $c->uri_for('/error');
			$c->stash->{'template'} = 'redirect.inc.tt2';
		};
	}

	update_stash($self, $c);
}


sub logfile : Local {
	my ($self, $c, $logfile) = @_;
	$c->stash->{template} = 'admin/logging/log_viewer.tt2';

	return if $logfile !~ /^mail\.log(-[0-9]{8}(_v\d+)?)?\.gz$/;

	if($logfile eq "mail.log.gz"){
		my $mail_log = $g->{'mail_log'};
		my $log_dir = $c->config->{'home'} . "/" . $g->{'log_dir'};
		my $command = $g->{'cmd_gzip'} . " -c $mail_log > $log_dir/mail.log.gz";
		system($command);
	}
	
	$c->stash->{'template'} = undef;
	$c->res->redirect( $c->uri_for("/static/log/$logfile") );
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

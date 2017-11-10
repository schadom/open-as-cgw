#!/usr/bin/perl
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


BEGIN { 
	my $libpath = $ENV{'LIMESLIB'};
	if($libpath) {	
		print "*** DEVEL ENVIRONMENT ***\nUsing libpath: $libpath\n";
		unshift(@INC,"$libpath/lib/");
	}
	
	if ($ENV{'LIMESGUI'}) {
		push @INC, "$ENV{'LIMESGUI'}/lib";
	} else {
		push @INC, '/var/www/LimesGUI/lib';
	}
}


use strict;
use warnings;

use Underground8::Appliance::LimesAS;
use Underground8::ReportFactory::LimesAS::Mail;
use Underground8::Utils;

use Data::Dumper;
use Template;

# use WrapChartClicker;

use Email::MIME::CreateHTML;

use Net::SMTP::TLS;

use Date::Format;

use LimesGUI::I18N::en;
use LimesGUI::I18N::de;

my $appliance = new Underground8::Appliance::LimesAS;
$appliance->load_config;

my $sn = $appliance->sn;
my $domainname = $appliance->system->domainname;
my $hostname = $appliance->system->hostname;
my $email_sender = "as-cgw\@$hostname.$domainname";

my $recipients = $appliance->notification->email_accounts();
my $nr_recipients = scalar @$recipients;

# if no recipients, do nothing
exit (0) unless ($nr_recipients > 0);

# template object
my $template = Template->new ({
					  INCLUDE_PATH => $g->{'cfg_template_dir'},
});  

# do this before fu**ing the db

my $sysinfo = $appliance->report->advanced_sysinfo;
my $current_timestamp = $appliance->report->mail->current_timestamp;
my $mailstats = $appliance->report->mail->current_stats->current_stats;
my $yesterday = $current_timestamp - 86400;
# my $date_string = time2str("%d.%m.%Y",$yesterday);
my $date_string = time2str("%Y-%m-%d",$yesterday);
my $versions = $appliance->report->versions;
$versions->{'last_update_printable'} = $versions->{'last_update'}->strftime("%Y-%m-%d %H:%M");
$versions->{'time_clamav_printable'} = $versions->{'time_clamav'}->strftime("%Y-%m-%d %H:%M");
$versions->{'product'} = $appliance->{_product};

my $timezone = $appliance->system->timezone->timezone;


my $img_path = $g->{'cfg_template_dir'} . "/email";

my $current_language = $appliance->quarantine->language;
my %selected_language = ();

if (!$current_language || $current_language eq "") {
	$current_language = "en";
}

if ($current_language eq "en") {
	%selected_language = %LimesGUI::I18N::en::quar_tmpl;
} elsif ($current_language eq "de") {
	%selected_language = %LimesGUI::I18N::de::quar_tmpl;
}

my %lics;
$lics{'services'} = avail_lic_services();
$lics{'license_info'} = $appliance->report->license->license_info();
$lics{'license_warn'} = $appliance->report->license->renew_licence_warning();

my $time = time;
my %mailq;
$mailq{'count'} = $appliance->report->mailqueue->{'history'}->{$time}->[0];
$mailq{'size'} = $appliance->report->mailqueue->{'history'}->{$time}->[1];

# Calc *real* mq values .. %mailq is outdated
my $mq_live = $appliance->report->mailqueue_live;;
my $mq_live_cnt = 0;
my $mq_live_size = 0;
foreach my $mq_item (@{$mq_live}){
	$mq_live_size += $mq_item->{'size'};
	$mq_live_cnt++;
}

my $last_backup = "";
my $backups = $appliance->backup->backup_list_encrypted();
if(@$backups >= 1){
	$last_backup = $backups->[-1];
	$last_backup =~ /Backup-(.+?)\.crypt/;
	$last_backup = $1;
}

my $options = {
	img_path => $img_path,
	hostname => $hostname,
	domainname => $domainname,
	sysinfo => $sysinfo,
	mailstats => $mailstats,
	sn => $sn,
	date_string => $date_string,
	language_strings => \%selected_language,
	lics => \%lics,
	versions => $versions,
	mailq => \%mailq,
	last_backup => $last_backup,
	mq_live_size => $mq_live_size,
	mq_live_cnt => $mq_live_cnt,
};

my ($plain, $html);
$template->process($g->{'template_email_daily_spam_report_plain'}, $options, \$plain);
$template->process($g->{'template_email_daily_spam_report_html'},  $options, \$html);

if(defined $ARGV[0]){
	print "NOT sending emails.. dumpding instead";

	print " ***** HTML\n";
	#print Dumper($html);

	print " ***** PLAIN\n";
	print Dumper($plain);

	#print Dumper($sysinfo);
	#print Dumper($mailstats);
	#print Dumper(%lics);
	#print Dumper(%mailq);
	#print Dumper(\$last_backup);
	# exit 1;
}

foreach my $recipient_hash (@$recipients) {
	my $name = $recipient_hash->{'_name'};
	my $address = $recipient_hash->{'_address'};
	my $smtp_server = $recipient_hash->{'_smtp_server'} || 'localhost';
	my $smtp_login = $recipient_hash->{'_smtp_login'};
	my $smtp_password = $recipient_hash->{'_smtp_password'};
	my $smtp_use_ssl = $recipient_hash->{'_smtp_use_ssl'};

	my $recipient = $name ? "$name <$address>" : "<$address>"; 

	my $email = Email::MIME->create_html(
		header => [
			From => "AS Communication Gateway <$email_sender> ($hostname.$domainname)",
			To => $recipient,
			Subject => "AS Communication Gateway Daily Report $date_string",
		],
		body => $html,
		text_body => $plain,
	);

	my @mailer_options = (
		Hello => "$hostname.$domainname",
	);

	push @mailer_options, 'NoTLS' => 1 if $smtp_use_ssl == 0;
	push @mailer_options, 'User' => $smtp_login if $smtp_login;
	push @mailer_options, 'Password' => $smtp_password if $smtp_password;
	my @message = split(/\n/,$email->as_string);

	my $mailer = new Net::SMTP::TLS($smtp_server,@mailer_options);
	$mailer->mail($email_sender);
	$mailer->to($address);
	$mailer->data;

	foreach my $line (@message) {
		$mailer->datasend("$line\n");
	}

	$mailer->dataend();
	$mailer->quit(); 
}


sub render {
	my $message = shift;
	my $length = shift;
	$message = substr($message, 0, ($length - 2)) if ($length < (length $message));
	return " $message" . (" " x ($length - (length $message) - 1));
}

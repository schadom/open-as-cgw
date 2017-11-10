#!/usr/bin/perl -w
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


# quarantine-cron - functions used by quarantine cron like
# sending self-confirmation notifications, quarantine cleanup, ...
#
# 09/12/2008 - Created by Andreas Starlinger

# check for development environment
BEGIN
{
    my $libpath = $ENV{'LIMESLIB'};
    if ($libpath)
    {
        print STDERR "*** DEVEL ENVIRONMENT ***\nUsing lib-path: $libpath\n";
        unshift(@INC,"$libpath/lib/");
    }
}

### usings

use Underground8::QuarantineNG::Common;
use Underground8::QuarantineNG::Base;

use Underground8::Exception; 
use Underground8::Exception::Execution;  
use Underground8::Appliance::LimesAS; 
use Underground8::Utils;

use Data::Dumper;
use POSIX;
use Pod::Usage;
use Getopt::Long;
use Schedule::Cron; # libschedule-cron-perl

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

use strict;
use warnings;

### variables

my $help = 0;
my $config_file = "quarantine.lock";
my $config_path = "/var/quarantine";

### main

GetOptions ('help|h|?' => \$help,
            'debug!' => \$debug,
);

# check program uid for root permissions
if ($> != 0)
{
    print STDERR "\nThis program must be executed with root privileges!\n\n";
    exit(0);
}

# print usage text
if ($help)
{
    pod2usage(1);
    exit(0);
}

# debug output or daemonize process
if ($debug)
{
    print STDERR "Starting up in debugging mode ...\n";
}

# daemonize if not in debugging mode
if (!$debug)
{
    daemonize("/var/run/openas-qcron.pid");
}

my $config = read_quarantine_config();

# not for now, everything is working in case of deactivation, but maybe in near future this is needed
#if ($config->{'quarantine_enabled'})
#{

    my $notify_unconfirmees_interval = $config->{'notify_unconfirmees_interval'};
    my $send_spamreport_interval = $config->{'send_spamreport_interval'};
    my $cleanup_interval = $config->{'cleanup_interval'};
    my $cleanup_old_interval = $config->{'cleanup_old_interval'};
    my $timeout_interval = $config->{'timeout_interval'};
    my $disk_space_interval = $config->{'disk_space_interval'};

    # Create new object with default dispatcher
    my $cron = new Schedule::Cron(\&dispatcher, nofork => 1, skip => 1, catch => 1, processprefix => "openas-qcron");

    # Add dynamically crontab entries

if ($config->{'quarantine_enabled'}) 
{ 
    if ($config->{'send_notifications'})
    {
        # notify unconfirmees
        $cron->add_entry($notify_unconfirmees_interval,\&notify_unconfirmees, $config);
    } 

    if ($config->{'send_spamreports'})
    {
        # send spam report
        $cron->add_entry($send_spamreport_interval,\&send_all_reports, $config);
    }
    
    # do cleanups
    $cron->add_entry($cleanup_interval,\&cleanup_releases_deletions, $config);
    $cron->add_entry($cleanup_old_interval,\&cleanup_old_quarantines, $config);

    #if ($config->{'send_notifications'})
    #{
        $cron->add_entry($cleanup_interval,\&cleanup_unconfirmees, $config);
        $cron->add_entry($cleanup_interval,\&cleanup_old_unconfirmed_quarantines, $config);    
    #}

    # set timeouts
    $cron->add_entry($timeout_interval,\&set_timeouts, $config);
}   
    # check disk space
    $cron->add_entry($disk_space_interval,\&disk_space_controller);


    # Run scheduler 
    $cron->run();

    base_destroy();

#}

### subs

# default cron routine
sub dispatcher
{ 
  log_message("debug", "ID:   ",shift); 
  log_message("debug", "Args: ","@_");
}

# function that checks for sufficient disk space and disables quarantine globally in case of running out of space
sub disk_space_controller
{

    my $hostname = `hostname -f`;
    chomp($hostname);

    log_message("debug", "running disk space check");

    my $quarantine_lock = read_quarantine_config($config_file, $config_path);
    my $config_set_soft = $quarantine_lock->{'soft'};
    my $config_set_hard = $quarantine_lock->{'hard'};

    # product specific space limits
    my %product_limits = (
        'HXX'  => { 'soft' => '40960', 'hard' => '51200'},
    );

    my $product_type = "HXX";
    my $hard_limit = $product_limits{$product_type}->{'hard'};
    my $soft_limit = $product_limits{$product_type}->{'soft'};

    my $used_space = check_disk_space($config->{'quarantine_path'});

    log_message("debug", "used-space: $used_space"); 

    if (!$config_set_soft && !$config_set_hard && $used_space > $soft_limit && $used_space < $hard_limit)
    {
        write_config($config_path, $config_file, "soft", "1");
        notify_admin("ATTENTION: disk space soft limit of $soft_limit MB is reached ($hostname)!", "Please remove old quarantined messages, in case of the hard limit of $hard_limit MB is reached the quarantine will be automatically disabled!");
        log_message("info", "quarantine soft limit reached");
    }

    if (!$config_set_hard && $used_space >= $hard_limit)
    {
        write_config($config_path, $config_file, "hard", "1");
        log_message("info", "quarantine hard limit reached");

        my $appliance = new Underground8::Appliance::LimesAS;
        $appliance->load_config();
        my $state = $appliance->quarantine->quarantine_enabled();
        if ($state)
        {
            notify_admin("ATTENTION: disk space hard limit of $hard_limit MB is reached ($hostname)!", "QUARANTINE WAS AUTOMATICALLY DISABLED! Please remove old quarantined messages, and re-enable the quarantine!"); 
            system("sudo -u www-data quarantine-disable.pl");
        } 
    }

    if (($config_set_hard || $config_set_soft) && $used_space < $soft_limit)
    {
        write_config($config_path, $config_file, "soft", "0");
        write_config($config_path, $config_file, "hard", "0");
        #TODO: get appliance object and commit
        #TODO: notify about change
        log_message("info", "quarantine limits reset due to unproblematic current_space");
        notify_admin("ATTENTION: disk space limits were reset ($hostname)!", "Due to uncomplicated free space the disk space limits were reset, QUARANTINE WAS NOT RE-ENABLED THIS HAS TO BE DONE MANUALLY!");
    } 

}

sub notify_admin
{
    my $subject = shift;
    my $body = shift;
    my $recipient = $config->{'notify_address'};
    my $hostname = `hostname -f`;
    chomp($hostname);

    # create email object
    my $email = Email::Simple->create(
        header => [
            From => "no-reply\@$hostname\n",
            To => $recipient,
            Subject => $subject,
        ],
        body => Encode::encode_utf8($body),
    );

    # send notification mail
    sendmail($email);
}

exit 0;


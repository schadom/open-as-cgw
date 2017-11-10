#!/usr/bin/perl

BEGIN { 
    my $homedir = (getpwuid($<))[7];
    unshift(@INC,"$homedir/devel/limesgui/trunk/limes-as/lib");
}                                                                                                                            
 
use strict;
use warnings;

use Error qw(:try);
use DBI;
use Data::Dumper;
use WrapChartClicker;

###########################################################

my $mysql_username = 'rt_log';
my $mysql_password = 'rt_log';
my $mysql_database = 'rt_log';
my $mysql_hostname = 'localhost';

# get the top XX domains of the day for statistics
my $interval = 100;


# Connect to MySQL
my $dsn = "DBI:mysql:database=$mysql_database;host=$mysql_hostname;mysql_server_prepare=1";
my $dbh = DBI->connect($dsn,$mysql_username,$mysql_password,{
                        RaiseError => 0,
                        AutoCommit => 1,
                       });
$dbh->{'mysql_auto_reconnect'} = 1;

die "Failed to Connect to Database!" if not $dbh;
 
# select from mail livelog
#my $livelog_stmt = "SELECT UNIX_TIMESTAMP(received_log) AS timestamp, sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR)";
my $livelog_stmt = "SELECT UNIX_TIMESTAMP(received_log) AS timestamp, sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)";

# get all mails
my $mails = $dbh->selectall_hashref($livelog_stmt,'timestamp');

#print Dumper $mails;

my $stats;

foreach my $timestamp (keys %$mails)
{
    my $mail = $mails->{$timestamp};
    my $rounded_timestamp = $timestamp + ($interval - ($timestamp % $interval));
    
    my $sqlgrey = $mail->{'sqlgrey'};
    my $amavis = $mail->{'amavis'} || 0;

    unless ($stats->{$rounded_timestamp})
    {
        $stats->{$rounded_timestamp} = {
            passed_clean => 0,
            passed_spam => 0,
            blocked_greylisted => 0,
            blocked_blacklisted => 0,
            blocked_virus => 0,
            blocked_banned => 0,
            blocked_spam => 0,
        };
    }

    # accepted
    if ($sqlgrey < 20)
    {
        # passed
        if ($amavis <20)
        {
            # clean
            if ($amavis == 10)
            {
                $stats->{$rounded_timestamp}->{'passed_clean'} ++;    
            }
            # spammy
            elsif ($amavis == 11)
            {
                $stats->{$rounded_timestamp}->{'passed_spam'} ++;
            }
        }
        # blocked virus/banned/spam
        else
        {
            # virus
            if ($amavis == 20)
            {
                $stats->{$rounded_timestamp}->{'blocked_virus'} ++;
            }
            # banned
            elsif ($amavis == 21)
            {
                $stats->{$rounded_timestamp}->{'blocked_banned'} ++;
            }
            # spam
            elsif ($amavis == 22)
            {
                $stats->{$rounded_timestamp}->{'blocked_spam'} ++;
            }
        }
    }
    # blocked
    else
    {
        # greylisted
        if ($sqlgrey < 22)
        {
            $stats->{$rounded_timestamp}->{'blocked_greylisted'} ++;
        }
        # blacklisted
        elsif ($sqlgrey == 22 || $sqlgrey == 23)
        {
            $stats->{$rounded_timestamp}->{'blocked_blacklisted'} ++;
        }
    }
}                

#print Dumper $stats;

my $times = [ sort { $a <=> $b } keys %$stats ];

# get first and last entry
my $start_timestamp = $times->[0];
my $end_timestamp = $times->[((scalar @$times)-1)];
my $cur_timestamp = $start_timestamp;

while ($cur_timestamp <= $end_timestamp)
{
    unless ($stats->{$cur_timestamp})
    {
        push @$times, $cur_timestamp;
    }
    $cur_timestamp += $interval;
}

$times = [ sort {$a <=> $b} @$times ];


my $wcc_arr = [];

# insert times;
push @$wcc_arr, $times;

my @data;

foreach my $timestamp (@$times)
{
    if ($stats->{$timestamp})
    {
        # i know this is very dirty. sorry, it's 37° outside
        push @{$data[0]}, $stats->{$timestamp}->{'passed_clean'};
        push @{$data[1]}, $stats->{$timestamp}->{'passed_spam'};
        push @{$data[2]}, $stats->{$timestamp}->{'blocked_greylisted'};
        push @{$data[3]}, $stats->{$timestamp}->{'blocked_blacklisted'};
        push @{$data[4]}, $stats->{$timestamp}->{'blocked_virus'};
        push @{$data[5]}, $stats->{$timestamp}->{'blocked_banned'};
        push @{$data[6]}, $stats->{$timestamp}->{'blocked_spam'};
    }
    else
    {
        push @{$data[0]}, 0;
        push @{$data[1]}, 0;
        push @{$data[2]}, 0;
        push @{$data[3]}, 0;
        push @{$data[4]}, 0;
        push @{$data[5]}, 0;
        push @{$data[6]}, 0;
    }

}
push @$wcc_arr, @data;

#print Dumper $wcc_arr;

my $chart = WrapChartClicker->new({
    intervall => 300,
    graphType => 'accounted',
    dir => '/tmp',
    filename => 'testgraph.png',
    data => $wcc_arr,
    vLabel => 'Mails/5 Min',
    vSize => 300,
    hSize => 800, 
});

$chart->render;

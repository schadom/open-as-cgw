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



use strict;
use warnings;
use DBI;


my $mysql_username = 'rt_log';
my $mysql_password = 'rt_log';
my $mysql_database = 'rt_log';
my $mysql_hostname = 'localhost';


# Connect to MySQL
my $dsn = "DBI:mysql:database=$mysql_database;host=$mysql_hostname;mysql_server_prepare=1";
my $dbh = DBI->connect($dsn,$mysql_username,$mysql_password,{
                        RaiseError => 0,
                        AutoCommit => 1,
                       });
$dbh->{'mysql_auto_reconnect'} = 1;

die "Failed to Connect to Database!" if not $dbh;

### STATEMENTS ###
## TIME ##
# get the start time
my $start_stmt_text = "SELECT DATE(DATE_SUB(NOW(), INTERVAL 1 HOUR)), HOUR(DATE_SUB(NOW(), INTERVAL 1 HOUR))";
## MAIL ##
# last hour statistics
my $mail_lasthour_stmt_text = "SELECT DISTINCT sqlgrey, amavis, COUNT( * ) FROM mail_livelog WHERE received_log >= ? AND received_log <= ? GROUP BY sqlgrey, amavis;";

# insert last hour stats
my $insert_hourly_stmt_text = "INSERT INTO mail_hourly (received_start, received_end, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?);";
my $insert_hourly_stmt = $dbh->prepare($insert_hourly_stmt_text);

# find out if there is a day entry
my $day_entry_lookup_stmt_text = "SELECT received_start, received_end FROM mail_daily WHERE received_start=? AND received_end=?";
my $day_entry_lookup_stmt = $dbh->prepare($day_entry_lookup_stmt_text);

# update the daily stats with the current hour stats
my $update_daily_stmt_text = "UPDATE mail_daily SET passed_clean=passed_clean+?, passed_spam=passed_spam+?, blocked_greylisted=blocked_greylisted+?, blocked_blacklisted=blocked_blacklisted+?, blocked_virus=blocked_virus+?, blocked_banned=blocked_banned+?, blocked_spam=blocked_spam+? WHERE received_start=? AND received_end=?;";
my $update_daily_stmt = $dbh->prepare($update_daily_stmt_text);

# insert a new day entry with current hour stats
my $insert_daily_stmt_text = "INSERT INTO mail_daily (received_start, received_end, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?);";
my $insert_daily_stmt = $dbh->prepare($insert_daily_stmt_text);

# prepare
my $mail_lasthour_stmt = $dbh->prepare($mail_lasthour_stmt_text);

my ($startdate, $starthour);
unless (($startdate, $starthour) = $dbh->selectrow_array($start_stmt_text))
{
    die "Select didn't work!";
}

my $startdatetime = "$startdate $starthour:00:00";
my $enddatetime = "$startdate $starthour:59:59";
my $daystartdatetime = "$startdate 00:00:00";
my $dayenddatetime = "$startdate 23:59:59";

my $passed_clean = 0;
my $passed_spam = 0;
my $blocked_greylisted = 0;
my $blocked_blacklisted = 0;
my $blocked_virus = 0;
my $blocked_banned = 0;
my $blocked_spam = 0;

get_last_hour_mail();
commit_last_hour_mail();
commit_day_mail();

#print_last_hour_mail();

sub get_last_hour_mail
{
    $mail_lasthour_stmt->bind_param(1,$startdatetime);
    $mail_lasthour_stmt->bind_param(2,$enddatetime);
    if ($mail_lasthour_stmt->execute)
    {           
        while (my ($sqlgrey,$amavis,$count) = $mail_lasthour_stmt->fetchrow_array)
        {
            ## ## status codes ## ##
            ## sqlgrey ##
            # 10 update
            # 11 whitelist
            # 12 whitelist_sender
            # 20 new
            # 21 abuse
            # 22 blacklist
            # 23 blacklist_sender
            #
            ## amavis ##
            # 10 passed clean
            # 11 passed spammy
            # 20 blocked infected
            # 21 blocked banned
            # 22 blocked spam
            ########################
            
            # accepted
            if ($sqlgrey < 20)
            {
                # passed
                if ($amavis <20)
                {
                    # clean
                    if ($amavis == 10)
                    {
                        $passed_clean += $count;    
                    }
                    # spammy
                    elsif ($amavis == 11)
                    {
                        $passed_spam += $count;
                    }
                }
                # blocked virus/banned/spam
                else
                {
                    # virus
                    if ($amavis == 20)
                    {
                        $blocked_virus += $count;
                    }
                    # banned
                    elsif ($amavis == 21)
                    {
                        $blocked_banned += $count;
                    }
                    # spam
                    elsif ($amavis == 22)
                    {
                        $blocked_spam += $count;
                    }
                }
            }
            # blocked
            else
            {
                # greylisted
                if ($sqlgrey < 22)
                {
                    $blocked_greylisted += $count;
                }
                # blacklisted
                elsif ($sqlgrey == 22 || $sqlgrey == 23)
                {
                    $blocked_blacklisted += $count;
                }
            }
        }
    }
}

sub print_last_hour_mail
{
    printf("*** Spam report %s - %s ***
            \t** Passed **
            \t\tClean: %d
            \t\tSpam: %d
            \t** Blocked **
            \t\tGreylisted: %d
            \t\tBlacklisted: %d
            \t\tVirus: %d
            \t\tBanned: %d\n",
            $startdatetime,
            $enddatetime,
            $passed_clean,
            $passed_spam,
            $blocked_greylisted,
            $blocked_blacklisted,
            $blocked_virus,
            $blocked_banned);
}

sub commit_last_hour_mail
{
    $insert_hourly_stmt->bind_param(1,$startdatetime);
    $insert_hourly_stmt->bind_param(2,$enddatetime);
    $insert_hourly_stmt->bind_param(3,$passed_clean);
    $insert_hourly_stmt->bind_param(4,$passed_spam);
    $insert_hourly_stmt->bind_param(5,$blocked_greylisted);
    $insert_hourly_stmt->bind_param(6,$blocked_blacklisted);
    $insert_hourly_stmt->bind_param(7,$blocked_virus);
    $insert_hourly_stmt->bind_param(8,$blocked_banned);
    $insert_hourly_stmt->bind_param(9,$blocked_spam);
    my $rv = $insert_hourly_stmt->execute;
}

sub commit_day_mail
{
    $day_entry_lookup_stmt->bind_param(1,$daystartdatetime);
    $day_entry_lookup_stmt->bind_param(2,$dayenddatetime);
    
    my $rows = $day_entry_lookup_stmt->execute;

    if ($rows == 0)
    {
        print "Inserting day statistics...";
        $insert_daily_stmt->bind_param(1,$daystartdatetime);
        $insert_daily_stmt->bind_param(2,$dayenddatetime);
        $insert_daily_stmt->bind_param(3,$passed_clean);
        $insert_daily_stmt->bind_param(4,$passed_spam);
        $insert_daily_stmt->bind_param(5,$blocked_greylisted);
        $insert_daily_stmt->bind_param(6,$blocked_blacklisted);
        $insert_daily_stmt->bind_param(7,$blocked_virus);
        $insert_daily_stmt->bind_param(8,$blocked_banned);
        $insert_daily_stmt->bind_param(9,$blocked_spam);
        $insert_daily_stmt->execute;
        print "done\n";
    }
    else
    {    
        print "Updating day statistics...";
        $update_daily_stmt->bind_param(1,$passed_clean);
        $update_daily_stmt->bind_param(2,$passed_spam);
        $update_daily_stmt->bind_param(3,$blocked_greylisted);
        $update_daily_stmt->bind_param(4,$blocked_blacklisted);
        $update_daily_stmt->bind_param(5,$blocked_virus);
        $update_daily_stmt->bind_param(6,$blocked_banned);
        $update_daily_stmt->bind_param(7,$blocked_spam);
        $update_daily_stmt->bind_param(8,$daystartdatetime);
        $update_daily_stmt->bind_param(9,$dayenddatetime);
        $update_daily_stmt->execute;
        print "done\n";
    }
}

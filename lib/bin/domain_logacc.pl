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
use Data::Dumper;

use Time::HiRes qw(gettimeofday tv_interval);

my $mysql_username = 'rt_log';
my $mysql_password = 'rt_log';
my $mysql_database = 'rt_log';
my $mysql_hostname = 'localhost';

# get the top XX domains of the day for statistics
my $top_count = 100;


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
my $start_stmt_text = "SELECT DATE(DATE_SUB(NOW(), INTERVAL 1 DAY))";

# temporary tables
my $temp_from_top_stmt_text = "CREATE TEMPORARY TABLE temp_from_top SELECT DISTINCT from_domain,COUNT( from_domain ) AS count FROM domain_livelog WHERE received_log >= ? AND received_log <= ? GROUP BY from_domain ORDER BY count DESC LIMIT $top_count";
my $temp_from_top_stmt = $dbh->prepare($temp_from_top_stmt_text);

my $temp_to_top_stmt_text = "CREATE TEMPORARY TABLE temp_to_top SELECT DISTINCT to_domain,COUNT( to_domain ) AS count FROM domain_livelog WHERE received_log >= ? AND received_log <= ? GROUP BY to_domain ORDER BY count DESC LIMIT $top_count";
my $temp_to_top_stmt = $dbh->prepare($temp_to_top_stmt_text);

## DOMAIN ##
# last hour statistics
#my $domain_lasthour_stmt_text = "SELECT DISTINCT from_domain, to_domain, sqlgrey, amavis, COUNT( * ) FROM domain_livelog WHERE received_log >= ? AND received_log <= ? GROUP BY from_domain, sqlgrey, amavis;";
#my $domain_lasthour_stmt_text = "SELECT DISTINCT from_domain, to_domain, sqlgrey, amavis, COUNT( * ) AS count FROM domain_livelog WHERE received_log >= ? AND received_log <= ? GROUP BY from_domain, sqlgrey, amavis ORDER BY count DESC LIMIT $top_count;";

my $domain_from_lasthour_stmt_text = "SELECT DISTINCT dl.from_domain, dl.sqlgrey, dl.amavis, COUNT(dl.from_domain) AS count FROM domain_livelog dl LEFT JOIN temp_from_top tmptd ON (dl.from_domain = tmptd.from_domain) WHERE dl.received_log >= ? AND dl.received_log <= ? GROUP BY tmptd.from_domain, dl.sqlgrey, dl.amavis ORDER BY count;";

my $domain_to_lasthour_stmt_text = "SELECT DISTINCT dl.to_domain, dl.sqlgrey, dl.amavis, COUNT(dl.to_domain) AS count FROM domain_livelog dl LEFT JOIN temp_to_top tmptd ON (dl.to_domain = tmptd.to_domain) WHERE dl.received_log >= ? AND dl.received_log <= ? GROUP BY tmptd.to_domain, dl.sqlgrey, dl.amavis ORDER BY count;";
#my $domain_to_lasthour_stmt = $dbh->prepare($domain_to_lasthour_stmt_text);

# insert last hour stats
my $insert_from_hourly_stmt_text = "INSERT INTO domain_from_hourly (received_start, received_end, domain, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?,?);";
my $insert_from_hourly_stmt = $dbh->prepare($insert_from_hourly_stmt_text);

my $insert_to_hourly_stmt_text = "INSERT INTO domain_to_hourly (received_start, received_end, domain, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?,?);";
my $insert_to_hourly_stmt = $dbh->prepare($insert_to_hourly_stmt_text);

# insert a new day entry
my $insert_from_daily_stmt_text = "INSERT INTO domain_from_daily (received_start, received_end, domain, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?,?);";
my $insert_from_daily_stmt = $dbh->prepare($insert_from_daily_stmt_text);

my $insert_to_daily_stmt_text = "INSERT INTO domain_to_daily (received_start, received_end, domain, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus, blocked_banned, blocked_spam) VALUES (?,?,?,?,?,?,?,?,?,?);";
my $insert_to_daily_stmt = $dbh->prepare($insert_to_daily_stmt_text);


my ($date);
unless (($date) = $dbh->selectrow_array($start_stmt_text))
{
    die "Select didn't work!";
}

my $starthour = 0;
my $daystartdatetime = "$date 00:00:00";
my $dayenddatetime = "$date 23:59:59";

##### Data structures
#
# Stats for one domain
# $domain = { name => 'domain.tld',
#             passed_clean => 0,
#             passed_spam => 0,
#             sum => 0,
#             ...
#             hours => [
#                           {
#                               passed_clean => 0,
#                               passed_spam => 0,
#                           }
#                      ]
#           }
# 
# Stats for all domains
# $domains_from = {
#                    lol =>   { name => 'lol', ...},
#                    lala =>  { name => 'lala', ...},
#                    ...
#                 }
#
# Sorted stats
# $domains_from_sorted = [
#                           { name => 'lol', ...},
#                        ]
#
#
#

#select STDOUT; $| = 1; #unbuffered

#print "Start\n";

my $t0 = [ gettimeofday ];


#print "Create temp table (from)...";
# get all stats
$temp_from_top_stmt->bind_param(1,$daystartdatetime);
$temp_from_top_stmt->bind_param(2,$dayenddatetime);

$temp_from_top_stmt->execute(); # temporary table

#printf "done (%f)\n", tv_interval($t0);

my $domain_from_lasthour_stmt = $dbh->prepare($domain_from_lasthour_stmt_text);

my $t1 = [ gettimeofday ];

#print "Creating statistics (from)...";

my $domains_from = get_last_24hour_domains($domain_from_lasthour_stmt);

#printf "done (%f)\n", tv_interval($t1);

my $t2 = [ gettimeofday ];

#print "Sorting (from)...";

my $top_domains_from = get_day_top_domains($domains_from);

#printf "done (%f)\n", tv_interval($t2);

my $t3 = [ gettimeofday ];

#print "Create temp table (to)...";

$temp_to_top_stmt->bind_param(1,$daystartdatetime);
$temp_to_top_stmt->bind_param(2,$dayenddatetime);
$temp_to_top_stmt->execute(); # temporary table
my $domain_to_lasthour_stmt = $dbh->prepare($domain_to_lasthour_stmt_text);

#printf "done (%f)\n", tv_interval($t3);

my $t4 = [ gettimeofday ];

#print "Creating statistics (to)...";

my $domains_to = get_last_24hour_domains($domain_to_lasthour_stmt);

#printf "done (%f)\n", tv_interval($t4);

my $t5 = [ gettimeofday ];

#print "Sorting (to)...";

my $top_domains_to = get_day_top_domains($domains_to);

#printf "done (%f)\n", tv_interval($t5);

my $t6 = [ gettimeofday ];
 
#print Dumper $top_domains_from;

#print "Committing to database (from,to)...";

#commit_stats_db($top_domains_from, $top_domains_to);

#printf "done (%f)\n", tv_interval($t6);

my $elapsed_total = tv_interval($t0);
#printf "Finished. Total: (%f sec)\n", tv_interval($t0);


sub init_structure
{
    my $domain_name = shift;
    my $domain;

    $domain = {
        name => $domain_name,
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
        sum => 0,
        hours => [  ],
    };

    for (my $hour = 0; $hour<24; $hour++)
    {
        $domain->{'hours'}->[$hour] = {
            passed_clean => 0,
            passed_spam => 0,
            blocked_greylisted => 0,
            blocked_blacklisted => 0,
            blocked_virus => 0,
            blocked_banned => 0,
            blocked_spam => 0,
        }
    }
    return $domain;
}

sub get_last_24hour_domains
{
    my $stmt = shift;
    my $stats = { };

    for (my $hour = 0; $hour<24; $hour++)
    {
        my $startdatetime = "$date $hour:00:00";
        my $enddatetime = "$date $hour:59:59";

        $stmt->bind_param(1,$startdatetime);
        $stmt->bind_param(2,$enddatetime);

        if ($stmt->execute)
        {           
            while (my ($domain_name, $sqlgrey, $amavis, $count) = $stmt->fetchrow_array)
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
                
                $stats->{$domain_name} = init_structure($domain_name) if not ($stats->{$domain_name});
                            
                $stats->{$domain_name}->{'sum'} += $count;
                
                # accepted
                if ($sqlgrey < 20)
                {
                    # passed
                    if (defined $amavis && $amavis <20)
                    {
                        # clean
                        if ($amavis == 10)
                        {
                            $stats->{$domain_name}->{'passed_clean'} += $count;    
                            $stats->{$domain_name}->{'hours'}->[$hour]->{'passed_clean'} += $count;
                        }
                        # spammy
                        elsif ($amavis == 11)
                        {
                            $stats->{$domain_name}->{'passed_spam'} += $count;
                            $stats->{$domain_name}->{'hours'}->[$hour]->{'passed_spam'} += $count;
                        }
                    }
                    # blocked virus/banned/spam
                    else
                    {
                        if (defined $amavis)
                        {
                            # virus
                            if ($amavis == 20)
                            {
                                $stats->{$domain_name}->{'blocked_virus'} += $count;
                                $stats->{$domain_name}->{'hours'}->[$hour]->{'blocked_virus'} += $count;
                            }
                            # banned
                            elsif ($amavis == 21)
                            {
                                $stats->{$domain_name}->{'blocked_banned'} += $count;
                                $stats->{$domain_name}->{'hours'}->[$hour]->{'blocked_banned'} += $count;
                            }
                            # spam
                            elsif ($amavis == 22)
                            {
                                $stats->{$domain_name}->{'blocked_spam'} += $count;
                                $stats->{$domain_name}->{'hours'}->[$hour]->{'blocked_spam'} += $count;
                            }
                        }
                    }
                }
                # blocked
                else
                {
                    # greylisted
                    if ($sqlgrey < 22)
                    {
                        $stats->{$domain_name}->{'blocked_greylisted'} += $count;
                        $stats->{$domain_name}->{'hours'}->[$hour]->{'blocked_greylisted'} += $count;
                    }
                    # blacklisted
                    elsif ($sqlgrey == 22 || $sqlgrey == 23)
                    {
                        $stats->{$domain_name}->{'blocked_blacklisted'} += $count;
                        $stats->{$domain_name}->{'hours'}->[$hour]->{'blocked_blacklisted'} += $count;
                    }
                }
            }
        }
    }
    return $stats;
}                    

sub get_day_top_domains
{
    my $domains = shift;
    my $sorted_domains = sort_day_top_domains($domains);


    my @top_domains;
    my $domain_count = scalar @$sorted_domains;

    my $count = ($domain_count > $top_count+1) ? $top_count : $domain_count;

    my $l;
    for ($l=0;$l<$count;$l++)
    {
        push @top_domains, ($sorted_domains->[$l]);
    }

    return [ @top_domains ];
}


sub sort_day_top_domains
{
    my $domains = shift;
    my $sorted_domains = [ ];
    foreach my $domainname (keys %$domains)
    {
        my $count = $domains->{$domainname};
        push @$sorted_domains, $domains->{$domainname};
    }       

    $sorted_domains = [ sort{&sort_domains_by_count}(@$sorted_domains) ];

    return $sorted_domains;
}

sub sort_domains_by_count
{
    my $sum_a = $a->{'sum'};
    my $sum_b = $b->{'sum'};

    if ($sum_a < $sum_b) { 1; }
    elsif ($sum_a == $sum_b) { 0; }
    else { -1; }
}
        
sub commit_stats_db
{
    my $domains_from = shift;
    my $domains_to = shift;

    # FROM DOMAINS
    foreach my $domain (@$domains_from)
    {
        # insert hour stats
        for (my $hour = 0; $hour<24; $hour++)
        {
            my $startdatetime = "$date $hour:00:00";
            my $enddatetime = "$date $hour:59:59";
            $insert_from_hourly_stmt->bind_param(1,$startdatetime);
            $insert_from_hourly_stmt->bind_param(2,$enddatetime);
            $insert_from_hourly_stmt->bind_param(3,$domain->{'name'});
            $insert_from_hourly_stmt->bind_param(4,$domain->{'hours'}->[$hour]->{'passed_clean'});
            $insert_from_hourly_stmt->bind_param(5,$domain->{'hours'}->[$hour]->{'passed_spam'});
            $insert_from_hourly_stmt->bind_param(6,$domain->{'hours'}->[$hour]->{'blocked_greylisted'});
            $insert_from_hourly_stmt->bind_param(7,$domain->{'hours'}->[$hour]->{'blocked_blacklisted'});
            $insert_from_hourly_stmt->bind_param(8,$domain->{'hours'}->[$hour]->{'blocked_virus'});
            $insert_from_hourly_stmt->bind_param(9,$domain->{'hours'}->[$hour]->{'blocked_banned'});
            $insert_from_hourly_stmt->bind_param(10,$domain->{'hours'}->[$hour]->{'blocked_spam'});
            my $rv = $insert_from_hourly_stmt->execute; 
        }

        $insert_from_daily_stmt->bind_param(1,$daystartdatetime);
        $insert_from_daily_stmt->bind_param(2,$dayenddatetime);
        $insert_from_daily_stmt->bind_param(3,$domain->{'name'});
        $insert_from_daily_stmt->bind_param(4,$domain->{'passed_clean'});
        $insert_from_daily_stmt->bind_param(5,$domain->{'passed_spam'});
        $insert_from_daily_stmt->bind_param(6,$domain->{'blocked_greylisted'});
        $insert_from_daily_stmt->bind_param(7,$domain->{'blocked_blacklisted'});
        $insert_from_daily_stmt->bind_param(8,$domain->{'blocked_virus'});
        $insert_from_daily_stmt->bind_param(9,$domain->{'blocked_banned'});
        $insert_from_daily_stmt->bind_param(10,$domain->{'blocked_spam'});
        my $rv = $insert_from_daily_stmt->execute; 
    }
    
    # TO DOMAINS
    foreach my $domain (@$domains_to)
    {
        # insert hour stats
        for (my $hour = 0; $hour<24; $hour++)
        {
            my $startdatetime = "$date $hour:00:00";
            my $enddatetime = "$date $hour:59:59";
            $insert_to_hourly_stmt->bind_param(1,$startdatetime);
            $insert_to_hourly_stmt->bind_param(2,$enddatetime);
            $insert_to_hourly_stmt->bind_param(3,$domain->{'name'});
            $insert_to_hourly_stmt->bind_param(4,$domain->{'hours'}->[$hour]->{'passed_clean'});
            $insert_to_hourly_stmt->bind_param(5,$domain->{'hours'}->[$hour]->{'passed_spam'});
            $insert_to_hourly_stmt->bind_param(6,$domain->{'hours'}->[$hour]->{'blocked_greylisted'});
            $insert_to_hourly_stmt->bind_param(7,$domain->{'hours'}->[$hour]->{'blocked_blacklisted'});
            $insert_to_hourly_stmt->bind_param(8,$domain->{'hours'}->[$hour]->{'blocked_virus'});
            $insert_to_hourly_stmt->bind_param(9,$domain->{'hours'}->[$hour]->{'blocked_banned'});
            $insert_to_hourly_stmt->bind_param(10,$domain->{'hours'}->[$hour]->{'blocked_spam'});
            my $rv = $insert_to_hourly_stmt->execute; 
        }

        $insert_to_daily_stmt->bind_param(1,$daystartdatetime);
        $insert_to_daily_stmt->bind_param(2,$dayenddatetime);
        $insert_to_daily_stmt->bind_param(3,$domain->{'name'});
        $insert_to_daily_stmt->bind_param(4,$domain->{'passed_clean'});
        $insert_to_daily_stmt->bind_param(5,$domain->{'passed_spam'});
        $insert_to_daily_stmt->bind_param(6,$domain->{'blocked_greylisted'});
        $insert_to_daily_stmt->bind_param(7,$domain->{'blocked_blacklisted'});
        $insert_to_daily_stmt->bind_param(8,$domain->{'blocked_virus'});
        $insert_to_daily_stmt->bind_param(9,$domain->{'blocked_banned'});
        $insert_to_daily_stmt->bind_param(10,$domain->{'blocked_spam'});
        my $rv = $insert_to_daily_stmt->execute; 
    }
}


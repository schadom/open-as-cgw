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


package Underground8::ReportFactory::LimesAS::Mail;
use base Underground8::ReportFactory;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Report::LimesAS::MailStats;
use Underground8::Report::LimesAS::MailLivelog;
#use WrapChartClicker;
use Error qw(:try);
use Underground8::Exception;
use DBI;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;

our $DEBUG = 0;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_dbh'} = undef;

    bless $self, $class;
    return $self;
}

sub dbh
{
    my $self = shift;
    unless (ref $self->{'_dbh'} eq 'GLOB')
    {
        my $mysql_username = $g->{'rt_log_mysql_username'};
        my $mysql_password = $g->{'rt_log_mysql_password'};
        my $mysql_database = $g->{'rt_log_mysql_database'};
        my $mysql_hostname = $g->{'rt_log_mysql_hostname'};
        # Connect to MySQL
        my $dsn = "DBI:mysql:database=$mysql_database;host=$mysql_hostname;mysql_server_prepare=1";
        my $dbh = DBI->connect($dsn,$mysql_username,$mysql_password,{
                            RaiseError => 0,
                            AutoCommit => 1,
                           });
        $dbh->{'mysql_auto_reconnect'} = 1;

        throw Underground8::Exception("Failed to Connect to Database!") if not $dbh;

        $self->{'_dbh'} = $dbh;
    }
    return $self->{'_dbh'};
}

sub current_timestamp
{
    my $self = shift;

    my $dbh = $self->dbh;

    my $time_stmt = "SELECT UNIX_TIMESTAMP(NOW());";
    
    my $timestamp = $dbh->selectrow_array($time_stmt);

    return $timestamp;
}


sub mail_lastyear
{
    my $self = shift;
    my $interval = $g->{'mail_chart_daylog_interval'};
    my $dbh = $self->dbh;

    my $daylog_stmt = "SELECT UNIX_TIMESTAMP(received_end) AS timestamp, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus,  blocked_banned, blocked_spam FROM mail_daily WHERE received_end > DATE_SUB(NOW(), INTERVAL 1 YEAR);";

    my $stats = $dbh->selectall_hashref($daylog_stmt,'timestamp');

    my $time_offset = 31536000; # 365 days

    my $report = $self->create_report($stats,$interval,$time_offset);

    return $report;    
}
 


sub mail_lastmonth
{
    my $self = shift;
    my $interval = $g->{'mail_chart_hourlog_interval'};
    my $dbh = $self->dbh;

    my $hourlog_stmt = "SELECT UNIX_TIMESTAMP(received_end) AS timestamp, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus,  blocked_banned, blocked_spam FROM mail_hourly WHERE received_end > DATE_SUB(NOW(), INTERVAL 1 MONTH);";

    my $stats = $dbh->selectall_hashref($hourlog_stmt,'timestamp');
 
    my $time_offset = 2678400; # 31 days

    my $report = $self->create_report($stats,$interval,$time_offset);

    return $report;
}

sub mail_lastweek
{
    my $self = shift;
    
    my $interval = $g->{'mail_chart_hourlog_interval'};

    my $dbh = $self->dbh;

    my $hourlog_stmt = "SELECT UNIX_TIMESTAMP(received_end) AS timestamp, passed_clean, passed_spam, blocked_greylisted, blocked_blacklisted, blocked_virus,  blocked_banned, blocked_spam FROM mail_hourly WHERE received_end > DATE_SUB(NOW(), INTERVAL 1 WEEK);";

    my $stats = $dbh->selectall_hashref($hourlog_stmt,'timestamp');

    my $time_offset = 604800; # 7 days

    my $report = $self->create_report($stats,$interval,$time_offset);

    return $report;
}

sub mail_last24h
{
    my $self = shift;

    # get the top XX domains of the day for statistics
    my $interval = $g->{'mail_chart_livelog_interval'};
    
    
    my $t0 = [ gettimeofday ]; # start

    my $dbh = $self->dbh;
     
    # select from mail livelog
    my $livelog_stmt = "SELECT UNIX_TIMESTAMP(received_log) AS timestamp, sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR)";

    #my $livelog_stmt = "SELECT sqlgrey, amavis AS timestamp, COUNT(*) AS count FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR) GROUP BY sqlgrey, amavis";


    #my $livelog_stmt = "SELECT UNIX_TIMESTAMP(received_log) AS timestamp, sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)";

    # get all mails
    my $mails = $dbh->selectall_arrayref($livelog_stmt);
    my $t1 = [ gettimeofday ];

    my $stats;

    my $sum_stats = {
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
        sum => 0,
    };

    foreach my $row (@$mails)
    {
        my ($timestamp,$sqlgrey,$amavis) = @$row;
        my $rounded_timestamp = $timestamp + ($interval - ($timestamp % $interval));
        
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
        $stats->{$rounded_timestamp} = $self->find_mail_status($stats->{$rounded_timestamp},$sqlgrey,$amavis);
        $sum_stats = $self->find_mail_status($sum_stats,$sqlgrey,$amavis);
    }
    
    my $t2 = [ gettimeofday ];

    my $time_offset = 86400; # one day ago

    my $report = $self->create_report($stats,$interval,$time_offset);

    my $t3 = [ gettimeofday ];

    if ($DEBUG > 0)
    {
        my $elapsed1 = tv_interval($t0,$t1);
        my $elapsed2 = tv_interval($t1,$t2);
        my $elapsed3 = tv_interval($t2,$t3);

        printf ("%f\n%f\n%f\n",$elapsed1,$elapsed2,$elapsed3);
    }
     

    return $report;
}

sub from_domains_lastweek
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT from_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $hourlog_lastweek_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_from_hourly WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 WEEK) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($hourlog_lastweek_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub to_domains_lastweek
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT to_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $hourlog_lastweek_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_to_hourly WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 WEEK) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($hourlog_lastweek_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub from_domains_lastmonth
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT from_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $hourlog_lastmonth_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_from_hourly WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 MONTH) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($hourlog_lastmonth_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub to_domains_lastmonth
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT to_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $hourlog_lastmonth_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_to_hourly WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 MONTH) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($hourlog_lastmonth_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub from_domains_lastyear
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT from_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $daylog_lastyear_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_from_daily WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 YEAR) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($daylog_lastyear_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub to_domains_lastyear
{
    my $self = shift;
    my $top_count = shift || 100;

    my $dbh = $self->dbh;

    my $livelog_today_stmt = "SELECT to_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) AND HOUR(received_log) < HOUR(NOW()) GROUP BY crc32(sqlgrey), crc32(amavis) ORDER BY from_domain;";
    my $daylog_lastyear_stmt = "SELECT domain AS name, SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam, SUM(passed_clean) + SUM(passed_spam) + SUM(blocked_greylisted) + SUM(blocked_blacklisted) + SUM(blocked_virus) + SUM(blocked_banned) + SUM(blocked_spam) AS sum FROM domain_to_daily WHERE DATE(received_end) > DATE_SUB(NOW(), INTERVAL 1 YEAR) GROUP BY crc32(domain) ORDER BY domain;";
    
    my $stats = $dbh->selectall_hashref($daylog_lastyear_stmt,'name');
    $stats = $self->db_stats_domains_livelog($livelog_today_stmt, $stats);
    
    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;      
}

sub from_domains_last24h
{
    my $self = shift;
    my $top_count = shift || 100;

    my $livelog_stmt = "SELECT from_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR) GROUP BY crc32(from_domain), sqlgrey, amavis ORDER BY from_domain;";
    my $stats = $self->db_stats_domains_livelog($livelog_stmt);

    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;     
}

sub to_domains_last24h
{
    my $self = shift;
    my $top_count = shift || 100;

    my $livelog_stmt = "SELECT to_domain, sqlgrey, amavis, COUNT(*) AS count FROM domain_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR) GROUP BY crc32(to_domain), sqlgrey, amavis ORDER BY from_domain;";
    my $stats = $self->db_stats_domains_livelog($livelog_stmt);

    my $other_domains = $stats->{'other'};
    delete $stats->{'other'};

    my $sorted_domains = sort_domains($stats);
    
    my $top_domains = [];
    my $domain_count = scalar @$sorted_domains;
    my $count = ($domain_count > $top_count) ? $top_count : $domain_count;
    @$top_domains = map { $sorted_domains->[$_] } (0..($count - 1));

    push @$top_domains, $other_domains if $other_domains;

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->domains($top_domains);
    return $report;     
}


sub db_stats_domains_livelog
{
    my $self = shift;
    my $stmt = shift;
    my $stats = shift || { };
    my $dbh = $self->dbh;

    die "I need a SQL statement!" unless $stmt;
     
    # select from mail livelog
    # get all mails
    my $mails = $dbh->selectall_arrayref($stmt);


    foreach my $row (@$mails)
    {
        my $domain_name = $row->[0];
        my $sqlgrey = $row->[1];
        my $amavis = $row->[2];
        my $count = $row->[3];

        unless ($stats->{$domain_name})
        {
            $stats->{$domain_name} = {
                name => $domain_name,
                passed_clean => 0,
                passed_spam => 0,
                blocked_greylisted => 0,
                blocked_blacklisted => 0,
                blocked_virus => 0,
                blocked_banned => 0,
                blocked_spam => 0,
                sum => 0,
            };
        }
        $stats->{$domain_name} = $self->find_mail_status($stats->{$domain_name},$sqlgrey,$amavis,$count);
    }
    return $stats;
}

sub sort_domains
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


sub current_stats
{
    my $self = shift;

    my $dbh = $self->dbh;

    my $t0 = [ gettimeofday ]; # start
     
    # select from mail livelog
    my $last24h_stmt = "SELECT sqlgrey, amavis, COUNT(sqlgrey) AS count FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR) GROUP BY crc32(sqlgrey), crc32(amavis)";
    #my $last24h_stmt = "SELECT sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 24 HOUR)";
    my $today_stmt = "SELECT sqlgrey, amavis, COUNT(sqlgrey) AS count FROM mail_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY) GROUP BY crc32(sqlgrey), crc32(amavis)";
    #my $today_stmt = "SELECT sqlgrey, amavis FROM mail_livelog WHERE DATE(received_log) > DATE_SUB(CURDATE(), INTERVAL 1 DAY)";
    my $lasthour_stmt = "SELECT sqlgrey, amavis, COUNT(*) AS count  FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 1 HOUR) GROUP BY crc32(sqlgrey), amavis";
    #my $lasthour_stmt = "SELECT sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 1 HOUR)";
    my $to_lasthour_stmt = "SELECT sqlgrey, amavis, COUNT(*) AS count FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 1 HOUR) AND HOUR(received_log) > HOUR(DATE_SUB(NOW(), INTERVAL 1 HOUR)) GROUP BY crc32(sqlgrey), crc32(amavis)";
    #my $to_lasthour_stmt = "SELECT sqlgrey, amavis FROM mail_livelog WHERE received_log >= DATE_SUB(NOW(), INTERVAL 1 HOUR) AND HOUR(received_log) > HOUR(DATE_SUB(NOW(), INTERVAL 1 HOUR))";
    my $forever_to_lasthour_stmt = "SELECT SUM(passed_clean) AS passed_clean, SUM(passed_spam) AS passed_spam, SUM(blocked_greylisted) AS blocked_greylisted, SUM(blocked_blacklisted) AS blocked_blacklisted, SUM(blocked_virus) AS blocked_virus, SUM(blocked_banned) AS blocked_banned, SUM(blocked_spam) AS blocked_spam FROM mail_daily WHERE DATE(received_start) <= DATE_SUB(CURDATE(), INTERVAL 1 DAY)";

    # get all mails
    my $mails_last24h = $dbh->selectall_arrayref($last24h_stmt);
    my $t1 = [ gettimeofday ];

    my $mails_today = $dbh->selectall_arrayref($today_stmt);
    my $t2 = [ gettimeofday ];
    my $mails_lasthour = $dbh->selectall_arrayref($lasthour_stmt);
    my $t3 = [ gettimeofday ];
    my $mails_to_lasthour = $dbh->selectall_arrayref($to_lasthour_stmt);
    my $t4 = [ gettimeofday ];

    my $stats;

    $stats->{'alltime'} = $dbh->selectrow_hashref($forever_to_lasthour_stmt);
    my $t5 = [ gettimeofday ];

    foreach my $key (keys %{$stats->{'alltime'}})
    {
        $stats->{'alltime'}->{$key} = $stats->{'alltime'}->{$key} || 0;
    }
    my $t6 = [ gettimeofday ];

    $stats->{'last24h'} = {
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
    };
    while (my $row = shift @{$mails_last24h})
    {
        my ($sqlgrey,$amavis,$count) = @$row;
        $stats->{'last24h'} = $self->find_mail_status($stats->{'last24h'},$sqlgrey,$amavis,$count);    
    }     
    my $t7 = [ gettimeofday ];


    $stats->{'today'} = {
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
    };
    while (my $row  = shift @{$mails_today})
    {
        my ($sqlgrey,$amavis,$count) = @$row;
        $stats->{'today'} = $self->find_mail_status($stats->{'today'},$sqlgrey,$amavis,$count);        
    }     
    my $t8 = [ gettimeofday ];


    $stats->{'lasthour'} = {
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
    };
    while (my $row = shift @{$mails_lasthour})
    {
        my ($sqlgrey,$amavis,$count) = @$row;
        $stats->{'lasthour'} = $self->find_mail_status($stats->{'lasthour'},$sqlgrey,$amavis,$count); 
    }
    my $t9 = [ gettimeofday ];

    foreach my $key (keys %{$stats->{'alltime'}})
    {
        $stats->{'alltime'}->{$key} += $stats->{'today'}->{$key};
    }
    my $t10 = [ gettimeofday ];
    
    my $report = new Underground8::Report::LimesAS::MailStats;
    $report->current_stats($stats);


    if ($DEBUG > 0)
    {
        my $elapsed0 = tv_interval($t0,$t1);
        my $elapsed1 = tv_interval($t1,$t2);
        my $elapsed2 = tv_interval($t2,$t3);
        my $elapsed3 = tv_interval($t3,$t4);
        my $elapsed4 = tv_interval($t4,$t5);
        my $elapsed5 = tv_interval($t5,$t6);
        my $elapsed6 = tv_interval($t6,$t7);
        my $elapsed7 = tv_interval($t7,$t8);
        my $elapsed8 = tv_interval($t8,$t9);
        my $elapsed9 = tv_interval($t9,$t10);
        my $elapsed10 = tv_interval($t10);

        printf ("%f\n%f\n%f\n%f\n%f\n%f\n%f\n%f\n%f\n",$elapsed0,$elapsed1,$elapsed2,$elapsed3,$elapsed4,$elapsed5,$elapsed6,$elapsed7,$elapsed8,$elapsed9,$elapsed10);
    }

    return $report;
}

sub stats_to_chartdata
{
    my $self = shift;
    my $stats = shift;
    my $start_timestamp = shift;
    my $end_timestamp = shift;
    my $interval = shift;
    
    my $times = [ sort { $a <=> $b } keys %$stats ];

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
            push @{$data[2]}, $stats->{$timestamp}->{'blocked_spam'};
            push @{$data[3]}, $stats->{$timestamp}->{'blocked_greylisted'};
            push @{$data[4]}, $stats->{$timestamp}->{'blocked_blacklisted'};
            push @{$data[5]}, $stats->{$timestamp}->{'blocked_virus'};
            push @{$data[6]}, $stats->{$timestamp}->{'blocked_banned'};
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

    return $wcc_arr;
}

sub find_mail_status
{
    my $self = shift;
    my $stats = shift;
    my $sqlgrey = shift;
    my $amavis = shift;
    my $count = shift || 1;

    # accepted
    if ($sqlgrey < 20)
    {
        if (defined $amavis)
        {
            # passed
            if ($amavis <20)
            {
                # clean
                if ($amavis == 10)
                {
                    $stats->{'passed_clean'} += $count;    
                }
                # spammy
                elsif ($amavis == 11)
                {
                    $stats->{'passed_spam'} += $count;
                }
            }
            # blocked virus/banned/spam
            else
            {
                # virus
                if ($amavis == 20)
                {
                    $stats->{'blocked_virus'} += $count;
                }
                # banned
                elsif ($amavis == 21)
                {
                    $stats->{'blocked_banned'} += $count;
                }
                # spam
                elsif ($amavis == 22)
                {
                    $stats->{'blocked_spam'} += $count;
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
            $stats->{'blocked_greylisted'} += $count;
        }
        # blacklisted
        elsif ($sqlgrey == 22 || $sqlgrey == 23)
        {
            $stats->{'blocked_blacklisted'} += $count;
        }
    }
    $stats->{'sum'} += $count;
    return $stats;
}

sub find_mail_status_string
{
    my $self = shift;
    my $sqlgrey = shift;
    my $amavis = shift;

    # accepted
    if ($sqlgrey < 20)
    {
        # passed
        if ($amavis <20)
        {
            # clean
            if ($amavis == 10)
            {
                return 'passed_clean';
            }
            # spammy
            elsif ($amavis == 11)
            {
                return 'passed_spam';
            }
        }
        # blocked virus/banned/spam
        else
        {
            # virus
            if ($amavis == 20)
            {
                return 'blocked_virus';
            }
            # banned
            elsif ($amavis == 21)
            {
                return 'blocked_banned';
            }
            # spam
            elsif ($amavis == 22)
            {
                return 'blocked_spam';
            }
        }
    }
    # blocked
    else
    {
        # greylisted
        if ($sqlgrey < 22)
        {
            return 'blocked_greylisted';
        }
        # blacklisted
        elsif ($sqlgrey == 22 || $sqlgrey == 23)
        {
            return 'blocked_blacklisted';
        }
    }
}

sub create_report
{
    my $self = shift;
    my $stats = shift;
    my $interval = shift;
    my $time_offset = shift; # how far to go back in the past

    my $sum_stats = {
        passed_clean => 0,
        passed_spam => 0,
        blocked_greylisted => 0,
        blocked_blacklisted => 0,
        blocked_virus => 0,
        blocked_banned => 0,
        blocked_spam => 0,
    };

    # sum up
    foreach my $timestamp (keys %$stats)
    {
        foreach my $key (keys %{$stats->{$timestamp}})
        {
            $sum_stats->{$key} += $stats->{$timestamp}->{$key};
        }
    }
 
    my $current_timestamp = $self->current_timestamp;                      
    my $start_timestamp = $current_timestamp - $time_offset;
    my $end_timestamp = $current_timestamp;

    my $chart_data = $self->stats_to_chartdata($stats, $start_timestamp, $end_timestamp, $interval);

    my $report = new Underground8::Report::LimesAS::MailStats;

    $report->chart_data($chart_data);
    $report->start_timestamp($start_timestamp);
    $report->end_timestamp($end_timestamp);
    $report->passed_clean($sum_stats->{'passed_clean'});
    $report->passed_spam($sum_stats->{'passed_spam'});
    $report->blocked_greylisted($sum_stats->{'blocked_greylisted'});
    $report->blocked_blacklisted($sum_stats->{'blocked_blacklisted'});
    $report->blocked_virus($sum_stats->{'blocked_virus'});
    $report->blocked_banned($sum_stats->{'blocked_banned'});
    $report->blocked_spam($sum_stats->{'blocked_spam'});

    return $report; 
}

sub livelog
{
    my $self = shift;
    my $limit = shift || 50;
    
    my $dbh = $self->dbh;

    my $statement = "SELECT UNIX_TIMESTAMP(received_log) AS received_log, msg_id, mail_from, rcpt_to, client_ip, subject, sqlgrey, amavis, amavis_hits, amavis_detail, delay FROM mail_livelog ORDER BY received_log DESC LIMIT $limit;";

    my $mail_arrayref = $dbh->selectall_arrayref($statement);
    my $mails;

    foreach my $row (@$mail_arrayref)
    {
        my ($received_log,$msg_id,$mail_from,$rcpt_to,$client_ip,$subject,$sqlgrey,$amavis,$amavis_hits,$amavis_detail,$delay) = @$row;
        my $mail = {
            received_log    => $received_log,
            msg_id          => $msg_id,
            mail_from       => $mail_from,
            rcpt_to         => $rcpt_to,
            client_ip       => $client_ip,
            subject         => $subject,
            amavis_hits     => $amavis_hits,
            amavis_detail   => $amavis_detail,
            delay           => $delay,
        };

        my $status = $self->find_mail_status_string($sqlgrey,$amavis);

        $mail->{'status'} = $status;

        push @$mails, $mail;
    }

    my $report = new Underground8::Report::LimesAS::MailLivelog;

    $report->mails($mails);
    return $report;
}

1;

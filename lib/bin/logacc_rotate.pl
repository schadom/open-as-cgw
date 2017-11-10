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

my $statements = [
    'DELETE FROM domain_livelog WHERE received_log < DATE_SUB( NOW( ) , INTERVAL 48 HOUR ) ;',
    'DELETE FROM domain_from_hourly WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 32 DAY ) ;',
    'DELETE FROM domain_to_hourly WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 32 DAY ) ;',
    'DELETE FROM domain_from_daily WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 10 YEAR ) ;',
    'DELETE FROM domain_to_daily WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 10 YEAR ) ;',

    'DELETE FROM mail_livelog WHERE received_log < DATE_SUB( NOW( ) , INTERVAL 48 HOUR ) ;',
    'DELETE FROM mail_hourly WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 32 DAY ) ;',
    'DELETE FROM mail_daily WHERE received_start < DATE_SUB( CURDATE( ) , INTERVAL 10 YEAR ) ;',
];

foreach my $statement (@$statements)
{
    $dbh->do($statement);
}

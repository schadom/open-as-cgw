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


#
# create table index on 3 fields in table mail_livelog in rtlog database
#

use strict;
use warnings;
use DBI;

my $dbname = "rt_log";
my $dbhost = "localhost";
my $dbuser = "root";
#my $dbpwd = "";
my $dbpwd  = "loltruck2000";
my $dsn = "DBI:mysql:database=$dbname;host=$dbhost;";
my $dbh = DBI->connect($dsn, $dbuser, $dbpwd, {
                            RaiseError => 1,
                            AutoCommit => 1,
                        });

select STDOUT; $| = 1;

### INDEX mail_livelog ## greylist_info ###

my $query = "SHOW INDEX FROM mail_livelog FROM rt_log WHERE Key_name = 'greylist_info'";
my $row_ref  = $dbh->selectrow_arrayref($query);

unless ($row_ref)
{
    # create index on table
    print "Creating table index (mail_livelog.greylist_info)...";
    my $create_index = "ALTER TABLE `mail_livelog` ADD INDEX `greylist_info` ( `mail_from` ( 10 ) , `rcpt_to` ( 10 ) , `client_ip` ( 10 ) ) ;";
    $dbh->do($create_index);        
    print "done!\n";
}
else
{
    print "Index found (mail_livelog.greylist_info)... skipping\n";
}

### INDEX mail_livelog ## status ###

$query = "SHOW INDEX FROM mail_livelog FROM rt_log WHERE Key_name = 'status'";
$row_ref  = $dbh->selectrow_arrayref($query);

unless ($row_ref)
{
    # create index on table
    print "Creating table index (mail_livelog.status)...";
    my $create_index = "ALTER TABLE `mail_livelog` ADD INDEX `status` ( `sqlgrey` , `amavis` ) ;";
    $dbh->do($create_index);        
    print "done!\n";
}
else
{
    print "Index found (mail_livelog.status)... skipping\n";
}

### INDEX mail_livelog ## received_log ###

$query = "SHOW INDEX FROM mail_livelog FROM rt_log WHERE Key_name = '_received_log'";
$row_ref  = $dbh->selectrow_arrayref($query);

unless ($row_ref)
{
    # create index on table
    print "Creating table index (mail_livelog._received_log)...";
    my $create_index = "ALTER TABLE `mail_livelog` ADD INDEX `_received_log` ( `received_log` ) ;";
    $dbh->do($create_index);        
    print "done!\n";
}
else
{
    print "Index found (mail_livelog._received_log)... skipping\n";
}


### INDEX domain_livelog ## status ###

$query = "SHOW INDEX FROM domain_livelog FROM rt_log WHERE Key_name = 'status'";
$row_ref  = $dbh->selectrow_arrayref($query);

unless ($row_ref)
{
    # create index on table
    print "Creating table index (domain_livelog.status)...";
    my $create_index = "ALTER TABLE `domain_livelog` ADD INDEX `status` ( `sqlgrey` , `amavis` ) ;";
    $dbh->do($create_index);        
    print "done!\n";
}
else
{
    print "Index found (domain_livelog.status)... skipping\n";
}

### INDEX domain_livelog ## received_log ###

$query = "SHOW INDEX FROM domain_livelog FROM rt_log WHERE Key_name = '_received_log'";
$row_ref  = $dbh->selectrow_arrayref($query);

unless ($row_ref)
{
    # create index on table
    print "Creating table index (domain_livelog.received_log)...";
    my $create_index = "ALTER TABLE `domain_livelog` ADD INDEX `_received_log` ( `received_log` ) ;";
    $dbh->do($create_index);        
    print "done!\n";
}
else
{
    print "Index found (domain_livelog._received_log)... skipping\n";
}

### GRANT rights for user rt_log ###

print "Revoking all privileges for rtlog...";
$query = "REVOKE ALL PRIVILEGES ON `rt\_log`.* FROM 'rt_log'\@'localhost'";
$dbh->do($query);
print "done\n";
print "Granting new privileges for rtlog...";
$query = "GRANT SELECT ,INSERT ,UPDATE ,DELETE, CREATE TEMPORARY TABLES ON `rt\_log`.* TO 'rt_log'\@'localhost' WITH MAX_USER_CONNECTIONS 10;";
$dbh->do($query);
print "done\n";


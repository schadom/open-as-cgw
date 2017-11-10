#!/usr/bin/perl -W
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

my $days = 1;    #How old may records be

sub mailcount();

my $dbh = DBI->connect( 'DBI:mysql:database=mailq;host=localhost',
    'mailq', 'mailq', { AutoCommit => 0 } )
  || die "Can't open DB connection: $!";

my $time = time;
$time -= ( $time % 300 );
my ( $count, $size ) = mailcount();

my $delete =
  $dbh->prepare( 'DELETE FROM mcount WHERE count_time<'
      . ( $time - ( 24 * 60 * 60 * $days ) ) );
my $insert =
  $dbh->prepare(
        'INSERT INTO mcount(count_time,mail_count,size) VALUES(' . $time . ','
      . $count . ','
      . $size
      . ')' );

$delete->execute;
$insert->execute;

$dbh->disconnect();

sub mailcount() {
    my %messages;
    my $msg_count = 0;

    open( MAILQ, '/usr/bin/mailq|' ) or die "Can't execute mailq: $!";

    my $line;

    # Read /usr/bin/mailq info and store all information in a hash of hashes
    while ( $line = <MAILQ> ) {
        return ( 0, 0 ) if ( $line =~ /empty/ );
        chomp $line;
        next if $line =~ /^$/ or $line =~ /^-/;
        my ( $id, $size, $time, $sender, $recipient, $message );
        ( $id, $size, $time, $sender ) =
          ( $line =~ /(\S{10})\s+(\d+)\s(.{19})\s\s(.+)/ );
        $line = <MAILQ>;
        chomp $line;
        $line =~ /^\((.+)\)$/;
        $message = $1;
        $line    = <MAILQ>;
        chomp $line;
        $line =~ s/\s//g;
        $line =~ /^(.+\@.+)$/;
        $recipient = $1;
        $messages{$id} = {
            size      => $size,
            time      => $time,
            sender    => $sender,
            recipient => $recipient,
            message   => $message
        };
        $msg_count++;
    }

    close MAILQ;

    $size = 0;

    foreach my $key ( keys %messages ) {
        $size += $messages{$key}->{size};
    }

    #Return message count and total size
    return ( $msg_count, $size );
}

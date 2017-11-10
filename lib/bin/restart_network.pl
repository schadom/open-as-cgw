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


use strict;
unless (defined $ARGV[0] && length $ARGV[0])
{
    die "No Network Interface Submitted\n";
}
my $iface = $ARGV[0];
sleep 4;
system("/usr/bin/sudo /sbin/ifdown $iface > /dev/null 2<&1");
system("/usr/bin/sudo /sbin/route del default > /dev/null 2>&1");
system("/usr/bin/sudo /sbin/ifup $iface > /dev/null 2<&1");

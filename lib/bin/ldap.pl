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


BEGIN {
    my $libpath = $ENV{'LIMESLIB'};
    my $guipath = $ENV{'LIMESGUI'};
    if($libpath)
    {
        print "*** DEVEL ENVIRONMENT ***\nUsing libpath: $libpath\n";
        unshift(@INC,"$libpath/lib/");
    }
    if($guipath)
    {
        print "Using guipath: $guipath\n";
        unshift(@INC,"$guipath/etc/");
    }
}

use Data::Dumper;
use DateTime;
use LockFile::Simple qw(lock trylock unlock);

use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::Execution;
use Underground8::Appliance::LimesAS;
use Underground8::Utils;

my $appliance = new Underground8::Appliance::LimesAS;
$appliance->load_config();


my $md5before = `md5sum /etc/postfix/transport`;
$md5before = chomp($md5before);

$appliance->antispam->create_ldap_maps;

$appliance->antispam->commit("override_ldap");

my $md5after = `md5sum /etc/postfix/transport`;
$md5after = chomp($md5after);

if($md5before ne $md5after){
	print "transport file changed, restarting GUI\n";
	system("/etc/init.d/nginx restart");
} else {
	print "transport file did not change\n";
}




#my $test = $appliance->antispam->usermaps();
#print Dumper $test;

exit 0;



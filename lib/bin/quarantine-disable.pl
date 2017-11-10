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


# quarantine-disable - disable script
# 11/13/2008 - Created by Andreas Starlinger

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

use strict;
use warnings;

### main

my $appliance = new Underground8::Appliance::LimesAS;
$appliance->load_config();
# disable quarantine
$appliance->antispam->quarantine_enabled(0);
$appliance->antispam->commit();
log_message("info", "quarantine disabled");
$appliance->quarantine->global_disable($appliance->antispam->get_mails_destiny,$appliance->antispam->get_admin_boxes);
$appliance->quarantine->commit();
log_message("info", "global disabled");

my $result = safe_system($g->{'cmd_webserver_restart'});
if ($result)
{
        log_message("info", "webserver restarted");
}
else
{
        log_message("err", "webserver restart failed");
}

exit 0;


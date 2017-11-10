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
    my $homedir = (getpwuid($<))[7];
    unshift(@INC,"$homedir/devel/limesas/lib/trunk/lib");
}
use strict;
use Underground8::Appliance::LimesAS;

my $appliance = new Underground8::Appliance::LimesAS();
$appliance->system->load_config;
if ($appliance->system->net_interface->notify)
{
    $appliance->system->net_revoke_settings();
    $appliance->system->net_notify('0');
}
$appliance->system->commit();
$appliance->system->net_interface->slave->revoke_crontab($appliance->system->net_name);
$appliance->system->net_restart_webserver();

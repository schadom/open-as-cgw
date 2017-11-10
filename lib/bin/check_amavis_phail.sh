#!/bin/bash

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


# This file checks the postfix mailq, if there are refused connections when connecting
# to an Amavis port, namely 10024-32. This may happen on the AS for unknown reasons, when
# the system load is critically high - if so, restart Amavis and flush queue.


NUM_PHAILS=`/usr/bin/mailq | grep ":100..: Connection refused" | wc -l`

if [ "$NUM_PHAILS" -gt "0" ]; then
	/etc/init.d/amavis restart
	sleep 30
	/usr/sbin/postqueue -f
	/usr/bin/logger -p "local0.warn" "check_amavis_phail.sh: Amavis restarted"
fi



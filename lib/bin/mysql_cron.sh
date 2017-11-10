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


# nightly script run by cron

# repair the tables ... this is a safety thing
# nothing will be done if everything is alright
echo "====================================================="
echo "Repairing started"
/bin/date
/usr/local/bin/mysql_tables.sh --repair sqlgrey
/usr/local/bin/mysql_tables.sh --repair rt_log
/usr/local/bin/mysql_tables.sh --repair mysql
/usr/local/bin/mysql_tables.sh --repair smtp_auth
/usr/local/bin/mysql_tables.sh --repair amavis
/usr/local/bin/mysql_tables.sh --repair mailq
echo "Repairing done"
echo "====================================================="
/bin/date

# now we start the rotating
echo "====================================================="
echo "Rotating started"
# /usr/bin/sudo -u limes /usr/local/bin/domain_logacc.pl  # we don't do domain stats anymore as of 2.0.1
/usr/bin/sudo -u limes /usr/local/bin/logacc_rotate.pl
echo "Rotating done"
echo "====================================================="
/bin/date



#### Amavis DB cleanup
echo "Starting hyper1337 Amavis DB cleanup"
echo "===================================================="

# Delete msgs older than 4 weeks
echo "Executing: DELETE FROM msgs WHERE UNIX_TIMESTAMP()-time_num > 28*24*60*60"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "DELETE FROM msgs WHERE UNIX_TIMESTAMP()-time_num > 28*24*60*60;"

# Delete msgs older than 1 hour AND empty content
echo "Executing: DELETE FROM msgs WHERE UNIX_TIMESTAMP()-time_num > 60*60 AND content IS NULL;"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "DELETE FROM msgs WHERE UNIX_TIMESTAMP()-time_num > 60*60 AND content IS NULL;"

# Delete quarantine msgs which do not appear in msgs table anymore
echo "Executing: DELETE quarantine FROM quarantine LEFT JOIN msgs USING(mail_id) WHERE msgs.mail_id IS NULL;"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "DELETE quarantine FROM quarantine LEFT JOIN msgs USING(mail_id) WHERE msgs.mail_id IS NULL;"

# ...
echo "Executing: DELETE msgrcpt FROM msgrcpt LEFT JOIN msgs USING(mail_id) WHERE msgs.mail_id IS NULL;"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "DELETE msgrcpt FROM msgrcpt LEFT JOIN msgs USING(mail_id) WHERE msgs.mail_id IS NULL;"

# ...
echo "Executing: DELETE FROM maddr WHERE NOT EXISTS (SELECT sid FROM msgs WHERE sid=id) AND NOT EXISTS (SELECT rid FROM msgrcpt WHERE rid=id);"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "DELETE FROM maddr WHERE NOT EXISTS (SELECT sid FROM msgs WHERE sid=id) AND NOT EXISTS (SELECT rid FROM msgrcpt WHERE rid=id);"

# Optimize tables
echo "Executing: OPTIMIZE TABLE msgs, msgrcpt, maddr, quarantine;"
/bin/date
/usr/bin/mysql -u root -ploltruck2000 -h localhost -D amavis -e "OPTIMIZE TABLE msgs, msgrcpt, maddr, quarantine;"

/bin/date
echo "Amavis DB cleanup done"
echo "===================================================="



# optimizing the tables is important ;)
echo "====================================================="
echo "Optimizing started"
/usr/local/bin/mysql_tables.sh --optimize sqlgrey
/usr/local/bin/mysql_tables.sh --optimize rt_log
/usr/local/bin/mysql_tables.sh --optimize amavis

echo "Optimizing done"
echo "====================================================="
echo "====================================================="
echo "MySQL cron done"
/bin/date
echo ""
echo ""
echo "Sleeping for 360 seconds..."
/bin/sleep 360
echo "Sleeping done"

echo "Repairing sqlgrey again ... don't know why we need that"
echo "====================================================="
echo "Repairing started"
/bin/date
/usr/local/bin/mysql_tables.sh --repair sqlgrey
echo "Repairing done"
echo "====================================================="
/bin/date


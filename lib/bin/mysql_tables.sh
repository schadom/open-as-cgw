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



# this shell script finds all the tables for a database and run a command against it

DBNAME=$2

printUsage() {
  echo "Usage: $0"
  echo " --optimize <dbname>"
  echo " --repair <dbname>"
  return
}


doAllTables() {
  # get the table names
  TABLENAMES=`mysql --defaults-extra-file=/etc/mysql/debian.cnf -D $DBNAME -e "SHOW TABLES\G;"|grep 'Tables_in_'|sed -n 's/.*Tables_in_.*: \([_0-9A-Za-z]*\).*/\1/p'`

  # loop through the tables and optimize them
  for TABLENAME in $TABLENAMES
  do
    mysql --defaults-extra-file=/etc/mysql/debian.cnf -D $DBNAME -e "$DBCMD TABLE $TABLENAME;"
  done
}

if [ $# -eq 0 ] ; then
  printUsage
  exit 1
fi

case $1 in
  --optimize) DBCMD=OPTIMIZE; doAllTables;;
  --repair) DBCMD=REPAIR; doAllTables;;
  --help) printUsage; exit 1;;
  *) printUsage; exit 1;;
esac

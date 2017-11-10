#!/bin/sh -e
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



if [ "$1" != "--force" -a -f /etc/nginx/ssl/default.pem ] ||
   [ "$1" != "--force" -a -f /etc/nginx/ssl/default.key ]; then
   echo "/etc/nginx/ssl/default.pem or /etc/nginx/ssl/default.key exists!  Use \"$0 --force.\""
   exit 0
fi

if [ "$1" = "--force" ]; then
  shift
fi     

echo
echo creating selfsigned certificate
export RANDFILE=/dev/random
openssl req $@ -config /etc/nginx/ssleay.cnf \
  -new -x509 -nodes -out /etc/nginx/ssl/default.pem \
  -keyout /etc/nginx/ssl/default.key -days 7300

chmod 600 /etc/nginx/ssl/default.pem
chmod 600 /etc/nginx/ssl/default.key

ln -sf /etc/nginx/ssl/default.pem \
  /etc/nginx/ssl/`/usr/bin/openssl \
  x509 -noout -hash < /etc/nginx/ssl/default.pem`.0

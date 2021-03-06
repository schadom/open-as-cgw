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


# Virtual Setup script in order to initialize virtual appliance
# Erik Sonnleitner, es@delta-xi.net


# W O R K F L O W:
#   1. On very first start of virtual appliance, VKEY is generated (if unexistent)
#   2. If VCONFIG doesn't exist or contains value 'AX', exit
#   3. VCONFIG is generated by CLI command 'setup-activation' and defines which type of virtual appliance we're dealing with
#   4. Once the CLI created VCONFIG, this script is ran again
#   5. If VCONFIG exists and is valid (non-'AX') <F2>


PATH_VCONFIG="/etc/open-as-cgw/conf/vconfig"
PATH_VKEY="/etc/open-as-cgw/conf/vkey"
PATH_SERIAL="/etc/open-as-cgw/sn"
NET_IF="eth0"
RAND_FILE="/tmp/`uuidgen`"


# Make sure motd/issue is wiped for CLI access
echo "" > /etc/motd
echo "Open AS Communication Gateway" > /etc/issue
echo "Open AS Communication Gateway" > /etc/issue.net

# If VKEY doesn't yet exist, generate
if [ ! -e $PATH_VKEY ]; then
	echo "No virtual key found, generating..."

	# Generate random key
	ssh-keygen -t rsa -q -f $PATH_VKEY -N ""
	rm $PATH_VKEY.pub
fi

# If VCONFIG exists, we handle a virtual appliance
#if [ ! -e $PATH_VCONFIG ]; then
#	echo "AS does not seem to run on a virtual appliance. Skipping VSetup."
#	exit 0;
#fi

# Set correct permissions and touch files (those must exist with correct perms for CLI-activation!)
touch $PATH_VCONFIG $PATH_SERIAL
chown limes:limes $PATH_VCONFIG $PATH_SERIAL
chmod g+w $PATH_VCONFIG $PATH_SERIAL

# $PATH_VCONFIG contains the 2-char suffix for the virtual serial number
# 'AX' is the predefined default value for non-configured virtual appliances
#SERIAL_SUFFIX=`cat $PATH_VCONFIG`
#if [ "$SERIAL_SUFFIX" == "AX" ]; then
#	echo "No model information entered yet. Exiting.";
#	exit 0;
#fi

SERIAL_SUFFIX="AF"

## If serial number doesn't exist (or file is empty), create
if [ ! -s $PATH_SERIAL ]; then
	# Fetch mac address
	MAC_ADDR=`ip addr show $NET_IF | grep "link/ether" | awk '{ print $2 }'`

	# Concat vkey and mac address to generate base34 S/N
	touch $RAND_FILE
	cat $PATH_VKEY > $RAND_FILE
	echo "$MAC_ADDR" >> $RAND_FILE

	# Create basic sha512 hash 
	SHA512SUM=`sha512sum $RAND_FILE | cut -d' ' -f1`
	
	# Encode to standard base64 and cut newlines from output
	BASE64=`echo "$SHA512SUM" | openssl enc -base64 | tr -d '\n'`

	# Trim to base34 (0-9, A-Z without 'I' and 'O')
	BASE34=`echo "$BASE64" | tr -d "[:lower:]" | tr -d 'I' | tr -d 'O'`

	# Delete temporary stuff
	rm $RAND_FILE

	# Write final serial number
	FINAL_SERIAL=${BASE34:1:9}${SERIAL_SUFFIX}
	echo "$FINAL_SERIAL" > $PATH_SERIAL
else
	echo "VKEY found at $PATH_VKEY, VCONFIG found at $PATH_VCONFIG [$SERIAL_SUFFIX]."
	echo "Serial is found at $PATH_SERIAL"
fi

exit 0

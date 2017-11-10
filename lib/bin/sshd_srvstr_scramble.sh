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


# Erik Sonnleitner, underground_8
# This script will try to find the network service string of an ubuntu-derived SSHd binary,
# and replace it with randomized content. This means that the exact OpenSSH version will
# not be revealed on "nc sshdhost sshport" or similar connects.
# Currently, only ubuntu-based ssh daemons are recognized, but this can be configured
# through the $SRV_REGEX variable.
# Actual substitution will not be performed if DRY_RUN is set.

#DRY_RUN="1"
SRV_REGEX="^OpenSSH.*ubuntu"
SRV_MAX_LEN=55					# "real" service-string length should be about 31 chars
BACKUP_EXT=".orig_unpatched"

# Check for arg
if [ -z $1 ]; then
	echo "Usage: $0 <sshd binary>";
	exit 0;
fi

# Some filetype checks
if [ ! -e $1 ]; then
	echo "$1 does not exist. Aborting...";
	exit 0;
elif [ ! -x $1 ]; then
	echo "$1 is no executable. Aborting...";
	exit 0;
elif [ ! -r $1 ]; then
	echo "$1 isn't readable. Aborting...";
	exit 0;
elif [ ! -w $1 ]; then
	echo "$1 isn't writable. Aborting...";
	exit 0;
fi;

# Get service string
SSHD_SRV_STR=`strings $1 | grep -E "${SRV_REGEX}"`
if [ -z "$SSHD_SRV_STR" ]; then
	echo "Couldn't determine SSHd service string. Aborting..."
	exit 0
elif [ ${#SSHD_SRV_STR} -gt $SRV_MAX_LEN ]; then
	echo "Suspicious service string length: ${#SSHD_SRV_STR}. Aborting..."
	exit 0
else
	echo "Service string found:    <$SSHD_SRV_STR> (${#SSHD_SRV_STR} bytes)"
fi

# Generate entropic replacement (of exactly the same length)
for i in `seq 1 ${#SSHD_SRV_STR}`; do
	REPLACEMENT="${REPLACEMENT}`head -c 3 /dev/urandom | md5sum | head -c1`";
done
echo "Entropic replacement:    <$REPLACEMENT>";

if [ ! -z $DRY_RUN ]; then
	echo "DRY_RUN set: Not going to replace original file $1"
else
	# Hash original binary
	MD5_SSHD_ORIGINAL=`md5sum ${1} | awk '{ print $1 }'`

	# Substitute given bytes in original binary and save to tmporary file
	sed -i$BACKUP_EXT -e "s/${SSHD_SRV_STR}/${REPLACEMENT}/" $1 
	RC=$?

	# Hash patched binary
	MD5_SSHD_MODIFIED=`md5sum ${1} | awk '{ print $1 }'`

	if [ $RC -eq 0 ]; then
		if [ "$MD5_SSHD_ORIGINAL" != "$MD5_SSHD_MODIFIED" ]; then
			echo "Substitution has been successfully accomplished."
		else
			echo "Warning: Nothing substituted, file unchanged."
		fi
	else
		echo "Error: Substitution of service string in binary file failed (sed returned error code = $RC)";
	fi
fi

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



# Set path.. this -IS- important, especially for sbin's
PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

# Actually create a new swap unit
create_swap_unit() {
	UNIT_PATH=$1

	if [ -z $UNIT_PATH ]; then
		echo "create_swap_unit() didn't receive a unit path, exiting."
		exit 12
	fi

	if [ $HDD_FREE -le $SWAP_UNIT_SIZE ]; then
		echo "Not enough free HDD space for new swap unit, exiting."
		exit 3
	fi

	dd if=/dev/zero of=$UNIT_PATH bs=1k count=$SWAP_UNIT_SIZE &> /dev/null
	if [ $? -ne 0 ]; then
		echo "Error creating new swap unit file, exiting."
		rm $UNIT_PATH &> /dev/null
		exit 9
	fi

	mkswap $UNIT_PATH &> /dev/null
	if [ $? -ne 0 ]; then
		echo "Error formatting new swap unit, exiting."
		rm $UNIT_PATH &> /dev/null
		exit 10
	fi

	swapon $UNIT_PATH &> /dev/null
	if [ $? -ne 0 ]; then
		echo "Error activating new swap unit, exiting."
		rm $UNIT_PATH &> /dev/null
		exit 11
	fi
}

#######################################################################################
# Code start

echo "Virtual swap controller started at `date`"

# Exit if we're virtual
if [ ! -e "/etc/open-as-cgw/conf/vconfig" ]; then
	echo "This appliance doesn't seem to run in virtual environment, exiting."
	exit 0;
fi

# Get memory info
MEMINFO="/proc/meminfo"
SWAP_FREE=`cat $MEMINFO | grep "SwapFree:" | grep kB | awk '{ print $2 }' 2>/dev/null`
SWAP_TOTAL=`cat $MEMINFO | grep "SwapTotal:" | grep kB | awk '{ print $2 }' 2>/dev/null`
MEM_TOTAL=`cat $MEMINFO | grep "MemTotal:" | grep kB | awk '{ print $2 }' 2>/dev/null`

# Check if we received valid memory values
if [ -z $SWAP_FREE -o -z $SWAP_TOTAL -o -z $MEM_TOTAL ]; then
	echo "Error determining Swap/Memory usage"
	exit 1
fi

# Predefine swap unit-size to 1/2 GiB, definition unit is KiB
SWAP_UNIT_SIZE="524288"
SWAP_FREE_THRESHOLD="15" # minimum free swap in % before creating new unit
SWAP_UNIT_FILEPREFIX="/tmp/as-swap-unit"
SWAP_UNIT_COUNT=`ls -lh $SWAP_UNIT_FILEPREFIX* 2>/dev/null | wc -l`
SWAP_UNIT_NEXT=`expr $SWAP_UNIT_COUNT + 1`
SWAP_FREE_PERCENT=`if [ $SWAP_TOTAL -ne 0 ]; then expr $SWAP_FREE \* 100 \/ $SWAP_TOTAL; else echo 0; fi`
HDD_FREE=`df -P | grep '/dev/mapper/system-root' | awk '{ print $4 }'`

if [ -z $HDD_FREE ]; then
	echo "HDD size not detectable (/dev/mapper/system-root inexistent, possibly not virtual))"
	exit 3;
fi

# Create initial swap, if not existent
if [ $SWAP_UNIT_COUNT -eq 0 ]; then
	echo "No swap found, creating initial swap unit, please wait..."
	create_swap_unit "${SWAP_UNIT_FILEPREFIX}1"
	echo "Initial swap unit created and activated."
	exit 0;
fi

# If current total swap > main memory, give up
if [ `expr $SWAP_UNIT_COUNT \* $SWAP_UNIT_SIZE` -ge $MEM_TOTAL ]; then
	echo "Swap size already exceeds main memory size, exiting."
	exit 2;
fi

# If free swap is less than $SWAP_FREE_THRESHOLD percent, initiate new unit
if [ $SWAP_FREE_PERCENT -ge $SWAP_FREE_THRESHOLD ]; then
	echo "Enough swap available, nothing to do for now."
	exit 0
else
	echo "Swap-space is getting low, creating new Swap Unit, please wait..."
	create_swap_unit "${SWAP_UNIT_FILEPREFIX}${SWAP_UNIT_NEXT}"
	echo "Swap unit #$SWAP_UNIT_NEXT created and activated."
	exit 0
fi



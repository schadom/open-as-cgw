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


# This script extends the root lvm to a second harddrive, if the harddrive exists
# should'nt hurt if this is executed and there is nothing to do ...

HDTARGET="/dev/sdb"


/sbin/pvcreate $HDTARGET
/sbin/vgextend system $HDTARGET
/sbin/lvresize -l 100%VG /dev/system/root
/sbin/resize2fs /dev/system/root


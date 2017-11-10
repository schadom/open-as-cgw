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

# temp storages
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

# trap and del tmp files
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

##
## show appliance info
##
function show_info(){
}

##
## configure network settings
##
function configure_network(){
}

##
## restart mgmt services
##
function do_restart(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 	# box title 
	dialog --backtitle "The management services are restarting now." --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
	sudo service openas-backend restart
	sudo service nginx restart
}

##
## reboot appliance
##
function do_reboot(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 	# box title 
	dialog --backtitle "The appliance is rebooting in 15 seconds." --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
	sleep 15 ; sudo shutdown -r now
}

##
## shutdown appliance
##
function do_shutdown(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 	# box title 
	dialog --backtitle "The appliance is shutting down in 15 seconds." --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
	sleep 15 ; sudo shutdown -h now
}

##
## enable/disable ssh
##
function toggle_ssh(){
}

# set infinite loop
while true
do

	### display main menu ###
	dialog --cancel-label "Exit" \
		   --title "[ Open AS Console Menu ]" \
	       --menu "Please use the arrow up/down keys to navigate." 15 40 8 \
			1 "Show appliance info" \
			2 "Configure networking" \
			3 "Restart Management Services" \
			4 "Reboot appliance" \
			5 "Shutdown appliance" \
			6 "Enable/Disable SSH" \
			7 "Open console" \
			8 "Logout" 2>"${INPUT}"

	# get selected item 
	menuitem=$(<"${INPUT}")

	# make decsion 
	case $menuitem in
		1) show_info;;
		2) configure_network;;
		3) do_restart;;
		4) do_reboot;;
		5) do_shutdown;;
		6) toggle_ssh;;
		7) bash; break;;
		8) exit; break;;
	esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

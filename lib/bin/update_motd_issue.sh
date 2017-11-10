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

# Vars
CFG_PATH='/etc/open-as-cgw'
REVISION=`cat ${CFG_PATH}/versions | grep -e '^revision.*' | cut -d'=' -f2 2>/dev/null`
VERSION_MAIN=`cat ${CFG_PATH}/versions | grep -e '^main.*' | cut -d'=' -f2 2>/dev/null`
VERSION_SEC=`cat ${CFG_PATH}/avail_secversion 2>/dev/null`
HOSTNAME=`hostname --fqdn 2>/dev/null`
IPADDR=`hostname -I 2>/dev/null`
LOADAVG=`cat /proc/loadavg | awk '{print $1, $2, $3}' 2>/dev/null`
LAST_UPDATE=`cat ${CFG_PATH}/update_timestamp | sed 's/_/ /' | sed 's/-/:/g' 2>/dev/null`
SERVICE_STATUS='\033[0;32mHealthy\033[0m' #TODO: add check logic or cmd 
CLUSTER_STATUS='\033[0;35mNot Active\033[0m' #TODO: add check logic or cmd 
MEM_TOTAL=`cat /proc/meminfo | grep MemTotal | awk '{print $2 $3}' 2>/dev/null`
MEM_FREE=`cat /proc/meminfo | grep MemFree | awk '{print $2 $3}' 2>/dev/null`
MEM_STAT="${MEM_FREE} / ${MEM_TOTAL}"
UPTIME_S=`cat /proc/uptime | awk '{ print $1 }' | cut -d'.' -f1`
UPTIME_M="$(expr $UPTIME_S \/ 60 \% 60)m"
UPTIME_H="$(expr $UPTIME_S \/ 60 \/ 60 \% 24)h"
UPTIME_D="$(expr $UPTIME_S \/ 60 \/ 60 \/ 24)d"

# Update etc/issue
echo -e "\033[0;34m  ____                  ___   ____" > /etc/issue
echo " / __ \___  ___ ___    / _ | / __/" >> /etc/issue
echo "/ /_/ / _ \/ -_) _ \  / __ |_\ \  " >> /etc/issue
echo "\____/ .__/\__/_//_/ /_/ |_/___/  " >> /etc/issue
echo -e "    /_/                           \033[0m\n" >> /etc/issue
echo -e "\033[1;36m[ Open AS Communication Gateway $VERSION_MAIN - www.openas.org ]\033[0m" >> /etc/issue
echo -en "\033[1;36m[ Hostname: \033[0;37m$HOSTNAME \033[1;36m] \033[0m" >> /etc/issue
echo -e "\033[1;36m[ IP: \033[0;37m$IPADDR\033[1;36m]\033[0m" >> /etc/issue
echo -e "\033[1;36m[ To manage this appliance visit \033[0;37mhttps://$IPADDR\033[1;36m]\033[0m\n" >> /etc/issue

# Update MOTD
echo -e "\033[0;34m  ____                  ___   ____" > /etc/motd
echo " / __ \___  ___ ___    / _ | / __/" >> /etc/motd
echo "/ /_/ / _ \/ -_) _ \  / __ |_\ \  " >> /etc/motd
echo "\____/ .__/\__/_//_/ /_/ |_/___/  " >> /etc/motd
echo -e "    /_/                           \033[0m" >> /etc/motd
echo -e "" >> /etc/motd
echo -e "\033[1;36m[ Open AS Communication Gateway $VERSION_MAIN - www.openas.org ]\033[0m" >> /etc/motd 
echo -en "\033[1;36m[ Hostname: \033[0;37m$HOSTNAME \033[1;36m] \033[0m" >> /etc/motd
echo -e "\033[1;36m[ IP: \033[0;37m$IPADDR\033[1;36m]\033[0m" >> /etc/motd
echo -en "\033[1;36m[ Services Status: $SERVICE_STATUS \033[1;36m] \033[0m" >> /etc/motd
echo -e "\033[1;36m[ Cluster Status: $CLUSTER_STATUS \033[1;36m] \033[0m" >> /etc/motd
echo -en "\033[1;36m[ Uptime: \033[0;37m$UPTIME_D $UPTIME_H $UPTIME_M \033[1;36m] \033[0m" >> /etc/motd
echo -en "\033[1;36m[ Load: \033[0;37m$LOADAVG \033[1;36m]\033[0m" >> /etc/motd
echo -e "\033[1;36m[ Mem: \033[0;37m$MEM_STAT \033[1;36m]\033[0m\n" >> /etc/motd
echo -e "" >> /etc/motd

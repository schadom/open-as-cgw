#!/bin/bash
# This script is intended to set the needed environment variables
# for an Open AS developer environment

# path vars
SCRIPT=`readlink -f "$0"`
SCRIPTPATH=`dirname "$SCRIPT"`
cd $SCRIPTPATH

# remove old vars to env 
sed -i '/# Open AS developer environment/d' ~/.bashrc
sed -i '/LIMESDEV/d' ~/.bashrc
sed -i '/LIMESLIB/d' ~/.bashrc
sed -i '/LIMESGUI/d' ~/.bashrc

# append new vars to env
echo '+ Appending variables to your ~/.bashrc...'
echo '# Open AS developer environment' >> ~/.bashrc
echo '' >> ~/.bashrc
echo 'export LIMESDEV=1' >> ~/.bashrc
echo 'export LIMESLIB="'$(dirname $(pwd))'/lib"' >> ~/.bashrc
echo 'export LIMESGUI="'$(dirname $(pwd))'/gui/lib"' >> ~/.bashrc
echo '+ Done! Please exit and re-login to your current shell!'

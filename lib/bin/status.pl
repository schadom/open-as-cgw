#!/usr/bin/perl -w
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


use strict;
my $backupfile = '';

# Holds the Timezone
my $timezone;
my $ct = '';
# Variable for everyday  use (counter or flags)
my $i = '0';											
my ($limit, $limit2);
# Temporary Variable
my $temp ='';
my $ext_dev = '';
######### New Interface start
BEGIN { 
    my $homedir = (getpwuid($<))[7];
    unshift(@INC,"$homedir/devel/limesas/lib/trunk/lib");
}
use strict;
use Underground8::Appliance::LimesAS;
use Underground8::Service::Backup;
use Underground8::Utils;

my $appliance = new Underground8::Appliance::LimesAS();
$appliance->load_config();

if (deflen($ARGV[0]) && $ARGV[0]=~/^DELETE\=(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.tar\.gz)$/)
{
    my $to_delete = $1;
    $appliance->backup->backup_read_list_unencrypted();
    my $index = $appliance->backup->backup_get_list_index($1);
    if (deflen($index) && $index >= 0)
    {
        $appliance->backup->backup_remove_unencrypted_backup($index);
    }
    $appliance->backup->commit();
    exit;
}

# take the timezone value
$timezone = $appliance->system->tz();
$ct .= "TIMEZONE=$timezone\n";
my $sn = $appliance->sn;
chomp $sn;
$ct .= "SN=$sn\n";
# Read the networksettings to determin ext. interface device name
$ext_dev = $appliance->system->net_name();
$ct .= "EXT_DEV=$ext_dev\n";
# Get System version
my $v_system = (deflen($appliance->report->versions->system))?$appliance->report->versions->system:'0';
my $v_build = (deflen($appliance->report->versions->build))?$appliance->report->versions->build:'0';
my $v_revision = (deflen($appliance->report->versions->revision))?$appliance->report->versions->revision:'0';
$ct .= "V_SYSTEM=$v_system\n";
$ct .= "V_BUILD=$v_build\n";
$ct .= "V_REVISION=$v_revision\n";



# Get antivirus version version
my $v_antivirus = (deflen($appliance->report->versions->antivirus))?$appliance->report->versions->antivirus:'0';
$ct .= "V_ANTIVIRUS=$v_antivirus\n";
# Get antispam version
my $v_antispam = (deflen($appliance->report->versions->antispam))?$appliance->report->versions->antispam:'0';
$ct .= "V_ANTISPAM=$v_antispam\n";
##############
# BACKUP PART
##############
# Read the file list of our actual backups
$appliance->backup->backup_read_list_unencrypted();

# if we have more than 1 .tar.gz backup (e.g. unencrypted's)
# remove all but the newest
if (scalar @{$appliance->backup->backup_list_unencrypted} > 1)
{
    # sorte the backups by date (auto naming makes it possible)
    my @backups = sort { $a cmp $b } @{$appliance->backup->backup_list_unencrypted};
    foreach (@backups)
    {
        # if only one backup is left, exit the loop
        last if ($_ eq $backups[-1]);
        # remove the backup
        $appliance->backup->backup_remove_unencrypted_backup($appliance->backup->backup_get_list_index($_));

    }
}

# creating a ned backup we have to lock the confs in the beginning
$appliance->set_config_lock_temp();

# create a temp dir
$appliance->backup->backup_create_tempdir();

# make a tar file of the backupfiles, returns the md5 sum
my $md5 = $appliance->backup->xml_to_tar([{ "_name" => $appliance->system->net_name, 
                                            "_ip_address" => $appliance->system->ip_address,
                                            "_subnet_mask" => $appliance->system->subnet_mask,
                                            "_default_gateway" => $appliance->system->default_gateway
                                        }]);

# make a gzip of the backup for smaller transfers
# and move it from the temp to our backup directory
$appliance->backup->tar_to_gzip();

# tempdir isn't necessary any more -> kick it out
$appliance->backup->backup_remove_tempdir();

# get the name of the last backupfile
$backupfile = $appliance->backup->backup_file;

# reread the unencrypted list
$appliance->backup->backup_read_list_unencrypted();

# check if the last created backup was identical to the previosly uploaded
# if it was, remove the new one, else set backupfile to backupfile + path
if ($appliance->backup->backup_compare_backups($md5, $backupfile))
{
    # if it was identical remove the newly generated backup
    $appliance->backup->backup_remove_unencrypted_backup($appliance->backup->backup_get_list_index($backupfile));
    # set backupfile to empty, check lateron will call in for deploying the backup if it wasn't empty
    $backupfile = '';
}
else
{
	$backupfile = "$g->{'cfg_backup_dir'}/" . $backupfile;
	$ct .= "BACKUP_FILE=$backupfile\n";
}

# commit the backup config xml file in order to store the new md5 checksum
$appliance->backup->commit();

print "$ct";

sub deflen
{
	my $check = $_[0];
	if ((defined $check) and (length $check))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
1;

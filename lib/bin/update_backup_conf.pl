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
use Data::Dumper;

my $etc = "";
my $bin = "";
my $var = "";
my $user = (getpwuid($<))[0];
 
BEGIN {

if ($ENV{'LIMESLIB'})
{
    my $libpath = $ENV{'LIMESLIB'};
    print "Found LIMESLIB=$libpath\n";
    $etc = "$libpath/etc";
    $bin = "$libpath/bin";    
    $var = "$libpath/etc/";
    unshift(@INC,"$libpath/lib/");
}
else
{
    $etc = "/etc/open-as-cgw";
    $bin = "/usr/local/bin";
    $var = "/var/open-as-cgw";
}

}
 
use Underground8::Appliance::LimesAS;
use Underground8::Service::Backup;
use Underground8::Utils;

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
#system("rm $etc/xml/backup.xml") if (-e "$etc/xml/backup.xml");

my $appliance = new Underground8::Appliance::LimesAS();
#$appliance->load_config();

# Remove old config, if existing
if (-e "$g->{'cfg_dir'}/backup.xml")
{
    safe_system("$g->{'cmd_rm'} $g->{'cfg_dir'}/backup.xml");
}

$appliance = undef;
$appliance = new Underground8::Appliance::LimesAS();

# We're lacking a backup.xml -> so we have to restore the defaults
# additionally the inclusion of the version file to backup happens here
$appliance->backup->restore_defaults;

$appliance->load_config();

$appliance->backup->backup_read_list_encrypted();
my @crypts = @{$appliance->backup->backup_list_encrypted()};
foreach (@crypts)
{
        my $filename = $_;
        $appliance->backup->backup_set_backup_file($filename);
        $appliance->backup->crypt_to_gzip();
        $appliance->backup->backup_create_tempdir();
        $appliance->backup->gzip_to_tar();

        my $tempdir = $appliance->backup->untar_to_tempdir();
        my $appfile = new Underground8::Appliance::LimesAS();
        my $backupname = $filename;
        $backupname =~ s/^(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)(\.crypt|\.tar\.gz|\.tar)$/$1/;
        $appfile->system->config_filename($tempdir);
        $appfile->system->load_config;

        $appliance->backup->add_backup_to_config({
                   '_name' => "$backupname",
                   '_net_interface' => [{ "_name" => $appfile->system->net_name,
                   "_ip_address" => $appfile->system->ip_address,
                   "_subnet_mask" => $appfile->system->subnet_mask,
                   "_default_gateway" => $appfile->system->default_gateway }]
                    });
        $appliance->backup->backup_remove_tempdir();

}
my @uncrypts = @{$appliance->backup->backup_list_unencrypted()};
foreach (@uncrypts)
{
        my $filename = $_;
        $appliance->backup->backup_set_backup_file($filename);
        $appliance->backup->backup_create_tempdir();
        $appliance->backup->gzip_to_tar();

        my $tempdir = $appliance->backup->untar_to_tempdir();
        my $appfile = new Underground8::Appliance::LimesAS();
        my $backupname = $filename;
        $backupname =~ s/^(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)(\.crypt|\.tar\.gz|\.tar)$/$1/;
        $appfile->system->config_filename($tempdir);
        $appfile->system->load_config;

        $appliance->backup->add_backup_to_config({
                   '_name' => "$backupname",
                   "_type" => "tar.gz",
                   '_net_interface' => [{ "_name" => $appfile->system->net_name,
                   "_ip_address" => $appfile->system->ip_address,
                   "_subnet_mask" => $appfile->system->subnet_mask,
                   "_default_gateway" => $appfile->system->default_gateway }]
                   });
       $appliance->backup->tar_to_gzip();
       $appliance->backup->backup_remove_tempdir();
#       print Dumper($appliance->backup);
#       print "Backup: $_\n";

}
$appliance->backup->commit;

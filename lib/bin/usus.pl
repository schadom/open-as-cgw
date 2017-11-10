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



#####################################
# UNDERGROUND_8 SMART UPDATE SCRIPT #
#####################################


use strict;
use Data::Dumper;
use Tie::File;
use DateTime;
use Getopt::Long;
use LWP::Simple;
use LockFile::Simple qw(lock trylock unlock);
use Data::Dumper;
use XML::Dumper;
use Config::File qw(read_config_file);

# usus needs to be completely independent from the environment, no matter where it is started
# the path variables need to be set (may not be always the case!)
$ENV{PATH} = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games";

my $config_file = "/etc/open-as-cgw/conf/usus.conf";
my $config = read_config_file($config_file) or exit 9;

$ENV{UCF_FORCE_CONFFNEW} = "yes";
$ENV{DEBCONF_FRONTEND} = "noninteractive";
$ENV{DEBIAN_FRONTEND} = "noninteractive"; 


# Used programs
my $APTITUDE = "DEBCONF_FRONTEND=noninteractive DEBIAN_FRONTEND=noninteractive /usr/bin/aptitude -o Aptitude::Log::=/tmp/aptitude-log -q -o Dpkg::Options::=--force-confnew -o Dpkg::Options::=--force-confmiss ";
my $GPG = "/usr/bin/gpg --homedir /root/.gnupg --keyring /etc/apt/trusted.gpg --no-default-keyring --yes";
my $WGET = "/usr/bin/wget";
my $DPKGLIST = "/usr/bin/dpkg --list limesas";
my $DPKGCONFIGURE ="DEBCONF_FRONTEND=noninteractive DEBIAN_FRONTEND=noninteractive /usr/bin/dpkg --configure --force-confnew --force-confmiss -a";


# Global variables
my $SECVERSION = "0";
my %CURRENTSTATUS = ();
my $DOWNLOADSIZE = "0";
my $DOWNLOADSPEED = "0";
my %AVAIL_VERSIONS = ();
my $NUKE_OVERRIDE = "0";
my $tmp = "updateserver_"."$config->{type}";
my $UPDATESERVER = $config->{$tmp};

my $UPGRADEABLE = "0";
my $UPGRADE = "0";

#print "\n\nupdateserver: $UPDATESERVER\n";
#exit 0;

# ALL THESE THINGS CAN BE SET VIA COMMANDLINE #################
# if an option is not set in the command line, the default value can be seen
# above. This is then going to be used.

GetOptions ('update!' => \$config->{update},   
            'download!' => \$config->{download},
            'upgrade!' => \$config->{upgrade},
            'auto-newest!' => \$config->{auto_newest},
            'version=s' => \$config->{main_version},
            'type=s' => \$config->{type});




%CURRENTSTATUS = get_current_status();

#print Dumper %CURRENTSTATUS;
my @output4gui;

# Now locking guifile - this script can only run once at a time
my $lockmgr = LockFile::Simple->make(-format => '/tmp/%F.lock',
                                     -autoclean => 1,
                                     -delay => 2,
                                     -hold => 28800,
                                     -max => 3,);

$lockmgr->lock($config->{output4gui_file}) or exit 1;
open(GUIFILE, "> $config->{output4gui_file}") or exit 1;

# Here we get the output to the GUIFILE directly (no buffering)
select(GUIFILE);
$|++;
select(STDOUT);

sleep 1;
print GUIFILE "message : success\n";
print GUIFILE "\nStarting Update Process : NONE";


# We now check the connection to $UPDATESERVER


print GUIFILE "\nConnection to update server : ";
my $return_check_connection = check_connection($UPDATESERVER);

if ( $return_check_connection )
{
    print GUIFILE "OK";
} else {
    print GUIFILE "FAILED";
    exit 2;
}


if ( $config->{update} or $config->{download} or $config->{upgrade})
{
    print GUIFILE "\nGetting info for newest versions : ";
    my $return_update = update();
#    my $return_write_sources = write_sources();
    

    if ( $return_update )
    {
        print GUIFILE "OK";
        print GUIFILE "\nUpdate ($SECVERSION) available! : INFO" if ( $SECVERSION ne "0" );    
    } else {
        print GUIFILE "FAILED";
        exit 3;
    }
}


if ( ($config->{download} or $config->{upgrade}) and $UPGRADEABLE)
{
    my $return_download = download();
    
    if ( $return_download )
    {
        print GUIFILE "OK";
        print GUIFILE "\nDownloaded $DOWNLOADSIZE $DOWNLOADSPEED : INFO";
    } else {
        print GUIFILE "FAILED";
        exit 4;
    }
}


if ( ($config->{upgrade} and $UPGRADEABLE) or $NUKE_OVERRIDE or !($CURRENTSTATUS{'install_ok'}) )
{
    print GUIFILE "\nUpgrading from $CURRENTSTATUS{'full'} to $SECVERSION : ";
    my $return_upgrade = upgrade();
    
    if ( $return_upgrade )
    {
        print GUIFILE "OK";
    } else {
        print GUIFILE "FAILED";
        exit 5;
    }   
}



print GUIFILE "\n\nDone. : NONE";

$lockmgr->unlock($config->{output4gui_file});

exit 0;


sub check_connection 
{
    my $server = shift;
    my $url = $server . "/sysmon_check.txt";
    my $content = get $url;
    
    if ( defined $content )
    {
        # We could test the returned content here...
        #print $content;
        return 1;

    } else {
        return 0;
    }
    return 0;
}

sub update
{
    my $downloadfile = "/tmp/limesas-versions.xml.gpg";
    
    system("$DPKGCONFIGURE");
    # First we update the current available versions file and check it
    system("$WGET ${UPDATESERVER}$config->{avail_versions_url} -O $downloadfile");
    my $exitcode_gpg = 1;
    $exitcode_gpg = system("$GPG --output $config->{avail_versions_file} --decrypt $downloadfile");

    if ($exitcode_gpg != 0)
    {
        return 0;
    }

    # Now we create sources.list - yes this happens EVERY time after update of xml file
    
    my $return_write_sources = write_sources();
    if ( !($return_write_sources) )
    {
        return 0;
    }


    # Now we aptitude update
    system("$APTITUDE update");
    
    # for the moment no checking if that worked happens here ...
    # maybe subject to change
    
    my $success = 0;
    
    # Now we aptitude dist-upgrade to see if any new sec/bugfix versions exist
    open (APT, "$APTITUDE dist-upgrade -s -V -y 2>&1 |");
    while( <APT> )
    {
        print $_;
        if ( $_ =~ m/^No\ packages\ will\ be\ installed,\ upgraded,\ or\ removed\./ )
        {
            # do nothing ...
            print "\nNo new sec/bugfix version available\n";
            $success=1;
        }
        
        if ( $_ =~ m/limesas\s+?\[(\d+\.\d+\.\d+)[a|b|s]\d*?\-(\d+)\~?.+\-\>\s+(\d+\.\d+\.\d+)([a|b|s]\d*?)\-(\d+)\~?.*\]/ )
        {
            $CURRENTSTATUS{'full'} = $1;
            $SECVERSION = $3;
            print "\nDetected version $CURRENTSTATUS{'full'} (revision: $2) of package limesas. New version is: $SECVERSION (revision: $5)\n";
            open(SECVERFILE, "> $config->{avail_secversion_file}") or exit 3;
            print SECVERFILE "$SECVERSION"."$4";
            close(SECVERFILE);
            $UPGRADEABLE = "1" if ( $5 > $2 );
            print "\nUpgradeable is: $UPGRADEABLE\n";
            $success=1;
        }    
    }

    # if we were able to check for new updates (no matter if we found some or not) we want to have a timestamp

    if ( $success )
    {
        open(TIMESTAMP, "> $config->{update_timestamp_file}") or exit 3;
        my $timetmp = get_localtime();
        print TIMESTAMP "$timetmp";
        close(TIMESTAMP);
        
        # We are checking if a nuked version is installed and if so UPGRADE IT!
        %AVAIL_VERSIONS = get_avail_versions();
        
        if ( $AVAIL_VERSIONS{'nuked'}{$CURRENTSTATUS{'full'}}{'active'} eq "1" )
        {
            $NUKE_OVERRIDE = "1";
            print "\n\nNUKE OVERRIDE ACTIVATED!\n\n";
        }
    }
    return $success;
}

    
sub download
{
    my $success = 0;
    if ( $UPGRADEABLE )
    {
        open (APT, "$APTITUDE dist-upgrade -d -V -y 2>&1 |");
        while ( <APT> )
        {
            print $_;
            if  ( $_ =~ m/^Need\ to\ get\ (\d+\.?\d?[k|m|M|K]?B)?\/?(\d+\.?\d?[k|m|M|K]?B)\ of\ archives\.\ After\ unpacking.+/ )
            {
                $DOWNLOADSIZE = $2;
                print GUIFILE "\nDownloading $DOWNLOADSIZE : ";
            }

            if  ( $_ =~ m/^Need\ to\ get\ (0B\/).+?of\ archives\..+/ )
            {
                $success = $1;
                $DOWNLOADSPEED = "previously downloaded."
            }

            if ( $_ =~ m/^Fetched\ (\d+\.?\d?[k|K|m|M]?B)\ in.+?\((\d+\.?\d?[m|M|k|K]?B\/s)\)/ )
            {
                $success = "1";
                $DOWNLOADSPEED = "with " .$2;
            }
        }
        close(APT);
    }
    return $success;
}


sub upgrade
{
    my $success = 0;
    if ( $UPGRADEABLE or $NUKE_OVERRIDE or !($CURRENTSTATUS{'install_ok'}) )
    {
        my $timestamp = get_localtime();
        $config->{upgradelog_file} .= "$timestamp";
        open (UPGRADELOG, "> $config->{upgradelog_file}") or exit 10;
        open (APT, "$APTITUDE dist-upgrade -V -y 2>&1 |");
        while ( <APT> )
        {
            print $_;
            print UPGRADELOG $_;
            # The following line is pretty much the very last thing that happens - if this line is there, it should have worked
            # in the future we may want to work with exit codes
            if ( $_ =~ m/Installing\ new\ version\ of\ config\ file\ \/etc\/limes\/versions\ \.\.\./ )
            {
                $success = "1";
                open(UPGRADEHISTORY, ">> $config->{upgradehistory_file}") or exit 11;
                print UPGRADEHISTORY "$timestamp from version $CURRENTSTATUS{'full'} ($CURRENTSTATUS{'type'}) to $SECVERSION\n";
                print UPGRADEHISTORY "Nuke override was: $NUKE_OVERRIDE\n\n";
                close(UPGRADEHISTORY);
            }
        }
        close(APT);
        close(UPGRADELOG);
    }

    return $success;
}

sub get_avail_versions
{
    my $file = $config->{avail_versions_file};
    my $dump =  new XML::Dumper;
    my $hash = $dump->xml2pl( $file );
    return (%$hash);
}

sub get_current_status
{
    my $main = "0";
    my $full = "0";
    my $type = "";
    my $rev = "0";
    my $user = "none";
    my $install_ok = "0";

    print "Now getting current status\n";
    open(DPKG, "$DPKGLIST |") or exit 8;
    foreach my $line (<DPKG>)
    {
        print "$line\n";
        if ( $line =~ m/^i([i|U])\s+?limesas\s+?(\d+?\.\d+?)\.(\d+?)([a|b|s])\d*?\-(\d+)\~?\d?(\w*?)\d?/ )
        {
            $install_ok = "1" if ($1 eq "i");
            $main = $2;
            $full = $2 . "." . $3;
            $type = "stable" if ($4 eq "s");
            $type = "devel" if ($4 eq "a");
            $type = "beta" if ($4 eq "b");
            $rev = $5;
            $user = $6 if ($6 ne "");
        }
    }
    close(DPKG);
    
    my %return_hash = ( "main" => $main,
                        "full" => $full,
                        "type" => $type,
                        "rev" => $rev,
                        "user" => $user,
                        "install_ok" => $install_ok,
                      );
    return %return_hash;

}

sub write_sources
{
    my $success = "0";

    %AVAIL_VERSIONS = get_avail_versions();
    if ( $config->{auto_newest} and $config->{type} eq "stable")
    {
        my @versions = reverse sort keys %{$AVAIL_VERSIONS{$config->{type}}{$CURRENTSTATUS{'main'}}{'avail'}};
        my $newestfound = "0";
        foreach my $version ( @versions )
       {
            print "\n$version is auto-upgradable: $AVAIL_VERSIONS{$config->{type}}{$CURRENTSTATUS{'main'}}{'avail'}{$version}{'auto-upgrade'}\n";
            if ( $AVAIL_VERSIONS{$config->{type}}{$CURRENTSTATUS{'main'}}{'avail'}{$version}{'auto-upgrade'} )
            {
                $config->{main_version} = $version;
                print "\nAutodetected $version as newest version\n";
                last;
            }
        }
    }

    my $type = $CURRENTSTATUS{'type'};
    # if no new main_version is set (to install) we use the current one to write sources.list
    if ( $config->{main_version} eq "0" )
    {
        $config->{main_version} = $CURRENTSTATUS{'main'};
        
        # if we are NOT at "stable" we need to use stable - the info is only there
        if ( $CURRENTSTATUS{'type'} ne "stable")
        {
            $type = "stable";
        }
    }
    

    if ( !(exists($AVAIL_VERSIONS{'stable'}{$CURRENTSTATUS{'main'}})) )
    {
        $success = "0";
    } else {
        # rewrite sources.list
        open (SOURCES, "> $config->{sourceslist_file}") or exit 7;
        print SOURCES "deb $UPDATESERVER/$config->{repository_dir} $AVAIL_VERSIONS{$type}{$config->{main_version}}{'base'} main restricted universe\n";
        print SOURCES "deb $UPDATESERVER/$config->{repository_dir} $AVAIL_VERSIONS{$type}{$config->{main_version}}{'base'}-security main restricted universe\n";
        print SOURCES "deb $UPDATESERVER/$config->{repository_dir} $AVAIL_VERSIONS{$type}{$config->{main_version}}{'base'}-updates main restricted universe\n";
        print SOURCES "deb $UPDATESERVER/$config->{repository_dir} $AVAIL_VERSIONS{$type}{$config->{main_version}}{'base'}-backports main restricted universe\n";
        print SOURCES "\n\n";
#        foreach my $tmp ( @{$AVAIL_VERSIONS{'stable'}{$config->{main_version}}{'depends'}} )
#        {
#            print SOURCES "deb $UPDATESERVER/$config->{repository_dir} limesas-$tmp limes limesas\n";
#        }
#        if ( $config->{type} ne "stable" )
#        {
         
            foreach my $tmp ( @{$AVAIL_VERSIONS{$type}{$config->{main_version}}{'depends'}} )
            {
                print SOURCES "deb $UPDATESERVER/$config->{repository_dir} limesas-$tmp limes limesas\n";
            }
#        }
        print SOURCES "deb $UPDATESERVER/$config->{repository_dir} limesas-$config->{main_version} limes limesas\n";
        $success = "1";
    }
    
    # we need to write a preferences file ... this is hardcoded here at the moment - we will see for the future

    open(PREF, "> /etc/apt/preferences") or exit 7;
    print PREF "Package: syslog-ng\n";
    print PREF "Pin: version 2.0.0-1-1limesas9\n";
    print PREF "Pin-Priority: -1\n";
    close(PREF);
    
    # and we also write dpkg configuration here ... hardcoded again
    open (DPKGCONF, "> /etc/dpkg/dpkg.cfg") or exit 7;
    print DPKGCONF "log /var/log/dpkg.log\n";
    print DPKGCONF "force-confnew\n";
    print DPKGCONF "force-confmiss\n";
    close(DPKGCONF);

    return $success;
}

sub get_localtime
{
    my @date = localtime();
    return (sprintf "%04d.%02d.%02d_%02d-%02d-%02d", ($date[5] + 1900), ($date[4]+1), $date[3], $date[2], $date[1], $date[0]);
}

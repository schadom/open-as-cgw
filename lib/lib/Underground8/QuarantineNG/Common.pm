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


package Underground8::QuarantineNG::Common;

use Sys::Syslog qw( :DEFAULT setlogsock);
use Config::File qw(read_config_file);
use DBI;
use POSIX;
use Fcntl;
use DB_File;
require Exporter;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw($debug log_message read_quarantine_config write_config daemonize confirm_domain trim get_quarantine_address_from_map check_disk_space check_domain_whitelist);

#### vars ####
my $pid_file = undef;
our $debug = 0;



# log message to syslog
sub log_message
{
    my ($priority, $msg) = @_;
    return 0 unless ($priority =~ /info|err|debug/);

    if ($debug)
    {
        printf("%s %s\n", $priority, $msg);
    }
    else
    {   
        setlogsock('unix');
        openlog($0, 'pid,cons', 'user');
        $msg =~ s/[^[:ascii:]]/_/g;
        syslog($priority, $msg);
        closelog();
    }
    return 1;
}


# load configfile
sub  read_quarantine_config
{
    my $config_file = shift;
    my $config_path = shift;
    my $cpath = undef;
    if (!defined($config_file))
    {
       $config_file = "quarantine-ng.conf";
    }

    if (defined($config_path))
    {
        $cpath = $config_path . "/" . $config_file;
    }
    else
    {
        if ($ENV{'LIMESLIB'})
        {
            $cpath = "$ENV{'LIMESLIB'}/etc/conf/$config_file";
            if ( ! -e $cpath)
            {   
                log_message("err", "$cpath not found, unable to startup!");
                exit (1);
            }
        }
        else
        {
            $cpath = "/etc/open-as-cgw/conf/$config_file";
            if ( ! -e $cpath)
            {   
                log_message("err", "$cpath not found, unable to startup!");
                exit (1);
            }
        }
    }

    my $config = undef;
    if ( !($config = read_config_file($cpath)) )
    {
        log_message("err", "Could not read configuration file, unable to startup!");
        exit (1);
    }

    return $config;
}

sub write_config
{
    my $config_path = shift;
    my $config_file = shift;
    my $key = shift;
    my $value = shift;

    my $cpath = undef;

    if (defined($config_path))
    {
        $cpath = $config_path . "/" . $config_file;
    }
    else
    {
        if ($ENV{'LIMESLIB'})
        {   
            $cpath = "$ENV{'LIMESLIB'}/etc/conf/$config_file";
            if ( ! -e $cpath)
            {
                log_message("err", "$cpath not found, unable to startup!");
                exit (1);
            }
        }
        else
        {   
            $cpath = "/etc/open-as-cgw/conf/$config_file";
            if ( ! -e $cpath)
            {
                log_message("err", "$cpath not found, unable to startup!");
                exit (1);
            }
        }
    }

    my @new_raw_data;
    my $data_file = $cpath;
    open(DAT, $data_file); 
    my @raw_data = <DAT>;
    close(DAT);
    my $new_line = undef;
    foreach my $line (@raw_data)
    {
        $new_line = $line;
        $line =~ /\s*(.*)\s*\=\s*(.*)\s*/;
        my $current_key = $1;
        my $current_value = $2;
        if (defined($current_key) && defined($current_value))
        {
            $current_key = trim($current_key);
            $current_value = trim($current_value);
            if ($current_key eq $key)
            {
                $new_line = $current_key . " = " . $value . "\n";
            }
        }
        push(@new_raw_data, $new_line);
    }
    open(DAT,">$data_file");
    while (@new_raw_data)
    {
        my $tmp = shift(@new_raw_data);
        print DAT ($tmp);
    }
    print DAT "@new_raw_data";
    close(DAT);  
}

sub check_domain_whitelist
{
    my $domain = shift;
    my $domain_list = shift;

    my @data = split(/,/, $domain_list);

    my $current_domain;
    foreach $current_domain (@data) {
        if ($current_domain eq $domain)
        {
            return 1;
        }
    }
    return 0;
}

# check for valid domain
sub confirm_domain
{   
    my $domain_map = shift;
    my $domain = shift;
    my %tab;
    my $null=chr(0);


    if (!$domain_map or !$domain)
    {
        return 0;
    }

    tie(%tab, 'DB_File', $domain_map, O_RDONLY, 0400, $DB_HASH);

    # TODO check if tie worked
    # query
    my $key = $domain;

    my $value = $tab{$key.$null};
    if ($value)
    {
        chop($value);  # chop null byte
        return 1;
    }
    else
    {
        return 0;
    }
}

sub get_quarantine_address_from_map
{
    my $rcpt_map = "/etc/postfix/local_rcpt_map.db";

    my %tab;
    my $null=chr(0);


    tie(%tab, 'DB_File', $rcpt_map, O_RDONLY, 0400, $DB_HASH);

    # TODO check if tie worked
    # query
    my $quarantine_address;
    while ((my $key, my $value) = each %tab) {
        $quarantine_address = $key;
    }
    # default address value
    my $default_address = "quarantine";
    if (defined($quarantine_address))
    {
        my $str_length = length($quarantine_address);
        if ($str_length > 1)
        {
            return substr($quarantine_address,0, $str_length -1);
        }
        # if an empty string was found, return the default value
        else
        {
            return $default_address;
        }
    }
    else
    {
        return $default_address;
    }
}

# daemonize the script
sub daemonize 
{
    $pid_file = shift;

    chdir '/' or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    write_pid_file($$);
    setsid or die "Can't start a new session: $!";
    umask 0;
}   

# write PID file for daemon
sub write_pid_file 
{
    my $recParamsSize = @_;
    if ($recParamsSize == 0)
    {
        die ("Wrong parameters qty writePIDFile\n");
    }   
    open(PIDFILE, "> $pid_file") || die ("Couldn't write to PID file\n");
    print(PIDFILE "$_[0]");
    close(PIDFILE);
}

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub check_disk_space
{
    my $path_to_check = shift;
    my $result = `du -sm $path_to_check 2> /dev/null`;
    $result =~ /^(.*)\t.*$/;
    my $disk_space = $1;
    return $disk_space;
}

1;


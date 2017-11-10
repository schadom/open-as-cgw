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



#
#
#
# script for resetting LimesAS to factory default
# 30.7.2008 hlampesberger
#
# TODO:
#  - locking
#  - quarantine reset
#  - system logs reset
#


# check for development environment
BEGIN
{   
    my $libpath = $ENV{'LIMESLIB'};
    if ($libpath)
    {   
        print STDERR "*** DEVEL ENVIRONMENT ***\nUsing lib-path: $libpath\n";
        unshift(@INC,"$libpath/lib/");
    }
}

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long;
use Underground8::Utils;
use Data::Dumper;
use Sys::Syslog;
use POSIX 'setsid';


# default variables
my $mysql_user = "root";
my $mysql_pass = "loltruck2000";
my $verbose = 0;
my $quiet = 0;
my $help = 0;
my $debug = 0;
my $statistics_reset = 0;
my $soft_reset = 0;
my $hard_reset = 0;
my $pid = 0;


# commands
my $mysql_cmd = "/usr/bin/mysql --defaults-extra-file=/etc/mysql/debian.cnf -B -N -n ";
my $mysql_cmd_root = "/usr/bin/mysql -u $mysql_user -p${mysql_pass} -B -N -n";
my $rm = "/bin/rm";
my $postsuper = "/usr/sbin/postsuper";

GetOptions ('verbose+' => \$verbose,
            'quiet!' => \$quiet,
            'help|h|?' => \$help,
            'debug!' => \$debug,
            'soft!' => \$soft_reset,
            'hard!' => \$hard_reset,
            'statistics!' => \$statistics_reset,
);


# check program uid for root permissions
if ($> != 0)
{
    print STDERR "\nThis program must be executed with root privileges!\n\n";
    exit(0);
}


# debug output
if ($debug)
{
    print "verbose = $verbose\n";
    print "quiet = $quiet\n";
    print "help = $help\n";
    print "statistics = $statistics_reset\n";
    print "soft = $soft_reset\n";
    print "hard = $hard_reset\n";
}


# print usage text
if ($help)
{
    pod2usage(1);
    exit(0);
}


# only one of the reset switches is allowed
my $sum = $soft_reset + $hard_reset + $statistics_reset;
if ($sum == 0 || $sum > 1)
{
    print STDERR "Parameter error!\n" if (!$quiet);
    pod2usage(1);
}



# fork the process
$pid = fork();

if ($pid == 0)
{
    setsid() or die "Can't start a new session: $!";

    if ($statistics_reset)
    {
        # open syslog socket
        openlog("resetter.pl", 'cons,pid', 'mail');
        syslog('info', '%s', 'LimesAS statistics reset initiated');    
        purge_livelog();
        purge_mailq();

        # report to syslog
        syslog('info', '%s', 'LimesAS statistics reset sucessful');    
        closelog();
     
        exit(0);
    }


    if ($soft_reset)
    {
        # open syslog socket
        openlog("resetter.pl", 'cons,pid', 'mail');
        syslog('info', '%s', 'LimesAS soft reset initiated');    
        purge_configuration();
        purge_livelog();
        purge_sqlgrey();
        purge_smtpauth();
        purge_mailq();
		reset_admin_password();

        # generate backup.xml
        system("/usr/bin/sudo -u www-data /usr/local/bin/update_backup_conf.pl > /dev/null");

        # report to syslog
        syslog('info', '%s', 'LimesAS soft reset sucessful');    
        closelog();

        system("/sbin/shutdown -r now");
        exit(0);
    }


    if ($hard_reset)
    {
        # open syslog socket
        openlog("resetter.pl", 'cons,pid', 'mail');
        syslog('info', '%s', 'LimesAS hard reset initiated');    
        purge_livelog();
        purge_amavis();
        purge_sqlgrey();
        purge_smtpauth();
        purge_system_logfiles();
        purge_configuration();
        purge_user_logfiles();
        purge_confbackup();
        purge_quarantine();
        purge_mailqueue();
        purge_mailq();
		reset_admin_password();

        # generate backup.xml
        system("/usr/bin/sudo -u www-data /usr/local/bin/update_backup_conf.pl > /dev/null");

        # report to syslog
        syslog('info', '%s', 'LimesAS hard reset sucessful, now rebooting');    
        closelog();

        system("/sbin/shutdown -r now");
        exit(0);
    }
}

exit(0);


#############   SUBS   ##############



# purge livelog from mysql
sub purge_livelog
{
    # drop database
    my $cmd = $mysql_cmd . "-e 'drop database rt_log;'";

    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting and Recreating Livelog database.\n"; 
    }

    if ($debug)
    {
        print STDERR "executing $cmd\n";
    }

    system($cmd);

    # create database
    $cmd = $mysql_cmd . "< /etc/open-as-cgw/db_struct/rt_log.sql";
        
    if ($debug)
    {
        print STDERR "executing $cmd\n";
    }
    
    system($cmd);


    # run index script
    system("/etc/open-as-cgw/db_struct/rtlog_checkdb.pl > /dev/null");
}

# drop all info in amavis database
sub purge_amavis
{
    # drop database
    my $cmd = $mysql_cmd_root . "-e 'drop database amavis;'";

    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting and Recreating Amavis database.\n"; 
    }

    if ($debug)
    {
        print STDERR "executing $cmd\n";
    }

    system($cmd);

    # create database
    $cmd = $mysql_cmd_root . "< /etc/open-as-cgw/db_struct/amavis.sql";
        
    if ($debug)
    {
        print STDERR "executing $cmd\n";
    }
    
    system($cmd);

}

# purge sqlgrey from mysql
sub purge_sqlgrey
{
    purge_database("sqlgrey", "sqlgrey");
}


# purge smtp_auth from mysql
# requires purge_configuration first!
sub purge_smtpauth
{
    purge_database("smtp_auth", "smtp_auth"); 
}


# TODO purge system logfiles (does this make sense?)
sub purge_system_logfiles
{
    # purge current maillog file
    system("/bin/echo \"\" > /var/log/open-as-cgw/mangled-mail.log");
}


sub reset_admin_password {
	system("/usr/sbin/usermod -p 'cdlRbNJGImptk' admin");
}

# purge LimesAS configuration settings
# antispam.xml  backup.exclude  backup.include  
# backup.xml  notification.xml  system.xml quarantine.xml usermaps.xml
sub purge_configuration
{
    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting all user-generated Config-files\n";
    }
    system("$rm -f /etc/open-as-cgw/xml/*.xml");
    system("$rm -f /etc/open-as-cgw/xml/backup.include");
    system("$rm -f /etc/open-as-cgw/xml/backup.exclude");
}



# purge the users downloadable logfiles
sub purge_user_logfiles
{ 
    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting all user-generated Log-files\n";
    }
    system("$rm -f /var/www/LimesGUI/root/static/log/*.gz");
}




# purge configuration backups
sub purge_confbackup
{
    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting all user-generated Backup-files\n";
    }
    system("$rm -f /var/www/LimesGUI/root/static/backup/*");
    system("$rm -rf /var/open-as-cgw/backup/*");
}



# TODO purge quarantine system
sub purge_quarantine
{
    return;
}



# purge mailqueue from postfix system
sub purge_mailqueue
{
    if ($verbose && !$quiet)
    {
        print STDERR "[*] Deleting all entries in postfix mailqueue\n";
    }
    system("$postsuper -d ALL");
}

# purge mailq-statistics from mysql
sub purge_mailq
{
    purge_database("MailQ", "mailq");
}




sub purge_database
{
    my $name = shift;
    my $db = shift;

    my @tables;
    my $i = 0;
    my $pid = 0;
    my $cmd = undef;

    if ($verbose && !$quiet)
    {
        # rudimentary error handling
        if (!$db)
        {
            print STDERR "[!] error!\n";
            exit(-1);
        }
            
        print STDERR "[*] Resetting MySQL-tables for Service $name\n";
    }

    $cmd = $mysql_cmd . $db . " -e 'show tables;'";

    if ($debug)
    {
        print STDERR "executing $cmd\n";
    }

    open(SQL, $cmd . "|") or die "Could not execute $cmd\n";

    while(<SQL>)
    {
        chomp($_);
        push(@tables, $_);
        if ($debug)
        {
            print STDERR "- reading $_\n";
        }
        $i++;
    }

    close(SQL);
    

    for my $table_name ( @tables )
    {
        if ($verbose && !$quiet)
        {
            print STDERR "     - truncating $table_name\n";
        }

        $cmd = $mysql_cmd . $db . " -e 'truncate $table_name;'";
        if ($debug)
        {
            print STDERR "executing $cmd\n";
        }
        system($cmd);
    }
}


__END__

=head1 NAME

resetter.pl - Factory Defaults for LimesAS

=head1 SYNOPSIS

resetter.pl [options] --statistics

resetter.pl [options] --soft

resetter.pl [options] --hard

 Options:
    -help
    -verbose
    -quiet
    -statistics
    -soft
    -hard

=head1 OPTIONS

=over 8

=item B<-help>

Print this help message and exits.

=item B<-verbose>

Verbose output when running.

=item B<-quiet>

Disables output to STDOUT and STDERR.

=item B<-statistics>

All statistic data from mailtraffic will be reset to zero. This does
not affect the system configuration. The appliance will not reboot.

=item B<-soft>

The system configuration is set back to factory-default, including the
network settings. All statistic data from mailtraffic will be reset to 
zero. Backups and Logfiles will remain. The appliance will not reboot.

=item B<-hard>

ALL settings are reset to factory-default and ALL data is wiped. The
appliance will be rebooted. The Serial-number is unchanged.

=back

=head1 DESCRIPTION

B<This program> resets a LimesAS appliance back to factory default
settings.

=cut




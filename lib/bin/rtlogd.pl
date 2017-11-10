#!/usr/bin/perl
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


#####################################################################
# rtlogd
#
# real-time log-parser for the Limes Anti-Spam appliance
# attaches to a pipe opened by syslog-ng and receives log-lines
# from the syslog mail-facility.
#
# 2007-2008
# Matthias Pfoetscher
# rewrite by Harald Lampesberger
#####################################################################

# check for development environment
BEGIN
{
    my $libpath = $ENV{'LIMESLIB'};
    if ($libpath)
    {
        print "*** DEVEL ENVIRONMENT ***\nUsing lib-path: $libpath\n";
        unshift(@INC,"$libpath/lib/");
    }
}

use strict;
use warnings;

use POSIX;
use Underground8::Log::Listener::Email;
use Underground8::Log::Writer::Email::MySQL;
use Time::Local;
use IO::File;
use File::Flock;
use File::Slurp;
use Data::Dumper;
use Getopt::Long;
use Date::Format qw(time2str);



#######    VARS    ########


our $progname = 'openas-rtlogd';
our $pidfile = '/var/run/openas-rtlogd.pid';
our $named_pipe = "/var/open-as-cgw/rt_log";
our $mq_offset = 0; 

my $INTERVAL = 300;  # seconds to restart writer
# time-factor for listener restart, e.g. 2 means 600s when interval is 300s
my $LISTENER_FACTOR = 3;   
my $input_file;
my $output_to_console;

my $counter = 1;
my $writer_pid = 0;
my $listener_pid = 0; 
my $DEBUG = 0;
my $logname = $progname;


#######   SUBS   #######

sub debug
{
    my $text = shift;
    my $level = shift || 1;

    if (defined $output_to_console)
    {
        print time2str("%c",time) . " $logname: $text\n" if $level <= $DEBUG;   
    }
    else
    {
        print "$text\n" if $level <= $DEBUG;   
    }
}


sub check_pid
{
    if (-e $pidfile)
    {
        unless (lock($pidfile, undef, 'nonblocking'))
        {
            my $existing_pid = read_file($pidfile);
            chomp($existing_pid);
            die "There's another instance of $progname running (PID:$existing_pid)!";
        }
        unlock($pidfile);
    }
}


sub write_pidfile
{                 
    check_pid;
    lock($pidfile, undef, 'nonblocking') or die "Couldn't lock $pidfile!";
    write_file($pidfile, "$$\n") or die "Couldn't write PID $$ to $pidfile!";
}


sub set_parent_sig_handlers
{
    # set signal handlers

    $SIG{'ALRM'} = \&sig_alrm;
    $SIG{'CHLD'} = \&sig_chld;

    $SIG{'INT'} = \&sig_shutdown;
    $SIG{'TERM'} = \&sig_shutdown;
    $SIG{'HUP'} = \&sig_shutdown;
    $SIG{'QUIT'} = \&sig_shutdown;
}

sub set_writer_sig_handlers
{
    $SIG{'INT'} = \&sig_shutdown_writer;
    $SIG{'HUP'} = \&sig_shutdown_writer;
    $SIG{'TERM'} = \&sig_shutdown_writer;
    $SIG{'QUIT'} = \&sig_shutdown_writer;
}


sub set_listener_sig_handlers
{
    $SIG{'INT'} = \&sig_shutdown_listener;
    $SIG{'HUP'} = \&sig_shutdown_listener;
    $SIG{'TERM'} = \&sig_shutdown_listener;
    $SIG{'QUIT'} = \&sig_shutdown_listener;
}

sub daemonize
{
    my $pid = fork();

    defined ($pid) or die "Cannot start daemon: $!";

    if ($pid)
    {
        print_log("$progname starting up...");
        exit(0);
        # daemonized
    }

    # Detach from shell
    setsid();

    # redirect shell output to logger
    my $logname = "$progname\[$$\]";
    redirect_output($logname);
}


sub redirect_output
{
    # TODO implement syslog
    my $logname = shift || 'rtlog';
    #close (STDOUT);
    #close (STDIN);
    #close (STDERR);
    open STDERR, "|logger -t '$logname'" or die("Could not open STDOUT: $!");
    close STDOUT;
    open STDOUT, ">&STDERR" or die("Could not open STDERR: $!");
    $| = 1;
}


sub cleanup_on_exit
{
    # cleanup should be done automatically

    # remove message queue
    Underground8::Log::MQ::Email->new->remove;
}


sub spawn_listener
{
    my $pid = spawn_child();

    if ($pid)
    {
        return $pid;
    }

    # set process name and logging parameters    
    $0 = "$progname-listener";
    $logname = "$progname-listener\[$$\]";
    set_listener_sig_handlers();

    debug("started listener process", 1);

    unless ($output_to_console)
    {
        redirect_output($logname);
    }

    if ($input_file)
    {
        open (SYSLOG, "<", $input_file)
          or die "Coudln't open $input_file: $!";
         debug("Opened file $input_file for input",1);
    }
    else
    {
        open (SYSLOG,"+<",$named_pipe)
          or die "Couldn't open $named_pipe: $!";
    }
    
    my $log_listener = new Underground8::Log::Listener::Email($mq_offset, $DEBUG);
    $log_listener->init;
    my $line;
    while ($line = <SYSLOG>) 
    {
        if (defined $line)
        {
            my $date;
            my $host;
            my $service;
            my $log_pid;
            my $message;
	
	    # 2015-10-27T03:33:26+01:00 mx postfix/cleanup[22414]: CEE2810098C: message-id=<E1Zqu4j-000ROF-HF.octo15@web.heise.de>
            # 2008-04-22T12:52:49+02:00 limeas01-vienna-buero2 postfix/cleanup[941]: 9F55682ACE: message-id=<20080422105245.5695B8295C@kermit.abizzle.net>
            my $match_string = qr/^(\d{4,4}-\d{2,2}-\d{2,2}T\d{2,2}:\d{2,2}:\d{2,2}\+[\d\:]*)\s([\d\_\+\w\-\.]+)\s([\w+\/-]+)(\[(\d+)\])*:\s(.+)$/;

            if ($line =~ $match_string)
            {
                $date = $1;
                $host = $2;
                $service = $3;
                $log_pid = $5;
                $message = $6;

                $date = date_to_timestamp($date);

                if ($log_listener->match($service))
                {
                    $log_listener->process($date,$host,$service,$log_pid,$message);
                }
            }
        }
    }
    close(SYSLOG);
    debug("listener exiting...",1);
    exit(0);
}


sub spawn_writer
{
    my $pid = spawn_child();

    if ($pid)
    {
        return $pid;
    }

    # set process name and signal handlers
    $0 = "$progname-writer"; 
    $logname = "$progname-writer\[$$\]";
    set_writer_sig_handlers();


    debug("started writer process", 1);
    

    unless ($output_to_console)
    {
        redirect_output($logname);
    }
    
    my $log_writer = new Underground8::Log::Writer::Email::MySQL($mq_offset, $DEBUG);
    $log_writer->run;
}


sub spawn_child
{
    # spawn away from parent process
    my $pid;
    my $sigset = new POSIX::SigSet(SIGINT);

    sigprocmask(SIG_BLOCK, $sigset) or die "Can't block SIGINT for fork $!";

    unless (defined ($pid = fork))
    {
        die "Cannot fork child: $!";
    }
    
    sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't block SIGINT for fork $!";

    return $pid;
}


sub date_to_timestamp
{
    my $date = shift;

    # 2015-10-27T03:33:26+01:00
    # 2007-06-18T15:20:02+02:00
    if ($date =~ qr/(\d{4,4})-(\d{2,2})-(\d{2,2})T(\d{2,2}):(\d{2,2}):(\d{2,2})\+.+/)
    {
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $hour = $4;
        my $minute = $5;
        my $second = $6; 

        my $timestamp = timelocal($second,$minute,$hour,$day,$month-1,$year-1900);
        return $timestamp;
    }

}



sub print_log
{
    my $text = shift;
    if (defined $output_to_console)
    {
        print time2str("%c",time) . " $logname: $text\n";   
    }
    else
    {
        print "$text\n";   
    }
}


sub sig_chld
{
    $SIG{'CHLD'} = 'IGNORE';

    my $dead_pid;

    $dead_pid = waitpid(-1, &WNOHANG);
    if (WIFEXITED($?))
    {
        # child process exited
        warn ("child $dead_pid terminated -- status $?\n") if $? != 0;
    }
    elsif (WIFSTOPPED($?))
    {
        # Child process stopped
        warn ("child $dead_pid stopped -- status $?\n") if $? != 0;
        kill('TERM', $dead_pid);
    }
    
    $SIG{CHLD} = \&sig_chld;
}


sub sig_alrm
{
     # kill children and restart them
    $SIG{'CHLD'} = 'IGNORE';
    $SIG{'ALRM'} = 'IGNORE';

    my $pid = 0;

    # do not restart listener every time
    if ($counter >= $LISTENER_FACTOR)
    {
        kill('TERM', $listener_pid);
        if ($pid = waitpid($listener_pid, 0))
        {
            debug("$listener_pid was killed after timeout, starting new one", 4);
            $listener_pid = spawn_listener();
        }
        else
        {
            debug("The fuck does not die!", 5);
            exit(-1);
        }
        $counter = 1;
    }
    else
    {
        $counter++;
    }
        

    kill('TERM', $writer_pid);
    if ($pid = waitpid($writer_pid, 0))
    {
        debug("$writer_pid was killed after timeout, starting new one", 4);
        $writer_pid = spawn_writer();
    }
    else
    {
        debug("The second fuck does not die!", 5);
        exit(-1);
    }
    

    $SIG{CHLD} = \&sig_chld;
    $SIG{'ALRM'} = \&sig_alrm;
    alarm($INTERVAL);
}


sub sig_shutdown
{
    kill('HUP', $listener_pid);
    kill('HUP', $writer_pid);

    cleanup_on_exit();

    exit(0);
}



sub sig_shutdown_listener
{
    exit(0);
}

sub sig_shutdown_writer
{
    exit(0);
}







######    MAIN    ######


$0 = $progname;
$logname = $progname;

GetOptions(
    'debug|d=i' => \$DEBUG,
    'file|f=s' => \$input_file,
    'console|c' => \$output_to_console,
);


# check for existing processes
check_pid();

# detach
daemonize() unless defined $output_to_console;
    
# write pidfile
write_pidfile();

debug ("Debugging ist turned on ($DEBUG)", 1);

# spawn children
$listener_pid = spawn_listener();
$writer_pid = spawn_writer();


# warn if there is a problem with the child pids
if ((!$listener_pid) || (!$writer_pid))
{
    debug("Something went wrong while starting the Childs", 1);
}


# set signal handlers
set_parent_sig_handlers();

debug ("activating alarm and going to sleep", 3);

alarm($INTERVAL);

while (1)
{
    sleep;
}


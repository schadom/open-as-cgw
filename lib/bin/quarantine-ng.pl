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


# quarantine-ng - daemon that handles quarantine tasks like creating/(de)activating
# quarantines, releasing messages, ...
# TODO: logging

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

### usings

use Underground8::QuarantineNG::Common;
use Underground8::QuarantineNG::Base;
use Underground8::Utils;
use IO::Socket::INET;
use Net::Server::Mail::LMTP;
use Data::Dumper;
use Pod::Usage;
use Getopt::Long;
use Switch;
use POSIX ();
use FindBin ();
use File::Basename ();
use File::Spec::Functions;
use Clone qw(clone);

use strict;
use warnings;

### variables

my $help = 0;
my $hostname = `hostname -f`;
my $domainname = `hostname -d`;
my @ARGCOPY;
chomp($hostname);
chomp($domainname);

my $dbh = undef;
my $SELF = undef;
my $script = undef; 
my $quarantine_enabled = 1;

### functions

sub validate_recipient
{
    my($session, $recipient) = @_;

    my $domain;
    if($recipient =~ /@(.*)>\s*$/)
    {
        $domain = $1;
    }

    if(not defined $domain)
    {
        # not OK
        return(0, 513, 'Syntax error.');
    }
    elsif (($domain eq $hostname) or ($domain eq $domainname))
    {
        # recipient-domain is valid hostname or domainname
        return(1);
    }
    else
    {
        # not OK
        return(0, 554, "$recipient: Recipient address rejected: Relay access denied");
    }
}



# parse all necessary information from given mail and initiate activities
sub parse_mail
{
    my($session, $data) = @_;

    # not for now, everything is working in case of deactivation, but maybe in near future this is needed
    #if ($quarantine_enabled)
    #{

        my $sender = $session->get_sender();
        $sender =~ /\<(.*)\>/;
        my $filtered_sender = $1; 
        my @recipients = $session->get_recipients();

        return(0, 554, 'Error: no valid recipients')
            unless(@recipients);

        my $command = undef;
        my $param1 = undef;
        my $param2 = undef;
        my $full_command = undef;

        if ($$data =~ /(\[\[.*\]\])/)
        {
            $full_command = $1;
            my $len = length($full_command);
            log_message("debug", "$len $full_command");
            if ($len == 20)
            {
                $full_command  =~ /\[\[(.{3}):(.{12})\]\]/;
                $command = $1;
                $param1 = $2;

                log_message("debug", "Command: $command  Param1: $param1.");

                # check for given commands
                switch ($command)
                {
                    # add and activate new user
                    case "AAC"  
                    {
                        if ($param1)
                        {
                            add_user($param1, $filtered_sender);
                            activate_quarantine($param1, $filtered_sender);
                            get_report($param1, 1, $filtered_sender);
                            log_message("info", "AAC new user with $param1.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Wrong parameters submitted for adding new user for $sender.");
                            return(1, 250, "message processed");
                        }
                    }
                    # add and deactivate new user
                    case "ADE"  
                    {
                        if ($param1)
                        {
                            add_user($param1, $filtered_sender);
                            deactivate_quarantine($param1, $filtered_sender);
                            log_message("info", "ADE new user with $param1 - quarantine deactivated.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while adding new user for $sender.");
                            return(1, 250, "message processed");
                        }
                    }
                    # delete all messages for single quarantine 
                    case "DAL"  
                    {
                        if ($param1)
                        {
                            delete_all_messages($param1, $filtered_sender);
                            log_message("info", "DAL deleting all messages for $param1.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            print "Error occured while deleting all messages.";
                            log_message("err", "Error occured while deleting all messages $param1.");
                            return(1, 250, "message processed");
                        }
                    }
                    # activate a quarantine
                    case "ACT"  
                    {
                        if ($param1) 
                        {
                            activate_quarantine($param1, $filtered_sender);
                            get_report($param1,1,$filtered_sender);
                            log_message("info", "ACT activating quarantine $param1.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured, invalid user submitted for activating by $sender.");
                            return(1, 250, "message processed");
                        } 
                    } 
                    # deactivate a quarantine
                    case "DEA"  
                    {
                        if ($param1)
                        {
                            deactivate_quarantine($param1, $filtered_sender);
                            log_message("info", "DEA deactivating quarantine $param1.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while deactivating user.");
                            print "Error occured while deactivating user.";
                            return(1, 250, "message processed");
                        }
                    }
                    # get quarantine report 
                    case "GET"  
                    {
                        if ($param1)
                        {
                            get_report($param1, 1, $filtered_sender);
                            log_message("info", "GET sending spam report $param1.");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while sending report.");
                            print "Error occured while getting report.";
                            return(1, 250, "message processed");
                        }
                    }
                    # unrecognized command submitted
                    else 
                    {
                        log_message("err", "Unknown command submitted from $sender.");
                        return(1, 250, "message processed");
                    }
                }
            }
            elsif ($len == 32)
            {
                $full_command  =~ /\[\[(.{3}):(.{12})(.{12})\]\]/;
                $command = $1;
                $param1 = $2;
                $param2 = $3;

                # check for given commands
                switch ($command)
                {
                    # delete message in quarantine
                    case "DEL"  
                    {
                        if ($param1 && $param2)
                        {
                            delete_message($param1, $param2, $filtered_sender);
                            log_message("info", "DEL deleting message $param1 $param2");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while deleting message for $sender.");
                            return(1, 250, "message processed");
                        }
                    }
                    # release message in quarantine
                    case "REL"  
                    {
                        if ($param1 && $param2)
                        {
                            release_message($param1, $param2, $filtered_sender);
                            log_message("info", "REL releasing message $param1 $param2");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while releasing message for $sender.");
                            return(1, 250, "message processed");
                        }
                    }
                    case "DED"
                    {
                        if ($param1 && $param2)
                        {
                            delete_day($param1, $param2, $filtered_sender);
                            log_message("info", "DED deleting day $param1 $param2");
                            return(1, 250, "message processed");
                        }
                        else
                        {
                            log_message("err", "Error occured while deleting day for $sender.");
                            return(1, 250, "message processed");
                        }
                    }
                    # unrecognized command submitted
                    else
                    {
                        log_message("err", "Unknown command submitted from $sender.");
                        return(1, 250, "message processed");
                    }
                }
            }
        }
        else
        {
            # log invalid
            log_message("info", "a invalid message from $sender was processed by quarantine-ng.");
        }

    #}

    return(1, 250, "message processed");
}


sub main_loop
{
    my $config = shift;
    my $conn = undef;
    $quarantine_enabled = $config->{'quarantine_enabled'};
    my $server = new IO::Socket::INET (Listen => 1, 
                                       LocalAddr => $config->{'listen_address'},
                                       LocalPort => $config->{'listen_port'});

    while ($conn = $server->accept)
    {
        my $lmtp = new Net::Server::Mail::LMTP (socket => $conn);
        # adding some handlers
        $lmtp->set_callback(RCPT => \&validate_recipient);
        $lmtp->set_callback(DATA => \&parse_mail);
        $lmtp->process();
        $conn->close()
    }
}


END
{
    base_destroy();
}


### signal handlers

sub sighup_handler
{
    log_message("info", "restarting quarantine-ng process.");
    exec($SELF, @ARGCOPY) or die "Couldn't restart: $!\n";
}




### main
@ARGCOPY = @{ clone(\@ARGV) };


GetOptions ('help|h|?' => \$help,
            'debug!' => \$debug,
);

# check program uid for root permissions
if ($> != 0)
{
    print STDERR "\nThis program must be executed with root privileges!\n\n";
    exit(0);
}

# print usage text
if ($help)
{
    pod2usage(1);
    exit(0);
}

# debug output or daemonize process
if ($debug)
{
    print STDERR "Starting up in debugging mode at $hostname ...\n";
}

# load configfile
my $config = read_quarantine_config();

# daemonize if not in debugging mode
if (!$debug)
{
    daemonize("/var/run/openas-qng.pid");
}

# signal handling
# restart process on HUP
$script = File::Basename::basename($0);
$SELF = catfile($FindBin::Bin, $script);
my $sigset = POSIX::SigSet->new();
my $action = POSIX::SigAction->new('sighup_handler', $sigset, &POSIX::SA_NODEFER);
POSIX::sigaction(&POSIX::SIGHUP, $action);

$0 = "quarantine-ng.pl";

# initialize base module
base_init($config);

# start the main daemon loop
main_loop($config);

# shutdown base module
base_destroy();

exit(0);


__END__

=head1 NAME

quarantine-ng.pl - Quarantine manager for LimesAS

=head1 SYNOPSIS

quarantine-ng.pl [options] --xxx

 Options:
    -help
    -xxx

=head1 OPTIONS

=over 8

=item B<-help>

Print this help message and exits.

=item B<-xxx>

xxx some text.
xxx some text.

=back

=head1 DESCRIPTION

B<This program> manages the Limes AS quarantine system. 

=cut



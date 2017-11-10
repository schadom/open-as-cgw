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


package Underground8::Log::Writer::Email::File;
use base Underground8::Log::Writer::Email;

use strict;
use warnings;

use Underground8::Log::Email;
use Underground8::Log::Writer::Email;
use IO::File;
use IO::Select;
use Date::Format;

#YYYY-MM-DD"T"HH:MM:SS+TZTZ
my $TIME_TPLT = "%Y-%m-%dT%H:%M:%S%z";

use MIME::Words qw(:all);

# message types
sub unmime {                                                                                                
    my ($enc) = @_;                                                                                         


    my @words = decode_mimewords($enc);                                                                     


    my $dec = "";                                                                                           
    for ( @words) {                                                                                         
        eval {                                                                                              
            $dec .= $_->[1] ? decode_mimewords($_->[1], $_->[0]) : $_->[0];                                 
        };                                                                                                  
        if ($@) {                                                                                           
            # if decoding fails for any reason (usually unknown charset)                                    
            # we just append he encoded word.                                                               
            print "Decoding failed: $enc\n";
            #$dec .= $_->[0];                                                                               
        }                                                                                                   
    }                                                                                                       
    return $dec;                                                                                            
}
 

sub new
{
    my $class = shift;
    my $id = shift || 0;
    my $filename = shift || '/var/log/open-as-cgw/mail.log';
    
    my $self = $class->SUPER::new($id);

    my $fh = open_fh($filename);
    my $sel = new IO::Select($fh) ;

    $self->{'_stat'} = [ _stat($filename) ];

    unless ($fh)
    {
        die "couldn't access file $filename";
    }
    
    $self->{'_sel'} = $sel;
    $self->{'_fh'} = $fh;
    $self->{'_filename'} = $filename;

    return $self;
}  

# taken from IO::File::Log

sub _stat ($) {
    return (stat $_[0])[0, 1, 6];
}

sub _dcomp {
    my $l1 = shift;
    my $l2 = shift;

    return 0 unless @$l1 and @$l2;

    for (@$l1 < @$l2 ? 0 .. @$l1 : 0 .. @$l2) {
    return 0 if 
        defined $l1->[$_] and defined $l2->[$_] and $l1->[$_] ne $l2->[$_];
    }

    return 1;
}     

sub open_fh
{
    my $filename = shift;

    # create the file if non existant
    unless (-e $filename)
    {
        system("/usr/bin/touch $filename");
    }

    # set ownerships and rights
    my $uid = getpwnam("root");
    my $gid = getgrnam("limes");
    chown $uid, $gid, $filename;
    chmod oct("0660"), $filename;

    my $fh = new IO::File($filename,"a+");
    unless ($fh)
    {
        die "Couldn't open file $filename";
    }
    autoflush $fh 1; 
    return $fh;
}

sub fh
{
    my $self = shift;
    my $select = $self->{'_sel'};
    
    if (-f $self->{'_filename'} and 
        ! _dcomp([(stat($self->{'_filename'}))[0, 1, 6]], 
             $self->{'_stat'}))
    {
        # alright
    }
    else
    {
        $select->remove($self->{'_fh'});
        $self->{'_fh'}->close;
        $self->{'_fh'} = open_fh($self->{'_filename'}); 
        $self->{'_stat'} = [ _stat($self->{'_filename'}) ];
        $select->add($self->{'_fh'}); 
    }
    my $fh = ($select->can_write)[0] or die "Couldn't get filehandle!";
    return $fh;
}

sub log
{
    my $self = shift;
    my $string = shift;
    my $fh = $self->fh;

    print $fh $string;    
}

sub run
{
    my $self = shift;

    @SIG{'INT','QUIT','TERM','HUP'} = (\&handler) x 4;

    my $count = 0;
    while (1)
    {
        my $mail_hash = $self->mq->rcv;
        if (defined $mail_hash)
        {
            my $type = $mail_hash->{'type'};
            my $mail = $mail_hash->{'mail'};
            $count++;
            # do stuff
            
            if ($type == Underground8::Log::Writer::Email::ACCEPTED)
            {
                my $status_string = "";
                if ($mail->amavis_status =~ qr/SPAMMY/)
                {
                    $status_string = "TAGGED";
                }                            
                else
                {
                    $status_string = "CLEAN";
                }
                $self->log(sprintf("%s %s msgid=<%s> from=<%s> to=<%s> host=%s queuenr=%s subject=\"%s\" status=\"%s\" hits=%2.2f delay=%3.4fsec\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $status_string,
                                                                                       $mail->msg_id,
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip,
                                                                                       $mail->queue_nr,
                                                                                       unmime($mail->subject),
                                                                                       $mail->amavis_status,
                                                                                       $mail->amavis_hits || 0,
                                                                                       $mail->delay));
            }
            elsif ($type == Underground8::Log::Writer::Email::GREYLISTED)
            {
                 $self->log(sprintf("%s GREYLISTED from=<%s> to=<%s> host=%s\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip
                                                                                       ));
            }
            elsif ($type == Underground8::Log::Writer::Email::BLOCKEDBL)
            {
                 $self->log(sprintf("%s BLOCKED BLACKLISTED from=<%s> to=<%s> host=%s\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip,
                                                                                       ));
            } 
            elsif ($type == Underground8::Log::Writer::Email::BLOCKEDVIRUS)
            {
                $self->log(sprintf("%s BLOCKED VIRUS msgid=<%s> from=<%s> to=<%s> host=%s queuenr=%s subject=\"%s\" status=\"%s\" virus=\"%s\" delay=%3.4fsec\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $mail->msg_id,
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip,
                                                                                       $mail->queue_nr,
                                                                                       unmime($mail->subject),
                                                                                       $mail->amavis_status,
                                                                                       $mail->amavis_detail,
                                                                                       $mail->delay));
            }                                         
            elsif ($type == Underground8::Log::Writer::Email::BLOCKEDBF)
            {
                $self->log(sprintf("%s BLOCKED BANNED FILE msgid=<%s> from=<%s> to=<%s> host=%s queuenr=%s subject=\"%s\" status=\"%s\" file=\"%s\" delay=%3.4fsec\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $mail->msg_id,
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip,
                                                                                       $mail->queue_nr,
                                                                                       unmime($mail->subject),
                                                                                       $mail->amavis_status,
                                                                                       $mail->amavis_detail,
                                                                                       $mail->delay));
            } 
            elsif ($type == Underground8::Log::Writer::Email::BLOCKEDSPAM)
            {
                $self->log(sprintf("%s BLOCKED SPAM msgid=<%s> from=<%s> to=<%s> host=%s queuenr=%s subject=\"%s\" status=\"%s\" hits=%2.2f delay=%3.4fsec\n",
                                                                                       time2str($TIME_TPLT,$mail->received_log),
                                                                                       $mail->msg_id,
                                                                                       $mail->from,
                                                                                       $mail->to,
                                                                                       $mail->client_ip,
                                                                                       $mail->queue_nr,
                                                                                       unmime($mail->subject),
                                                                                       $mail->amavis_status,
                                                                                       $mail->amavis_hits,
                                                                                       $mail->delay));
            } 
            elsif ($type == Underground8::Log::Writer::Email::RELAYED)
            {
                $self->log(sprintf("%s RELAY=%s to=<%s> relayhost=%s relaymsg=\"%s\"\n",
                                time2str($TIME_TPLT,$mail->received_log),
                                $mail->relay_status,
                                $mail->to,
                                $mail->relay,
                                $mail->relay_msg
                                ));
            }
        }
    }
}

sub handler
{
    exit(0);
}

1;

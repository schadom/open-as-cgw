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


package Underground8::Log::MQ::Email;
# IPC Message Queue for Object Passing
# from Log::Listener::EMail to Log::Writer::Email::X;

use strict;
use warnings;
                                              
use Underground8::Log::Email;
use Storable qw(nfreeze thaw);
use IPC::SysV qw(S_IRWXU IPC_CREAT IPC_NOWAIT ftok);
use IPC::Msg;
use constant MMQ        => "/etc/group"; # shouldnt change
use constant MMQID      => 137;
use constant MMQSIZE    => 33554432; # 32MBytes
use constant MMQBUFLEN  => 4096;

sub new
{
    my $class = shift;
    my $increment = shift || 0; # if you want more queues

    my $mmqid = MMQID + $increment;

    my $qkey = ftok(MMQ,$mmqid);

    my $msg = new IPC::Msg($qkey, S_IRWXU | IPC_CREAT);
    $msg->set(qbytes => MMQSIZE); # set queue size 

    my $self = {
        mq => $msg 
    };

    $self = bless $self, $class;
    return $self;
}    

sub mq
{
    my $self = shift;
    return $self->{'mq'};
}

sub snd
{
    my $self = shift;
    my $mail = shift;
    my $type = shift || 1;

    warn "No Underground8::Log::Email Object!" && return if not $mail->isa('Underground8::Log::Email');

    my $freezed_mail = nfreeze($mail);
    my $packet = pack("l! a*", $type, $freezed_mail);

    if (length($packet) >= MMQBUFLEN)
    {
        warn("Alert! MQ-packet too big for MQ. Deleting too long message. This should never happen ...");
    }
    else
    { 
        $self->mq->snd(1, $packet, IPC_NOWAIT) or die ($!);
    }
}


sub rcv
{
    my $self = shift;

    my $mail = undef;
    my $return = { };
    
    my $t = $self->mq->rcv($mail, MMQBUFLEN, 1, 0);


    # valid message has t == 1
    if ($t == 1)
    {
        if (defined $mail)
        {
            my ($type, $unpacked_mail) = unpack("l! a*", $mail);

            my $mail_obj = thaw($unpacked_mail); 

            if (defined $mail_obj)
            {
                warn "No Underground8::Log::Email Object!" && return if not $mail_obj->isa('Underground8::Log::Email');
                $return->{'type'} = $type;
                $return->{'mail'} = $mail_obj;
                return $return;
            }
            else
            {
                return undef;
            }
        }
        else
        {
            return undef;
        }
    }
    else
    {
        return undef;
    }
}


sub remove
{
    my $self = shift;
    $self->mq->remove;
}

1;

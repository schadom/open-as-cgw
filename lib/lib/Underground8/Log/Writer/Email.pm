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


package Underground8::Log::Writer::Email;
use base Underground8::Log::Writer;

use strict;
use warnings;

use Underground8::Log::Email;
use Underground8::Log::MQ::Email;
use IO::File;
 
use constant ACCEPTED       => 10;
use constant GREYLISTED     => 11;
use constant BLOCKEDBL      => 12;
use constant BLOCKEDVIRUS   => 13;
use constant BLOCKEDBF      => 14;
use constant BLOCKEDSPAM    => 15;
use constant RELAYED        => 20;

sub new
{
    my $class = shift;
    my $id = shift;
    
    my $mq = new Underground8::Log::MQ::Email($id);

    my $self = {
        _mq => $mq,
    };
    bless $self, $class;
    return $self;
}

sub mq
{
    my $self = shift;
    return $self->{'_mq'};
}

sub commit_relayed
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,RELAYED) or die "couldn't send to mq";
}

sub commit_accepted
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,ACCEPTED) or die "couldn't send to mq";
}

sub commit_greylisted
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,GREYLISTED) or die "couldn't send to mq";
}

sub commit_blocked_blacklist
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,BLOCKEDBL) or die "couldn't send to mq";
}

sub commit_blocked_bannedfile
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,BLOCKEDBF) or die "couldn't send to mq";
}

sub commit_blocked_virus
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,BLOCKEDVIRUS) or die "couldn't send to mq";
}

sub commit_blocked_spam
{
    my $self = shift;
    my $mail = shift;
    $self->mq->snd($mail,BLOCKEDSPAM) or die "couldn't send to mq";
}

sub DESTROY
{
    my $self = shift;

    my $mq = $self->mq;
    #$mq->remove if $mq;
}

1; 

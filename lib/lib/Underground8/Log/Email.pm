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


package Underground8::Log::Email;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self = {
        _msg_id         => '',
        _queue_nr       => '',
        _received       => undef,
        _received_log   => undef,
        _delay          => undef,
        _from           => '',
        _to             => '',
        _subject        => '',
        _client_ip      => '',
        _sqlgrey_status => '',
        _amavis_status  => '',
        _amavis_detail  => '',
        _amavis_hits    => undef,
        _relay          => '',
        _relay_status   => '',
        _relay_msg      => '',
    };

    $self = bless $self, $class;
    return $self;
}

sub complete
{
    my $self = shift;
    return $self->msg_id && $self->queue_nr && $self->received && $self->received_log && $self->delay && $self->from && $self->to && $self->client_ip && $self->sqlgrey_status && $self->amavis_status;
}

sub msg_id
{
    my $self = shift;
    $self->{'_msg_id'} = shift if @_;
    return $self->{'_msg_id'};
}

sub queue_nr
{
    my $self = shift;
    $self->{'_queue_nr'} = shift if @_;
    return $self->{'_queue_nr'};
}

sub received
{
    my $self = shift;
    $self->{'_received'} = shift if @_;
    return $self->{'_received'};
}

sub received_log
{
    my $self = shift;
    $self->{'_received_log'} = shift if @_;
    return $self->{'_received_log'};
}

sub delay
{
    my $self = shift;
    $self->{'_delay'} = shift if @_;
    return $self->{'_delay'};
}

sub from
{
    my $self = shift;
    $self->{'_from'} = shift if @_;
    return $self->{'_from'};
}

sub to
{
    my $self = shift;
    $self->{'_to'} = shift if @_;
    return $self->{'_to'};
}

sub subject
{
    my $self = shift;
    $self->{'_subject'} = shift if @_;
    return $self->{'_subject'};
}

sub sqlgrey_status
{
    my $self = shift;
    $self->{'_sqlgrey_status'} = shift if @_;
    return $self->{'_sqlgrey_status'};
}

sub client_ip
{
    my $self = shift;
    $self->{'_client_ip'} = shift if @_;
    return $self->{'_client_ip'};
}

sub amavis_status
{
    my $self = shift;
    $self->{'_amavis_status'} = shift if @_;
    return $self->{'_amavis_status'};
}

sub amavis_hits
{
    my $self = shift;
    if (@_)
    {
        my $hits = shift;
        $self->{'_amavis_hits'} = $hits if ($hits ne '-');
    }
    return $self->{'_amavis_hits'};
}

sub amavis_detail
{
    my $self = shift;
    $self->{'_amavis_detail'} = shift if @_;
    return $self->{'_amavis_detail'};
}

sub relay
{
    my $self = shift;
    $self->{'_relay'} = shift if @_;
    return $self->{'_relay'};
}

sub relay_status
{
    my $self = shift;
    $self->{'_relay_status'} = shift if @_;
    return $self->{'_relay_status'};
}

sub relay_msg
{
    my $self = shift;
    $self->{'_relay_msg'} = shift if @_;
    return $self->{'_relay_msg'};
} 

sub to_string
{
    my $self = shift;

    return sprintf("*MAIL* from: %s to: %s ip: %s sqlgrey-status: %s",$self->from,$self->to,$self->client_ip,$self->sqlgrey_status);
}

1;

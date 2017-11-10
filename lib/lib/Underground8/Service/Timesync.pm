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


package Underground8::Service::Timesync;
use base Underground8::Service;


use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Timesync::SLAVE;
use Data::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Timesync::SLAVE();
    $self->{'_server'} = ();
    return $self;
}

#### Accessors ####

sub time_servers($)
{
    my $self = instance(shift);
    
    return $self->{'_server'};
}

sub add_server($$)
{
    my $self = instance(shift);
    my $newserver = shift;
    push @{$self->{'_server'}}, $newserver;
    $self->change;
}

sub del_server
{
    my $self = instance(shift);
    my $delid = shift;
    splice(@{$self->{'_server'}}, $delid, 1);
    $self->change;
}

sub change_server
{
    my $self = instance(shift);
    my $changeid = shift;
    my $newserver = shift;
    $self->{'_server'}[$changeid] = $newserver;
    $self->change;
}

#### Misc methods ####



sub commit ($)
{
    my $self = instance(shift);
    $self->slave->write_config( $self->time_servers ) if( $self->is_changed() );
    $self->unchange;
}

1;

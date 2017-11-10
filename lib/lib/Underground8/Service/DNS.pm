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


package Underground8::Service::DNS;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::DNS::SLAVE;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::DNS::SLAVE();
    $self->{'_hostname'} = undef;
    $self->{'_domainname'} = undef;
#    $self->{'_primary_dns'} = undef;
#    $self->{'_secondary_dns'} = undef;
#    $self->{'_use_local_cache'} = 1;
    return $self;
}

#### Accessors ####

sub hostname ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_hostname'} = shift;
        $self->change;
    }
    return $self->{'_hostname'};
}

sub domainname ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_domainname'} = shift;
        $self->change;
    }
    return $self->{'_domainname'};
}

#sub use_local_cache ($@)
#{
#    my $self = instance(shift);
#    if (@_)
#    {
#        $self->{'_use_local_cache'} = shift;
#        $self->change;
#    }
#    return $self->{'_use_local_cache'};
#}

#sub primary_dns($@)
#{
#    my $self = instance(shift);
#    if (@_)
#    {
#        $self->{'_primary_dns'} = shift;
#        $self->change;
#    }
#    return $self->{'_primary_dns'};
#}

#sub secondary_dns($@)
#{
#    my $self = instance(shift);
#    if (@_)
#    {
#        $self->{'_secondary_dns'} = shift;
#        $self->change;
#    }
#    return $self->{'_secondary_dns'};
#}

#### Misc methods ####

sub commit ($)
{
    my $self = instance(shift);
    $self->slave->write_config( #$self->primary_dns,
                                #$self->secondary_dns,
                                #$self->use_local_cache,
                                $self->hostname,
                                $self->domainname);
    $self->slave->service_restart();
    $self->unchange;
}
1;

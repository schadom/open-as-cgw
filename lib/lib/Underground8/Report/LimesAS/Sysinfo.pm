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


package Underground8::Report::LimesAS::Sysinfo;
use base Underground8::Report;

use strict;
use warnings;

use Underground8::Utils;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'cpu_total'} = undef;
    $self->{'cpu_avg_24h'} = undef; # the value to be sent in report mail !
    $self->{'cpu_avg_1h'} = undef;
    #$self->{'fsusage_root'} = undef;
    $self->{'mem_total'} = undef;
    $self->{'mem_used'} = undef;
    $self->{'mem_free'} = undef;
    $self->{'mem_used_percentage'} = undef;
    $self->{'swap_total'} = undef;
    $self->{'swap_used'} = undef;
    $self->{'swap_free'} = undef;
    $self->{'swap_used_percentage'} = undef;
    $self->{'loadavg_1'} = undef;
    $self->{'loadavg_5'} = undef;
    $self->{'loadavg_15'} = undef;
    $self->{'uptime'} = undef;

    bless $self, $class;
    return $self;
}


1;

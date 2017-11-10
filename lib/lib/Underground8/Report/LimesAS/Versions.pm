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


package Underground8::Report::LimesAS::Versions;
use base Underground8::Report;

use strict;
use warnings;

use Underground8::Utils;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'version_system'} = undef;
    $self->{'version_revision'} = undef;
    $self->{'version_system_available'} = undef;
    $self->{'version_system_all'} = undef;
    $self->{'last_update'} = undef;
    $self->{'version_build'} = undef;
    $self->{'time_system'} = undef;
    $self->{'version_clamav'} = undef;
    $self->{'time_clamav'} = undef;
    $self->{'version_spamassassin'} = undef;

    bless $self, $class;
    return $self;
}

# Marketing Versions
sub antispam
{
    my $self = instance(shift);
    return $self->{'version_spamassassin'};
}
# Marketing Versions
sub antivirus
{
    my $self = instance(shift);
    return $self->{'version_clamav'};
}
# Marketing Versions
sub system   
{
    my $self = instance(shift);
    return $self->{'version_system'};
}
# Marketing Versions
sub build
{
    my $self = instance(shift);
    return $self->{'version_build'};
}
# Marketing Versions
sub revision
{
    my $self = instance(shift);
    return $self->{'version_revision'};
}

sub system_available
{
    my $self = instance(shift);
    return $self->{'version_system_available'};
}

sub system_all
{
    my $self = instance(shift);
    return $self->{'version_system_all'}
}

1;

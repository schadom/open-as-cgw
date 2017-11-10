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


package Underground8::Service::Timezone;
use base Underground8::Service;


use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Timezone::SLAVE;
use Data::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Timezone::SLAVE();
    $self->{'_has_changes'} = 0;
    $self->{'_current_timezone'} = undef;
    $self->{'_timezones'} = {};
    return $self;
}

#### Accessors ####

sub initialize_timezones($)
{
    my $self = instance(shift);
    my @regions = (
                   'Africa',
                   'America',
                   'Antarctica',
                   'Arctic',
                   'Asia',
                   'Atlantic',
                   'Australia',
                   'Brazil',
                   'Canada',
                   'Chile',
                   'Europe',
                   'Indian',
                   'Mexico',
                   'Mideast',
                   'Pacific',
                   'US'
                  );
    
    foreach my $region (@regions)
    {
        $self->{'_timezones'}->{$region} = $self->slave->get_zones($region);

    }
    $self->change;
}

sub timezones($)
{
    my $self = instance(shift);
    return $self->{'_timezones'};
}

sub timezone($$)
{
    my $self = instance(shift);
    my $newzone = shift;
    
    if ($newzone)
    {
        $self->{'_current_timezone'} = $newzone;
        $self->change;
    }
    return $self->{'_current_timezone'};
}



#### Misc methods ####



sub commit ($)
{
    my $self = instance(shift);
    my $files;
    push @{$files}, "/etc/localtime";

    my $md5_first = $self->create_md5_sums($files);
    $self->slave->write_config( $self->timezone ) if( $self->is_changed() );
    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart;
    }

    $self->unchange;
}

1;

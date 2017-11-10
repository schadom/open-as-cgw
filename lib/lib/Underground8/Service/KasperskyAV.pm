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


package Underground8::Service::KasperskyAV;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::KasperskyAV::SLAVE;

#Constructor
sub new ($$)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::KasperskyAV::SLAVE();
    $self->{'_archive_recursion'} = 0;
    $self->{'_archive_maxfilesize'} = '10M';
    $self->{'_archive_maxfiles'} = 2500;


    return $self;
}                                                        
                                                         
#### Accessors ####

sub archive_recursion
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_archive_recursion'} = shift;
        $self->change;
    }
    return $self->{'_archive_recursion'};
}

sub commit
{
    my $self = shift;

    my $archive_recursion = $self->{'_archive_recursion'};

    my $files;
    push @{$files}, $g->{'file_kaspersky_kavserverconf'};
    push @{$files}, $g->{'file_kaspersky_kavupdaterconf'};
    my $md5_first = $self->create_md5_sums($files);

    $self->slave->write_config($archive_recursion);

    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }
    $self->unchange;

}


1;

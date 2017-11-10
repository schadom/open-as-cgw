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


package Underground8::Service::Monit;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Monit::SLAVE;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;

use Data::Dumper;

# Constructor
sub new($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Monit::SLAVE();

    return $self;
}

sub remove_slave ($)
{
    my $self = instance(shift);
    delete $self->{'_slave'};
}

sub commit($)
{
    my $self = instance(shift);

    my $files;
    push @{$files}, $g->{'file_monit'};
    push @{$files}, $g->{'file_monit_default'};
    safe_system($g->{'cmd_monit_perm_addgrp'});
    my $md5_first = $self->create_md5_sums($files);
    
    $self->slave->write_config();

    safe_system($g->{'cmd_monit_perm_addgrp'});
    my $md5_second = $self->create_md5_sums($files);

    safe_system($g->{'cmd_monit_perm_delgrp'});

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }
    $self->unchange;
}

1;

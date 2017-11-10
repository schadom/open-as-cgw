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


package Underground8::Service::SyslogNG;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::SyslogNG::SLAVE;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;

use Data::Dumper;

# Constructor
sub new($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::SyslogNG::SLAVE();
    $self->{'_host'} = undef;
    $self->{'_port'} = undef;
    $self->{'_proto'} = undef;
    $self->{'_enabled'} = 0;


    return $self;
}

### Accessors ###
sub enabled ($)
{
    my $self = instance(shift);
    if (@_)
    {
        my $param = shift;
        if ($param == 1)
        {
            $self->change if ($self->{'_enabled'} != $param);
            $self->{'_enabled'} = 1;
        }
        else
        {
            $self->change if ($self->{'_enabled'} != $param);
            $self->{'_enabled'} = 0;
        }
    }

    return $self->{'_enabled'};
}



sub host ($)
{
    my $self = instance(shift);
    my $param = shift;
    
    if ($param)
    {
        if ($self->{'_host'})
        {
            $self->change if ($self->{'_host'} ne $param);
        }
        else
        {
            $self->change;
        }

        $self->{'_host'} = $param;
    }

    return $self->{'_host'};
}



sub port ($)
{
    my $self = instance(shift);
    my $param = shift;
    
    if ($param)
    {
        if ($self->{'_port'})
        {
            $self->change if ($self->{'_port'} != $param);
        }
        else
        {
            $self->change;
        }

        $self->{'_port'} = $param;
    }

    return $self->{'_port'};
}


sub proto ($)
{
    my $self = instance(shift);
    my $param = shift;

    if($param)
    {
        if ($self->{'_proto'})
        {
            $self->change if ($self->{'_proto'} ne $param);
        }
        else
        {
            $self->change;
        }

        $self->{'_proto'} = $param;
    }

    return $self->{'_proto'};
}




sub remove_slave ($)
{
    my $self = instance(shift);
    delete $self->{'_slave'};
}



sub commit ($)
{
    my $self = instance(shift);

    my $files;
    push @{$files}, $g->{'file_syslogng'};
    push @{$files}, $g->{'file_syslogng_logrotate'};

    my $md5_first = $self->create_md5_sums($files);
    $self->slave->write_config($self->enabled, $self->host, $self->port, $self->proto);
    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }
    $self->unchange;
}

1;

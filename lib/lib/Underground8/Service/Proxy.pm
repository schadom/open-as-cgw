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


package Underground8::Service::Proxy;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Proxy::SLAVE;

# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Proxy::SLAVE();
    $self->{'_proxy_server'} = "";
    $self->{'_proxy_port'} = "";
    $self->{'_proxy_username'} = "";
    $self->{'_proxy_password'} = "";
    $self->{'_proxy_enabled'} = "0";
    return $self;
}

#### Accessors ####

sub proxy_enabled ($)
{
    my $self = instance(shift);
    if (@_)
    {
        my $param = shift;
        if ($param == 1)
        {
            $self->change if ($self->{'_proxy_enabled'} != $param);
            $self->{'_proxy_enabled'} = 1;
        }
        else
        {
            $self->change if ($self->{'_proxy_enabled'} != $param);
            $self->{'_proxy_enabled'} = 0;
        }
    }

    return $self->{'_proxy_enabled'};
}

sub proxy_server($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_proxy_server'} = shift;
        $self->change;
    }
    return $self->{'_proxy_server'};
}

sub proxy_port($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_proxy_port'} = shift;
        $self->change;
    }
    return $self->{'_proxy_port'};
}

sub proxy_username($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_proxy_username'} = shift;
        $self->change;
    }
    return $self->{'_proxy_username'};
}

sub proxy_password($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_proxy_password'} = shift;
        $self->change;
    }
    return $self->{'_proxy_password'};
}

#### Misc methods ####

sub commit ($)
{
    my $self = instance(shift);

    my $files;
    push @{$files}, $g->{'file_clamav_freshclamconf'};
    
    my $md5_first = $self->create_md5_sums($files);
    $self->slave->write_config( $self->proxy_server,
                                $self->proxy_port,
                                $self->proxy_username,
                                $self->proxy_password,
                                $self->proxy_enabled);
    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }
    $self->unchange;
}

1;

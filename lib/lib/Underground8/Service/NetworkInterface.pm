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


package Underground8::Service::NetworkInterface;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::NetworkInterface::SLAVE;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::NetworkInterface::SLAVE();
    $self->{'_name'} = $name;
    $self->{'_notify'} = 0;
    $self->{'_user_change'} = 0;
    $self->{'_ip_address'} = '';
    $self->{'_subnet_mask'} = '';
    $self->{'_default_gateway'} = '';
    $self->{'_old_name'} = $name;
    $self->{'_old_ip_address'} = '';
    $self->{'_old_subnet_mask'} = '';
    $self->{'_old_default_gateway'} = '';

    # from DNS.pm - needs to be here for ubunt 14.04
    $self->{'_primary_dns'} = undef;
    $self->{'_secondary_dns'} = undef;
    $self->{'_use_local_cache'} = 1;
    $self->{'_domainname'} = undef;

    return $self;
}
#### Accessors ####

# ro
sub name ($@)
{
    my $self = instance(shift);
    return $self->{'_name'};
}

sub user_change ($$)
{
    my $self = instance(shift);
    if(@_)
    {
        $self->{'_user_change'} = shift;
    }
    return $self->{'_user_change'};
}

sub ip_address ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_ip_address'} = shift;
        $self->change;
    }
    return $self->{'_ip_address'};
}

sub subnet_mask ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_subnet_mask'} = shift;
        $self->change;
    }
    return $self->{'_subnet_mask'};
}

sub default_gateway ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_default_gateway'} = shift;
        $self->change;
    }
    return $self->{'_default_gateway'};
}

sub notify
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_notify'} = shift;
        $self->change;
    }
    return $self->{'_notify'};
}

sub newconf_to_oldconf
{
    my $self = instance(shift);
    $self->{'_old_name'} = $self->{'_name'};
    $self->{'_old_ip_address'} = $self->{'_ip_address'};
    $self->{'_old_subnet_mask'} = $self->{'_subnet_mask'};
    $self->{'_old_default_gateway'} = $self->{'_default_gateway'};    
}

sub oldconf_to_newconf
{
    my $self = instance(shift);
    $self->{'_name'} = $self->{'_old_name'};
    $self->{'_ip_address'} = $self->{'_old_ip_address'};
    $self->{'_subnet_mask'} = $self->{'_old_subnet_mask'};
    $self->{'_default_gateway'} = $self->{'_old_default_gateway'};
}
sub revoke_crontab ($)
{
    my $self = instance(shift);
    $self->slave->revoke_crontab($self->name);
}
sub revoke_settings ($)
{
    my $self = instance(shift);
    $self->oldconf_to_newconf();
    $self->notify('0');
}

sub create_crontab ($$)
{
    my $self = instance(shift);
    $self->slave->create_crontab(shift);
}
sub service_restart ($)
{
    my $self = instance(shift);
    $self->slave->service_restart($self->name);
}

sub restart_webserver ($)
{
    my $self = instance(shift);
    $self->slave->restart_webserver();
}

sub primary_dns($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_primary_dns'} = shift;
        $self->change;
    }
    return $self->{'_primary_dns'};
}

sub secondary_dns($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_secondary_dns'} = shift;
        $self->change;
    }
    return $self->{'_secondary_dns'};
}

sub domainname($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_domainname'} = shift;
        $self->change;
    }
    return $self->{'_domainname'};
}


sub use_local_cache ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_use_local_cache'} = shift;
        $self->change;
    }
    return $self->{'_use_local_cache'};
}




#### Misc methods ####
sub commit ($)
{
    # user_change Values:
    # 0: System makes a commit without user calling
    #   -> configure the interface but don't create a cron revoke
    # 1: User triggered an IP change
    #   -> configure the interface and create a crontab
    # 2: User clicked on confirmed new settings
    #   -> remove the crontab and just write the xml's
    my $self = instance(shift);
    # Except we received a "confirmed change", write new settings
    $self->slave->write_config( $self->name,
                                $self->ip_address,
                                $self->subnet_mask,
                                $self->default_gateway,
                                $self->primary_dns,
                                $self->secondary_dns,
                                $self->use_local_cache,
                                $self->domainname ) unless ($self->user_change == 2);
    # Only if user changes, create crontab
    if ($self->user_change == 1)
    { 
        $self->slave->create_crontab($self->name);
    }
    # restart network except we received a "confirmed change"
    $self->slave->trigger_service_restart($self->name) unless ($self->user_change == 2);
    # If we got a confirm, remove the crontab and set notify to 0
    if ($self->user_change == 2)
    {
        $self->revoke_crontab();
        $self->notify(0);
    }
    $self->user_change(0);
    $self->unchange;
}

1;

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


package Underground8::Appliance;

use strict;
use warnings;

use Underground8::Utils;
use Sys::Statistics::Linux;
use Underground8::Log;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self;


    my $lxs = new Sys::Statistics::Linux;
    $lxs->set(
        SysInfo   => 1,
        CpuStats  => 0,
        ProcStats => 0,
        MemStats  => 1,
        PgSwStats => 0,
        NetStats  => 0,
        SockStats => 0,
        DiskStats => 0,
        DiskUsage => 0,
        LoadAVG   => 0,
        FileStats => 0,
        Processes => 0,
    ); 
    my $result = $lxs->get;
   
    $self->{'_name'} =      $name;
    $self->{'_version'} =   '0.01';
    $self->{'_config_lock'} = 0;
    $self->{'_alert_notify'} = 0;
    $self->{'_cpu_count'} = $result->{'SysInfo'}->{'countcpus'};
    $self->{'_total_memory'} = $result->{'MemStats'}->{'memtotal'};
    $self->{'_temp_dir'} = '';
    
    bless $self, $class;
    return $self;
}

sub config_lock
{
    my $self = instance(shift);
    return $self->{'_config_lock'};
}

sub set_config_lock_temp
{
    my $self = instance(shift);
    $self->{'_config_lock'} = 1;
}

sub set_config_lock_block
{
    my $self = instance(shift);
    $self->{'_config_lock'} = 2;
}

sub set_config_lock_unlock
{
    my $self = instance(shift);
    $self->{'_config_lock'} = 0;
}

sub alert_notify
{
    my $self = instance(shift);
    return $self->{'_alert_notify'};
}

sub cpu_count
{
    my $self = instance(shift);
    return $self->{'_cpu_count'};
}

sub total_memory
{
    my $self = instance(shift);
    return $self->{'_total_memory'};
}

# alert_notify:
# Binary Status
# 1.... NetworkInterface Changed
# 2.... free to be used
# 3.... free to be used
# 4.... free to be used
# 5.... free to be used
# ...
###### Operations:
# Set 1 to true:
# $a |= (1 << 1)
# Set 2 to true:
# $a |= (1 << 2)
# Toggle 1 (if set unset it, if unset, set it):
# $a ^= (1 << 1)
# Check if 1 is set:
# if ($a & (1 << 1))
# Check if 2 is set:
# if ($a & (1 << 2))

sub set_alert_notify_nic_change
{
    my $self = instance(shift);
    unless ($self->{'_alert_notify'} & (1 << 1))
    {
        $self->{'_alert_notify'} |= (1 << 1);
    }    
}

sub unset_alert_notify_nic_change
{
    my $self = instance(shift);
    if ($self->{'_alert_notify'} & (1 << 1))
    {
        $self->{'_alert_notify'} ^= (1 << 1);
    }
}

sub check_alert_notify_nic_change
{
    my $self = instance(shift);
    if ($self->{'_alert_notify'} & (1 << 1))
    { return 1;}
    else
    { return 0;}
}

1;

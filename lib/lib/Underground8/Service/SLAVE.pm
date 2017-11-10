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


package Underground8::Service::SLAVE;

use strict;
use warnings;

use Underground8::Utils;
use Carp;
use Sys::Statistics::Linux;
use Underground8::ReportFactory::LimesAS;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $service_name = shift;

    my $self;
    $self = {
            _service_name => $service_name,
    };
    bless $self, $class;
    return $self;
}


# prototypes
sub write_config ($$);

sub service_start ($);

sub service_stop ($);

sub service_restart ($);

sub service_reload ($);


sub service_name ($@)
{
    my $self = instance(shift);
    $self->{'_service_name'} = shift if @_;
    return $self->{'_service_name'};
}

sub memory_factor
{
    my $lxs = new Sys::Statistics::Linux;                                                                                                                    
                                                                                                                                                         
    $lxs->set(
        SysInfo   => 1,
        CpuStats  => 1,
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
    my $total_memory = $result->{'MemStats'}->{'memtotal'};

    #my $rounded_memory = sprintf ("%.0f", $total_memory / 2097152);  #2GB
    my $rounded_memory = sprintf ("%.0f", $total_memory / 1048576);   #1GB

    $rounded_memory = 0.25 if $rounded_memory < 1;
    return $rounded_memory;   
}

sub quarantine_soft_state
{
    my $state = get_quarantine_state("soft");
    return $state;
}
    
sub quarantine_hard_state
{
    my $state = get_quarantine_state("hard");
    return $state;
}
    
sub get_quarantine_state
{
    my $type = shift;
    my $config_path = "/var/quarantine/quarantine.lock";
    my $quarantine_lock_file = read_config_file($config_path);
    return $quarantine_lock_file->{$type};
}

sub report
{
    my $report = new Underground8::ReportFactory::LimesAS;
    return $report;
}

=head1 DESCRIPTION

SLAVE - Static Module to read and write configuration of a service. This is a interface which should be implemented by the service slaves.

=head1 SYNOPSIS

read_config ()      # retrieve a service object out of a configuration file/db/...

read_value ($)      # retrieve a specified value

write_config ($)    # write the service configuration

write_value ($$)    # write a specified value

service_start ()    # start the service

service_stop ()     # stop the service

service_restart ()  # restart the service

service_reload ()   # reload the service

=head1 AUTHORS

Matthias Pfoetscher, Underground_8

Harald Lampesberger, Underground_8

=cut
1;

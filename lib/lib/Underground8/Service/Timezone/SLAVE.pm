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


package Underground8::Service::Timezone::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Data::Dumper;
#use FastGlob qw(glob);

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('timezone');
}

sub service_start ($)
{
    # none 
}

sub service_stop ($)
{
    # none
}

sub service_restart ($$)
{
    # WTF? Why is this here? this is fucked up!
    safe_system($g->{'cmd_mysql_restart'});
    safe_system($g->{'cmd_rtlogd_restart'});
}

sub write_config ($@)
{
    my $self = instance(shift); 
    
    $self->write_timezone(@_);

}

sub get_zones($$)
{
    my $self = shift;
    my $region = shift;
    my @zones = ();
    
    @zones = glob("/usr/share/zoneinfo/$region/*");
    
    for (my $i = 0; $i < @zones; $i++)
    {
        $zones[$i] =~ s/\/usr\/share\/zoneinfo\/$region\///g;
    }

    
    return \@zones;
}    

sub write_timezone($$)
{
    my $self = instance(shift);
    my $newtz = shift;
    $g->{'cmd_cp'}
    if safe_system("$g->{'cmd_cp'} /usr/share/zoneinfo/$newtz /etc/localtime");
}

1;


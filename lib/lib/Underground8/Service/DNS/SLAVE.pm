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


package Underground8::Service::DNS::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use TryCatch;
use Underground8::Exception::FileOpen;
use Underground8::Exception::Execution;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('dns');
}

sub service_start ($)
{
    # nothing to do here 
}

sub service_stop ($)
{
    # nothing to do here
}

sub service_restart ($$)
{
    my $self = instance(shift);

    safe_system($g->{'cmd_dnsmasq_restart'},0,1)
	or throw Underground8::Exception::Execution($g->{'cmd_dnsmasq_restart'});
}

sub write_config ($$$$$)
{
    my $self = instance(shift);
    my $hostname = shift;
    my $domainname = shift;

    $self->change_hostname($hostname,$domainname);
    $self->write_hosts_file($hostname,$domainname);
    $self->write_mailname_file($domainname);
}

sub change_hostname ($$)
{
    my $self = instance(shift);
    my $hostname = shift;
    my $domainname = shift;

    # hostnamectl set-hostname method
    safe_system("$g->{'cmd_hostname_change'} $hostname.$domainname",0,1);
}

sub write_hosts_file ($$$)
{
    my $self = instance(shift);
    my $hostname = shift;
    my $domainname = shift;

    open (HOSTS, '>', $g->{'file_hosts'})
        or throw Underground8::Exception::FileOpen($g->{'file_hosts'});

    print HOSTS "127.0.0.1    localhost\n";
    print HOSTS "127.0.1.1    $hostname.$domainname $hostname\n";

    close (HOSTS);
}

sub write_mailname_file ($$)
{
    my $self = instance(shift);
    my $mailname = shift;
     
    open (MAILNAME, '>', $g->{'file_mailname'})
        or throw Underground8::Exception::FileOpen($g->{'file_mailname'});
    
    print MAILNAME "$mailname\n";

    close (MAILNAME);
}

1;

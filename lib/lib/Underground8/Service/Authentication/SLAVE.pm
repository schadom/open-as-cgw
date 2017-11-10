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


package Underground8::Service::Authentication::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('authentication');
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
    # none
}

sub write_config ($$@)
{
    my $self = instance(shift); 
	my $hash_commonuse = shift;
    
    $self->write_users(@_);
	$self->write_passwd_commonuse($hash_commonuse);
}

sub write_passwd_commonuse($$){
	my $self = instance(shift);
	my $hash = shift;

	my $ec = 0;

	return $ec;
}

sub write_users($)
{
    my $self = instance(shift);
    my $users = shift;
    if ( ref($users) eq 'HASH')
    {
        open (GUIPASSWD,'>',$g->{'file_guipasswd'})
            or throw Underground8::Exception::FileOpen($g->{'file_guipasswd'});
        foreach my $user (keys %$users)
        {
			if( $user eq "admincli" ) {
				# Set gui password for CLI admin user
				my $admin_hash = $users->{'admincli'}->{'passwd'};
			    system( $g->{'cmd_usermod'} . " -p '$admin_hash' admin" ); 
				next;
			}

            print GUIPASSWD "${user}:$users->{$user}->{'passwd'}\n";
        }
        close (GUIPASSWD);
    }

}

1;

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


package Underground8::Service::Authentication;
use base Underground8::Service;

use Catalyst::Plugin::Authentication::Credential::Password;
use Catalyst::Plugin::Authentication;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Authentication::SLAVE;
use Data::Dumper;
use Apache::Htpasswd;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $name = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Authentication::SLAVE();
    $self->{'_users'} = {};
	$self->{'_commonuse'} = {};
    return $self;
}

#### Accessors ####

sub user_password ($$$$$$)
{
    my $self = instance(shift);
    my $user = shift;
    my $pw = shift;
    # if you change this to use database authent. use sub encrypt from this file instead of
    # CryptPasswd from Apache::Htpasswd
    my $handler = new Apache::Htpasswd({UseMD5 => 1});
    $self->users->{$user}->{'passwd'} = $handler->CryptPasswd($pw);

	if($user eq "admin") {
    	$self->users->{'admincli'}->{'passwd'} = crypt( $pw, "ab" );
	}

    $self->change;

}    

sub commonusers_password ($$){
	my $self = instance(shift);
	my $pw = shift;

	$self->{'_commonuse'}{'_pass_commonusers'} = crypt( $pw, "ab" );
	$self->change;	
}


sub users ($)
{
    my $self = instance(shift,__PACKAGE__);
    return $self->{'_users'};
}

sub pass_commonusers ($) {
	my $self = instance(shift, __PACKAGE__);
	return $self->{'_commonuse'}{'_pass_commonusers'};
}

#### Misc methods ####


## REMOVED in order not to need Digest::SHA2 in lucid
#sub encrypt ($)
#{
#    use Digest::SHA2;
#    my $text = shift;
#    my $context = new Digest::SHA2 256;
#    $context->add($text);
#    return my $crypttext = $context->b64digest();
#
#}

sub encrypt_md5 ($$)
{
    my $self = instance(shift);
		my $text = shift;
		my $salt = shift || undef;

    my $handler = new Apache::Htpasswd({UseMD5 => 1});
		return $handler->CryptPasswd($text, $salt);
}

sub authenticate ($$$)
{
    my $self = instance(shift,__PACKAGE__);
    my $user = shift;
    my $hash = shift;
    if ( $self->users->{$user}->{'passwd'} eq $hash )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub commit ($)
{
    my $self = instance(shift);
    $self->slave->write_config( $self->pass_commonusers , $self->users );
    $self->unchange;
}

1;

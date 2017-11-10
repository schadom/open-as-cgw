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


package Underground8::Configuration::LimesAS::MailQ;
use base Underground8::Configuration;

use strict;
use warnings;

#use Clone::Any qw(clone);
use Clone qw(clone);

use Underground8::Utils;
use Underground8::Service::MailQ;
use Data::Dumper;
use Error qw(:try);
use Underground8::Exception;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $appliance = shift;

    my $self = $class->SUPER::new("system",$appliance);
    
    $self->{'_mailq'} = new Underground8::Service::MailQ;
    return $self;
}

#### Accessors ####
# local only

sub purge ($)
{
    my $self = instance(shift,__PACKAGE__);
    $self->{'_mailq'}->purge();
}

1;

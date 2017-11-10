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


package Underground8::Notification::SLAVE;

use strict;
use warnings;

use Underground8::Utils;
use Carp;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $notification_name = shift;

    my $self;
    $self = {
            _notification_name => $notification_name,
    };
    bless $self, $class;
    return $self;
}


# prototypes
sub write_config ($$);

sub notification_name ($@)
{
    my $self = instance(shift);
    $self->{'_notification_name'} = shift if @_;
    return $self->{'_notification_name'};
}

1;
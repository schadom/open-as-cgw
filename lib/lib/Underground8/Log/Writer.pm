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


package Underground8::Log::Writer;

use strict;
use warnings;


sub new
{
    my $class = shift;
    my $self = { };

    bless $self, $class;
    return $class;
}


# fork and run
sub init
{
    my $self = shift;
    my $pid;
    
    # let's split
    $pid = fork();
    unless (defined $pid)
    {      
        warn "Error on fork!";
    }

    # daddy
    if ($pid != 0)
    {
        return $pid;
    }
    # child
    else
    {
        $self->run;
    }
}

# dummy
sub run
{
    return 0;
}


1;

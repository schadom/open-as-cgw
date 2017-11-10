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


package Underground8::Exception;
use base qw(Error);
use overload ('""' => 'stringify');
use Carp;

sub new
{
    my $self = shift;
    my $text = "EXCEPTION: " . shift;
    my $exception = shift;
    my @args = @_;

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;  # Enables storing of stacktrace

    $self = $self->SUPER::new(-text => $text, @args);
    $self->{'_caught_exception'} = $exception if $exception;

    return $self;
}

sub package
{
    my $self = shift;
    return $self->{'-package'};
}                         

sub caught_exception
{
    return $self->{'_caught_exception'};
}

1;

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


package LimesGUI::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    CATALYST_VAR => 'Catalyst',
    INCLUDE_PATH => [
        LimesGUI->path_to( 'root', 'src' ),
        LimesGUI->path_to( 'root', 'lib' )
    ],
    WRAPPER      => 'site/wrapper',
    ERROR        => 'catalyst_error.tt2',
    TIMER        => 0,
    render_die   => 1,
});

=head1 NAME

LimesGUI::View::TT - Catalyst TTSite View

=head1 SYNOPSIS

See L<LimesGUI>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Matthias Pfoetscher, underground_8

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


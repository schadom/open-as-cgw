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


package Catalyst::Plugin::Prototype::Underground8;

use strict;
use base 'Class::Data::Inheritable';
use HTML::Prototype;

our $VERSION = '1.00';

__PACKAGE__->mk_classdata('prototype');
eval { require HTML::Prototype::Underground8; };

if ( $@ ) {
    __PACKAGE__->prototype( HTML::Prototype->new );
} else {
    __PACKAGE__->prototype( HTML::Prototype::Underground8->new );
}

=head1 NAME

Catalyst::Plugin::Prototype - Plugin for Prototype

=head1 SYNOPSIS

    # use it
    use Catalyst qw/Prototype/;

    # ...add this to your tt2 template...
    [% c.prototype.define_javascript_functions %]

    # ...and use the helper methods...
    <div id="view"></div>
    <textarea id="editor" cols="80" rows="24"></textarea>
    [% uri = base _ 'edit/' _ page.title %]
    [% c.prototype.observe_field( 'editor', uri, { 'update' => 'view' } ) %]

=head1 DESCRIPTION

Some stuff to make Prototype fun.

This plugin replaces L<Catalyst::Helper::Prototype>.

=head2 METHODS

=head3 prototype

    Returns a ready to use L<HTML::Prototype> object.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

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


package Underground8::Configuration::LimesAS::DB;

=head1 NAME 

Underground8::Configuration::LimesAS::DB - DBIC Schema Class

=cut

# Our schema needs to inherit from 'DBIx::Class::Schema'
use base qw/DBIx::Class::Schema/;

# Need to load the DB Model classes here.
# You can use this syntax if you want:
#    __PACKAGE__->load_classes(qw/User UserRole Roles/);
# Also, if you simply want to load all of the classes in a directory
# of the same name as your schema class (as we do here) you can use:
#    __PACKAGE__->load_classes(qw//);
# But the variation below is more flexible in that it can be used to 
# load from multiple namespaces.
__PACKAGE__->load_classes({
    MyAppDB => [qw/User/]
});

1;

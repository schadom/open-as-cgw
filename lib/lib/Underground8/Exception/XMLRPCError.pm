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


package Underground8::Exception::XMLRPCError;
use base Underground8::Exception;
use overload ('""' => 'stringify');

sub new
{
    my $self = shift;
    my $text = "Something didn't work while sending the XML to the Server";
    my @args = @_;

    # Possible Error Codes
    # 400 => 'clim_malformed_xml', 'Malformed request.',
    # 403 => 'clim_auth_failed', 'Authentication failed.',
    # 404 => 'clim_serial_not_found', 'Serial Number not known.',
    # 405 => 'clim_product_missmatch', 'Licence Key is not for this Product.',
    # 409 => 'clim_voucer_taken', 'Licence Key already in use.',
    # 410 => 'clim_voucher_not_found', 'Licence Key is unknown to the Licence Server.',
    # 417 => 'clim_voucher_update_error', 'CLIM failed to update the Licence Key Information, conntact Support.',
    # 500 => 'clim_unknown_error', 'Unknown Error.',
    # 999 => 'clim_unreachable', 'Licensemanagement unreachable.',


    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;  # Enables storing of stacktrace

    $self->SUPER::new($text, @args);
}

1;

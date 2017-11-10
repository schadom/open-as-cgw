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


package Underground8::Service::SMTPCrypt;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::SMTPCrypt::SLAVE;
use XML::Dumper;


# Constructor
sub new ($)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::SMTPCrypt::SLAVE();

	$self->{'_enabled'} = undef;
	$self->{'_cryptotag'} = undef;
	$self->{'_packtype'} = undef;
	$self->{'_presetpw'} = undef;
	$self->{'_pwhandling'} = undef;

	$self->{'_config'} = undef;
    return $self;
}

sub load_config($){
	my $self = instance(shift);
	my $config_file = $g->{'file_smtpcrypt_conf'};
	my $config = {};

	my $dump = new XML::Dumper;

	# If smtpcrypt.xml doesn't exist, write it (shouldn happen anyway!)
	if(! -e "$config_file") {
		$self->slave->write_default_config();
	}

	$config = $dump->xml2pl( $config_file );
	$self->{'_config'} = $config;
	return $config;
}

sub save_config($) {

}

#### Accessors ####
sub get_cryptotag($) {
	my $self = instance(shift);
	return $self->{'_config'}->{'global'}->{'default_tag'};
}

sub set_cryptotag($$){
	my $self = instance(shift);
	$self->{'_config'}->{'global'}->{'default_tag'} = shift;
}

sub get_packtype($){
	my $self = instance(shift);
	return $self->{'_config'}->{'global'}->{'default_pack_type'};
}

sub set_packtype($$){
	my $self = instance(shift);
	$self->{'_config'}->{'global'}->{'default_pack_type'} = shift;
}

sub get_pwhandling($){
	my $self = instance(shift);
	return $self->{'_config'}->{'global'}->{'default_enc_type'};
}

sub set_pwhandling($$){
	my $self = instance(shift);
	$self->{'_config'}->{'global'}->{'default_enc_type'} = shift;
}

sub get_presetpw($){
	my $self = instance(shift);
	return $self->{'_config'}->{'global'}->{'default_password'};
}

sub set_presetpw($$){
	my $self = instance(shift);
	$self->{'_config'}->{'global'}->{'default_password'} = shift;
}

sub get_enabled($){
	my $self = instance(shift);
	return $self->{'_config'}->{'global'}->{'enabled'};
}

sub set_enabled($$){
	my $self = instance(shift);
	$self->{'_config'}->{'global'}->{'enabled'} = shift;
}


#### Misc methods ####
sub commit ($)
{
    my $self = instance(shift);
    $self->slave->write_config( $self->{'_config'} );
    $self->unchange;
}

1;

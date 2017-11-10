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


package Underground8::Service::SMTPCrypt::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Underground8::Exception::Execution;
use XML::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('smtpcrypt');
}

sub service_start ($)
{
    # nothing to do here 
}

sub service_stop ($)
{
    # nothing to do here
}


sub write_config ($$)
{
    my $self = instance(shift);
	my $config = shift;

	my $dump = new XML::Dumper;
	$dump->pl2xml( $config, $g->{'file_smtpcrypt_conf'} );
}

sub write_default_config($){
	my $self = instance(shift);
	
	my $dump = new XML::Dumper;
	my %default_config = ( 
		global => {
			default_tag => "CRYPT",
			default_enc_type => "generate_pw",  # generate | preset
			default_password => "",             # only makes sense if default_enc_type is preset
			default_pack_type => "zip",
			enabled => "0",
		},
		domain_sender_autocrypt => { },  
		domain_rcpt_autocrypt => { },  
		mailaddr_sender_autocrypt => { }, 
		mailaddr_rcpt_autocrypt => { },  
	);

	# Dump default XML & re-read
	$dump->pl2xml( \%default_config, $g->{'file_smtpcrypt_conf'} );
	return 1;
}

1;

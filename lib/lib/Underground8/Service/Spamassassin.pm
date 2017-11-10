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


package Underground8::Service::Spamassassin;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Spamassassin::SLAVE;

#Constructor
sub new ($$) {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{'_slave'} = new Underground8::Service::Spamassassin::SLAVE();
	$self->{'gtube'}->{'spam_test_string'} = 'XJS*C4JDBQADN1.NSBN3*2IINEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X';
	$self->{'gtube'}->{'spam_test_score'} = 1000 ;

	$self->{'languages'}->{'status'} = "disabled" ;
	$self->{'languages'}->{'allowed'} = "en de" ;

	return $self;
}

sub set_gtube($$) {
	my $self = shift;
	if(@_) {
		$self->{'gtube'}->{'spam_test_string'}=shift ;
		$self->change();
	}
}

sub get_gtube($) {
	my $self = shift;
	return $self->{'gtube'}->{'spam_test_string'};
}

sub set_gtube_score($$) {
	my $self = shift;
	if(@_) {   
		$self->{'gtube'}->{'spam_test_score'}=shift ;
		$self->change();
	}
}

sub get_gtube_score($) {
	my $self = shift;
	return $self->{'gtube'}->{'spam_test_score'};
}

sub enable_language_filter($){
	my $self = shift;
	$self->{'languages'}->{'status'} = "enabled";
	$self->change();
}

sub disable_language_filter($){
	my $self = shift;
	$self->{'languages'}->{'status'} = "disabled";
	$self->change();
}

sub get_language_filter_status($){
	my $self = shift;
	return $self->{'languages'}->{'status'};
}

sub set_allowed_languages($$) {
	my $self = shift;
	if(@_){
		$self->{'languages'}->{'allowed'} = shift;
		$self->change();
	}
}

sub get_allowed_languages($){
	my $self = shift;
	return $self->{'languages'}->{'allowed'};
}

sub commit($) {
	my $self = shift;
	if($self->is_changed()){
		$self->slave->write_config(
			$self->{'gtube'}->{'spam_test_string'},
			$self->{'gtube'}->{'spam_test_score'},
			$self->{'languages'}->{'allowed'},
			$self->{'languages'}->{'status'},
		);
	}
}

1;

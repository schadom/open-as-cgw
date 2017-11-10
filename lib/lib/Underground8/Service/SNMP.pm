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


package Underground8::Service::SNMP;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::SNMP::SLAVE;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;

use Data::Dumper;

# Constructor
sub new($) {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{'_slave'} = new Underground8::Service::SNMP::SLAVE();
	$self->{'_enabled'} = 0;
	$self->{'_location'} = undef;
	$self->{'_contact'} = undef;
	$self->{'_network'} = undef;
	$self->{'_community'} = undef;

	return $self;
}

### Accessors ###
sub enabled ($) {
	my $self = instance(shift);

	if (@_) {
		my $param = shift;
		if ($param == 1) {
			$self->change if ($self->{'_enabled'} != $param);
			$self->{'_enabled'} = 1;
		} else {
			$self->change if ($self->{'_enabled'} != $param);
			$self->{'_enabled'} = 0;
		}
	}

	return $self->{'_enabled'};
}


sub network ($) {
	my $self = instance(shift);
	my $param = shift;
	
	if ($param) {
		if ($self->{'_network'}) {
			$self->change if ($self->{'_network'} ne $param);
		} else {
			$self->change;
		}

		$self->{'_network'} = $param;
	}

	return $self->{'_network'};
}


sub community ($) {
	my $self = instance(shift);
	my $param = shift;
	
	if ($param) {
		if ($self->{'_community'}) {
			$self->change if ($self->{'_community'} ne $param);
		} else {
			$self->change;
		}

		$self->{'_community'} = $param;
	}

	return $self->{'_community'};
}


sub contact ($) {
	my $self = instance(shift);
	my $param = shift;
	
	if ($param) {
		if ($self->{'_contact'}) {
			$self->change if ($self->{'_contact'} ne $param);
		} else {
			$self->change;
		}

		$self->{'_contact'} = $param;
	}

	return $self->{'_contact'};
}


sub location ($) {
	my $self = instance(shift);
	my $param = shift;
	
	if ($param) {
		if ($self->{'_location'}) {
			$self->change if ($self->{'_location'} ne $param);
		} else {
			$self->change;
		}

		$self->{'_location'} = $param;
	}

	return $self->{'_location'};
}


sub remove_slave ($) {
	my $self = instance(shift);
	delete $self->{'_slave'};
}



sub commit ($) {
	my $self = instance(shift);

	my $files;
	push @{$files}, $g->{'file_snmpd_conf'};

	my $md5_first = $self->create_md5_sums($files);

	$self->slave->write_config($self->enabled, $self->network, $self->community, $self->location, $self->contact);

	my $md5_second = $self->create_md5_sums($files);

	if ($self->compare_md5_hashes($md5_first, $md5_second)) {
		$self->slave->service_restart();
	}
	$self->unchange;
}

1;

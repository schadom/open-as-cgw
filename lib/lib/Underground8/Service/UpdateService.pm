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


package Underground8::Service::UpdateService;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::UpdateService::SLAVE;
use Underground8::Exception::FalseRange;
use Underground8::Exception::TooBigRange;

use Data::Dumper;

# Constructor
sub new($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::UpdateService::SLAVE();
    $self->{'_parameters'} = { "auto_newest" => "0", "upgrade" => "1", "download" => "1", "update" => "1"};
    $self->{'_usus_cmd_line'} = "";
    return $self;
}



### Accessors ###

sub parameters
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_parameters'} = shift;
        $self->change;
    }
    return $self->{'_parameters'};
}

sub remove_slave ($)
{
    my $self = instance(shift);
    delete $self->{'_slave'};
}

sub commit($)
{
    my $self = instance(shift);
    $self->slave->write_config($self->{'_parameters'});
    $self->unchange;
}

sub initiate_usus($)
{
    my $self = instance(shift);
    my $action = shift;
    my $version = shift;
    my $options;
    
    if ( $action eq "update" )
    {
        $options = "--update --no-download --no-upgrade --no-auto-newest";
    } elsif ( $action eq "upgrade" ) {
        $options = "--upgrade --no-download --no-auto-newest";
    } elsif ( $action eq "install_new" ) {
        # License enforcement
        if ($self->report->license->meta_lic_featureupdate())
        {
            $options = "--upgrade --version=$version";
        } else {
            # if we have no up2date license, fall back to normal "update"
            $options = "--update --no-download --no-upgrade --no-auto-newest";
        }
    } else {
        $options = "";
    }

    print STDERR "\n\n\nInitiate usus as been called.\naction: $action\nversion: $version\nso options are: $options\n\n";

    $self->slave->initiate_usus($options);
}

1;

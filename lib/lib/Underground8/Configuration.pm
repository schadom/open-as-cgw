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


package Underground8::Configuration;

use strict;
use warnings;

use Underground8::Utils;
use XML::Simple;
use Error qw(:try);

# Constructor
sub new ($$$)
{
    my $class = shift;
    my $name = shift;
    my $appliance = shift;

    warn "No name defined!" if not defined $name;
    unless ($appliance)
    {
        warn "No appliance defined!" if not defined $appliance;
    }
    else
    {
        warn "Appliance is not a Underground8::Appliance object!" if not $appliance->isa('Underground8::Appliance');
    }

    my $self;
    $self = {
            _name => $name,
            _appliance => $appliance,
            _config_filename => '',
    };

    bless $self, $class;
    return $self;
}

sub name ($)
{
    my $self = instance(shift);
    return $self->{'_name'};
}

sub appliance ($)
{
    my $self = instance(shift);
    return $self->{'_appliance'};
}

sub config_filename ($)
{
    my $self = instance(shift);
    my $path = shift;
    my $file = $self->name() . ".xml";
    # If we got a path to read our xml from, set it
    if (defined $path && length $path && -d $path)
    {
        $self->{'_config_filename'} = $path . "/" . $file;
    }
    # if we didn't get a path, and config filename isn't defined, use the default path to it
    elsif (defined $self->{'_config_filename'} && $self->{'_config_filename'} eq '')
    {
        $self->{'_config_filename'} = $g->{'cfg_dir'} . "/" . $file;
    }
    # anyways return the variable
    return $self->{'_config_filename'};
}

sub prepare($$)
{
    my $self = instance(shift);
    my $xml_file = $self->xml_config_file;
    my $xml = '';
    
    $xml_file =~ /^.*\/([a-z]*.xml$)/;
    $xml = $1;

    try {
        $self->{'_temp_dir'} = mk_tmp_dir($g->{'xml_temp_dir_name'},$g->{'xml_temp_dir'});
        safe_system("$g->{'cmd_cp'} $xml_file $self->{'_temp_dir'}/$xml");
    }
    catch Underground8::Exception with
    {   
        my $E = shift;
        throw Underground8::Exception::XMLCopy($xml_file,$E);
    };
    
    return 1;
}

sub del_temp_dir($)
{
    my $self = instance(shift);
    
    if ($self->{'_temp_dir'} =~ qr/\/tmp/)
    {
        safe_system("$g->{'cmd_rm'} -rf $self->{'_temp_dir'}");
        delete($self->{'_temp_dir'});
    }
    else
    {
        warn "temp dir is not set!";
    }
    
}

sub xml_restore($)
{
    my $self = instance(shift);

    safe_system("$g->{'cmd_mv'} $self->{'_temp_dir'}/* $g->{'cfg_dir'}");
}             


sub save_config;

sub load_config;


1;

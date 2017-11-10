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


package Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::ReportFactory::LimesAS;
use Underground8::Exception::FileOpen;
use Digest::MD5;

# Constructor
sub new ($$$)
{
    my $class = shift;

    my $self;
    $self = {
            _has_changes => 0,
            _slave => undef,
            _report => new Underground8::ReportFactory::LimesAS,
    };

    bless $self, $class;
    return $self;
}

sub is_changed
{
    my $self = instance(shift);
    return $self->{'_has_changes'};
}

sub change
{
    my $self = instance(shift);
    $self->{'_has_changes'} = 1;
}

sub unchange
{
    my $self = instance(shift);
    $self->{'_has_changes'} = 0;
}

sub report
{
    my $self = instance(shift);
    return $self->{'_report'};
}

sub slave
{
    my $self = instance(shift);
    return $self->{'_slave'};
}

sub import_params ($$)
{
    my $self = instance(shift);
    my $import = shift;
    if (ref($import) eq 'HASH')
    {
        foreach my $key (keys %$import)
        {
            $self->{$key} = $import->{$key};
        }
        $self->change;
    }
    else
    {
        warn 'No hash supplied!';
    }
}

sub export_params ($)
{
    my $self = instance(shift);
    my $export = undef;
    foreach my $key (keys %$self)
    {
        $export->{$key} = $self->{$key};
    }
    delete $export->{'_slave'};
    delete $export->{'_has_changes'};
    delete $export->{'_report'};
    return $export;
}

sub create_md5_sums ($@)
{
    my $self = instance(shift);
    my $filelist = shift;
    
    my $hashes = {};

    foreach my $file (@{$filelist})
    {
        open(FILE, $file) or throw Underground8::Exception::FileOpen($file);
        my $ctx = Digest::MD5->new;
        $ctx->addfile(*FILE);
        $hashes->{$file} = $ctx->hexdigest;
        close(FILE);
        #print STDERR "\nCreated hash for $file : $hashes->{$file}";
    }
    
    return $hashes;
}


sub compare_md5_hashes ($%)
{
    my $self = instance(shift);
    my $first = shift;
    my $second = shift;

    my $changed = 0;
    
    if ((defined $first) && (defined $second))
    {
        foreach my $file (keys %{$first})
        {
            #print STDERR "\nLooking at file $file";
            if ($first->{$file} ne $second->{$file})
            {
                $changed = 1;
                #print STDERR " --- HAS BEEN CHANGED!\n";
            }
        }
    }
    
    return $changed;

}
1;

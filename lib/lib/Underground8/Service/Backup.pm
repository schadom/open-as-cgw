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


package Underground8::Service::Backup;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::Backup::SLAVE;
#Constructor
sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->create_slave();
    $self->{'_backups'} = [];
    $self->{'_index'} = {};
    $self->{'_backup_file'} = undef;
    $self->{'_backup_status'} = 0;
    return $self;
}

#### Accessors ####
# returns the index hash of our backupfiles
# hashstructure:
# filename_without_ending => backups_arrayposition
sub index ($)
{
    my $self = instance(shift);
    return $self->{'_index'};
}

sub delete_from_index($$)
{
    my $self = instance(shift);
    my $file = shift;
    if (defined $self->index->{$file})
    {
        foreach (keys %{$self->index})
        {
            if ($self->index->{$_} > $self->index->{$file})
            {
                $self->index->{$_}--;
            }
        }
    }
    delete $self->index->{$file};
}

# takes the backup filename without ending
# reads the network interface array of hashes out of
# our backup.xml settings
sub get_net_interfaces ($$)
{
    my $self = instance(shift);
    my $name = shift;
    if (defined $name && defined $self->index->{$name})
    {
        return $self->backups->[$self->index->{$name}]->{'_net_interface'};
    }
    return undef;
}

# takes a hash of information about our backup
# and add's it to the backups array and 
# puts the array index number into our 
# index hash
# removes the backup information about the same
# backupname if it's existing in the config
# so be sure to deliver everything necessary from above
# datastructure:
# {
#    '_name' => "Backup2008.02.22_22-39-19"
#    '_net_interface' => [   {   
#           '_name' => 'eth0',
#            '_ip_address' => '192.168.0.100',
#            '_subnet_mask' => '255.255.255.0',
#            '_default_gateway' => '192.168.0.1',
#        }, 
#        {   
#            '_name' => 'eth1',
#            '_ip_address' => '10.1.200.200',
#            '_subnet_mask' => '255.255.255.0',
#            '_default_gateway' => '10.1.200.1',
#        }, 
#       ],
#   '....' => '.....',
# }
sub add_backup_to_config ($$)
{
    my $self = instance(shift);
    my $info = shift;
    if (defined $info && ref $info eq 'HASH' && defined $info->{'_name'})
    {
        my $realname = $info->{'_name'};
        $realname =~ s/^(.*)(\.crypt|\.tar\.gz|\.tar)/$1/;

        # if we got a backup info, remove it if present
        if (defined $self->index->{$realname})
        {
            splice(@{$self->backups}, $self->index->{$realname}, 1);
            $self->delete_from_index($realname);
        }
        push @{$self->backups}, $info;
        $self->index->{$realname} = $#{$self->backups};
        $self->change();
        return 1;
    }
    return 0;
}

# returns the array of backups stored in the backup.xml(Objectvariable)
sub backups ($)
{
    my $self = instance(shift);
    return $self->{'_backups'};
}

# get the index of our real file arrays
# (encrypted and unencrypted backups)
# takes a backup name and returns the index
sub get_list_index ($$)
{
    my $self = instance(shift);
    return $self->slave->get_list_index(shift);
}
# handle the untar to tempdir down to the slave
sub untar_to_tempdir($)
{
    my $self = instance(shift);
    return $self->slave->untar_to_tempdir();
}
# get the filename of a backup if we have an 
# array index
sub get_encrypted_by_index ($$)
{
    my $self = instance(shift);
    return $self->slave->get_encrypted_by_index(shift);
}
# get the filename of a backup if we have an 
# array index
sub get_unencrypted_by_index ($$)
{
    my $self = instance(shift);
    return $self->slave->get_unencrypted_by_index(shift);
}
# return the array of filenames of encrypted backups
sub list_encrypted ($)
{
    my $self = instance(shift);
    return $self->slave->list_encrypted();
}
# return the array of filenames of uncrypted backups
sub list_unencrypted ($)
{
    my $self = instance(shift);
    return $self->slave->list_unencrypted();
}
# read the list of encrypted backup files from the filesystem
sub read_list_encrypted ($)
{
    my $self = instance(shift);
    return $self->slave->read_list_encrypted();
}
# read the list of uncrypted backup files from the filesystem
sub read_list_unencrypted ($)
{
    my $self = instance(shift);
    return $self->slave->read_list_unencrypted();
}
# remove an encrypted backup
# and make sure that there's nothing left in the configfiles
sub remove_encrypted_backup ($$)
{
    my $self = instance(shift);
    my $index = shift;
    my $filename = $self->slave->get_encrypted_by_index($index);
    if ($filename =~ /^(.*)\.crypt/ && defined $self->index->{$1})
    {
        splice(@{$self->backups}, $self->index->{$1}, 1);
        $self->delete_from_index($1);
        $self->change();
    }
    $self->slave->remove_encrypted_backup($index);
}
# remove an unencrypted backup
# and make sure that there's nothing left in the configfiles
sub remove_unencrypted_backup ($$)
{
    my $self = instance(shift);
    my $index = shift;
    my $filename = $self->slave->get_unencrypted_by_index($index);
    if ($filename =~ /^(.*)\.tar\.gz/ && defined $self->index->{$1})
    {
        splice(@{$self->backups}, $self->index->{$1}, 1);
        $self->delete_from_index($1);
        $self->change();
    }
    $self->slave->remove_unencrypted_backup($index);
}
# tell slave to remove a tempdir
sub remove_tempdir ($)
{
    my $self = instance(shift);
    $self->slave->remove_tempdir();
}
# tell slave to create a tempdir
sub create_tempdir ($)
{
    my $self = instance(shift);
    return $self->slave->create_tempdir();
}
# compare mp5 checksums
# takes a checksum and a name of a backup
# and compares it to the next eldest backup
# is only needed for the underground8 backups
# so list unencrypted is used that normaly should
# hold only the last unencrypted backup & the currently created one
# sorts them by date (in the name)
sub compare_backups ($$$)
{
    my $self = instance(shift);
    my $md5_checksum = shift;
    my $backupfile = shift;
    my @backups = grep { s/^(.*)\.tar\.gz$/$1/ } sort {$a cmp $b} @{$self->list_unencrypted};
    # if we have only one backup
    # return 0 -> comparison failed -> time to upload
    if (2 > scalar @backups)
    {
        return 0;
    }
    # if the new checksum isn't equal to the previous one ($backups[-1] ne $backups[-2])
    # return 0 -> comparison failed -> time to upload
    elsif (defined $self->index->{$backups[-2]})
    {
         if ($self->backups->[$self->index->{$backups[-2]}]->{'_md5_checksum_tar'} ne $md5_checksum)
         {
             return 0;
         }
         else
         {
            return 1;
         }
    }
    else
    {
        return 0;
    }    
}
# creates a tar of a config file
# takes the network settings 
# of the current config
# in order to store them in the backup.xml
# for easier installing lateron
sub xml_to_tar ($)
{
    my $self = instance(shift);
    # Takes Net Interface Structure of type:
    # Array of Hashes
    # Every Hash represents one network interface
    # example:
    #[   {   
    #        '_name' => 'eth0',
    #        '_ip_address' => '192.168.0.100',
    #        '_subnet_mask' => '255.255.255.0',
    #        '_default_gateway' => '192.168.0.1',
    #    }, 
    #    {   
    #        '_name' => 'eth1',
    #        '_ip_address' => '10.1.200.200',
    #        '_subnet_mask' => '255.255.255.0',
    #        '_default_gateway' => '10.1.200.1',
    #    }, 
    #]
    my $net_interfaces = shift;
    my $md5_checksum = $self->slave->xml_to_tar();
    $self->{'_backup_file'} = $self->slave->backup_filename();
    if (defined $md5_checksum && length $md5_checksum)
    {
        my $filename = $self->backup_file;
        $filename =~ s/^(.*)(\.crypt|\.tar\.gz|\.tar)/$1/;
        # Add the newly created backup to our backups array
        push @{$self->backups}, {'_md5_checksum_tar' => $md5_checksum,
                                 '_name' => $filename,
                                 '_type' => 'tar',
                                 '_net_interface' => (ref $net_interfaces eq 'ARRAY')?$net_interfaces:[$net_interfaces]};
        # Add the Array Number to the backup index hash
        $self->index->{$filename} = $#{$self->backups};
        
        # And now set change active that our conf gets saved to the xml on next commit
        $self->change();
        return $md5_checksum;
    }
}
# tell slave to install a backup (from tar to the real position)
sub tar_to_xml ($)
{
    my $self = instance(shift);
    $self->slave->tar_to_xml();
    $self->{'_backup_status'} = 0;
    
}

# zip a tarred backup and change it's type in the backup.xml
sub tar_to_gzip ($)
{
    my $self = instance(shift);
    $self->{'_backup_file'} = $self->slave->tar_to_gzip();
    if ($self->{'_backup_file'} =~ /(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)\.tar\.gz$/)
    {
        if (defined $self->index->{$1})
        {
            $self->backups->[$self->index->{$1}]->{'_type'} = 'tar.gz';
        }
        $self->{'_backup_status'} = 1;
    }
    $self->change();
}

# way back: extract a gzip to tar
# make sure the $self->backup_file object variable
# holds the name of the to extract backup
sub gzip_to_tar ($)
{
    my $self = instance(shift);
    if ($self->backup_file() =~ /Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.tar\.gz$/)
    {
        $self->slave->gzip_to_tar($self->backup_file());
        $self->{'_backup_status'} = 1;
    }
}

# crypt a gzip backupfile
# and change it's type in backup.xml
sub gzip_to_crypt ($)
{
    my $self = instance(shift);
    $self->{'_backup_status'} = 0;
    $self->{'_backup_file'} = $self->slave->gzip_to_crypt($self->backup_file());
    if ($self->{'_backup_file'} =~ /(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)\.crypt$/)
    {
        if (defined $self->index->{$1})
        {        
            $self->backups->[$self->index->{$1}]->{'_type'} = 'crypt';
        }       
        $self->{'_backup_status'} = 2;
    }
    
}

# way back: from crypt to gzip, change the typ to tar.gz
# make sure the $self->backup_file object variable
# holds the name of the to decrypt backup
sub crypt_to_gzip ($)
{
    my $self = instance(shift);
    $self->{'_backup_status'} = 0;
    $self->{'_backup_file'} = $self->slave->crypt_to_gzip($self->backup_file());
    if ($self->{'_backup_file'} =~ /(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)\.tar\.gz$/)
    {
        if (defined $self->index->{$1})
        {
            $self->backups->[$self->index->{$1}]->{'_type'} = 'tar.gz';
        }
        $self->{'_backup_status'} = 2;
    }
}

# was intendet to get information where we are at the moment
# 0 for xml_to_tar finished
# 1 for tar_to_gzip finished
# 2 for tar_to_gzip finished
# 2 for crypt_to_gzip finished
# 1 for gzip_to_tar finished
# 0 for tar_to_xml finished
# maybe outdated
sub backup_status ($)
{
    my $self = instance(shift);
    return $self->{'_backup_status'};
}

# return the backup filename we're actually working on 
# (including ending)
sub backup_file ($)
{
    my $self = instance(shift);
    return $self->{'_backup_file'};
}
# setter for the backup file we're working on
sub set_backup_file ($$)
{
    my $self = instance(shift);
    $self->{'_backup_file'} = shift;
}
# create a new slave
sub create_slave ($)
{
    my $self = instance(shift);
    $self->{'_slave'} = new Underground8::Service::Backup::SLAVE();
}

sub slave ($)
{
    my $self = instance(shift);
    return $self->{'_slave'};
}
sub initialize_upload ($$)
{
    my $self = instance(shift);
    return $self->slave->initialize_upload(shift);
}
# tell slave it should prepare for file download
sub initialize_download ($$)
{
    my $self = instance(shift);
    return $self->slave->initialize_download(shift);
}
# we're uploading a backup file here
# transmit a buffer to the slave who
# writes it out to the open filehandle
sub write_file ($$$)
{
    my $self = instance(shift);
    return $self->slave->write_file(shift, shift);
}
# we're downloading a backup file here
# take in the next buffer from the 
# slave's filehandle and pass it up
sub read_file ($$$)
{
    my $self = instance(shift);
    return $self->slave->read_file(shift, shift);
}
# check if a file exists
sub check_file($$)
{
    my $self = instance(shift);
    return $self->slave->check_file(shift);
}
# create a unique backup name
# slave has to check if there are files with a desired name
# already existing
sub create_backup_name($$)
{
    my $self = instance(shift);
    return $self->slave->create_backup_name(shift);
}
# read in from the xml
sub import_params ($$)
{
    my $self = instance(shift);
    my $import = shift;
    my $key;
    if (ref($import) eq 'HASH')
    {
#        if (defined $import->{'_md5_checksum_tar'} && ref $import->{"_md5_checksum_tar"} eq 'HASH')
#        {
#            $import->{'_backups'} = [];
#            foreach $key (keys %{$import->{'_md5_checksum_tar'}})
#            {
#                push @{$import->{'_backups'}}, {'_name' => $key, 
#                                                '_md5_checksum_tar' => $import->{'_md5_checksum_tar'}->{$key}};
#                $import->{'_index'}->{$key} = $#{$import->{'_backups'}};
#            }
#        }
        foreach $key (keys %$import)
        {
            $self->{$key} = $import->{$key};
        }
    }
    else
    {
        warn 'No hash supplied!';
    }
}
# write out to the backup.xml file
sub export_params ($)
{
    my $self = instance(shift);
    my $export = undef;
    foreach my $key (keys %$self)
    {
        if (length $key)
        {
            $export->{$key} = $self->{$key};
        }
    }
    delete $export->{'_slave'};
    delete $export->{'_has_changes'};
    delete $export->{'_backup_file'};
    delete $export->{'_backup_status'};
    return $export;
}
sub commit ($)
{
    my $self = instance(shift);
    $self->unchange;
}

1;

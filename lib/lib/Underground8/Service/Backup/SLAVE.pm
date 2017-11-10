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


package Underground8::Service::Backup::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Error qw(:try);
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Exception::Remove;
use Underground8::Exception::CreateTmpDir;
use Underground8::Exception::CreateArchive;
use Underground8::Exception::FileExtract;;
use Crypt::CBC;
use File::Temp qw/ tempdir /;
use Digest::MD5;

# Create a new Backup Slave
# populate our lists with the existing files
sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('backup');
    $self->read_list_encrypted();
    $self->read_list_unencrypted();
    return $self;
}
# Object Variable _backup_filename
# holds the info with what file we're dealing
# at the moment
# changes on every state change
# from tar over gzip to crypt
# and back to tar
sub backup_filename
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_backup_filename'} = shift;
    }
    return $self->{'_backup_filename'};
}

# check if the file we're trying to upload to
# already exists
# or if it's already in use
# else open a filehandle
# and save the handle to the slave object
sub initialize_upload ($$)
{
    my $self = instance(shift);
    my $file = shift;
    # Return 0 if the file that we should save is already there
    if ($self->check_file($file))
    {
        throw Underground8::Exception::FileExists($file);
    }
    # Check if a file upload is already in progress
    # Return 2 if it's in progress, 
    # so that the caller can cancel the upload
    # if the upload hangs for example or a copy wasn't finished cleanly
    if (defined $self->{'_ul'} && 
        defined $self->{'_ul'}->{$file} && 
        defined $self->{'_ul'}->{$file}->{'_status'} &&
        $self->{'_ul'}->{$file}->{'_status'} == 1)
    {
        throw Underground8::Exception::FileInUse($file);
    }

    open $self->{'_ul'}->{$file}->{'_handle'}, ">$g->{'cfg_backup_dir'}/$file"
    or throw Underground8::Exception::FileOpen($file);
    $self->{'_ul'}->{$file}->{'_status'} = 1;
    return 1;
}

# check if we have the file that should
# be delivered
# check if the file is currently downloaded
# in order to avoid buffer whise file mixing
sub initialize_download ($$)
{
    my $self = instance(shift);
    my $file = shift;
    # Return 0 if the file that should be copied doesn't exists
    unless ($self->check_file($file))
    {
        throw Underground8::Exception::FileNotFound($file);
    };
    # Check if a file download is already in progress
    # Return 2 if it's in progress, 
    # so that the caller can cancel the download
    # if the download hangs for example or a copy wasn't finished cleanly
    if (defined $self->{'_dl'} && 
                defined $self->{'_dl'}->{$file} && 
                defined $self->{'_dl'}->{$file}->{'_status'} &&
                $self->{'_dl'}->{$file}->{'_status'} == 1)
    {
        throw Underground8::Exception::FileInUse($file);
    }

    open $self->{'_dl'}->{$file}->{'_handle'}, "<$g->{'cfg_backup_dir'}/$file"
    or throw Underground8::Exception::FileOpen($file);
    $self->{'_dl'}->{$file}->{'_status'} = 1;
    return 1;
}
# writes to a buffer
# checks if we have a filehandle open 
# as a slave object variable
# stop writing if we've reached 
# the end of the upload and return
# the end of writing
# else request the next buffer
sub write_file ($$$)
{
    # Required Values:
    # - Filename of Backupfile
    # - Content
    my $self = instance(shift);
    my $file = shift;
    my $content = shift;
    
    if (ref($self->{'_ul'}->{$file}->{'_handle'}) ne 'GLOB')
    {
        throw Underground8::Exception("File Handle not found");;
    }
    
    # Return 2: Got an emtpy content, End of File reached, buffer closed
    if (length $content == 0)
    {
        close $self->{'_ul'}->{$file}->{'_handle'};
        delete $self->{'_ul'}->{$file};
        $self->read_list_encrypted();
        $self->read_list_unencrypted();
        return 2;
    }
    else
    {
        print { $self->{'_ul'}->{$file}->{'_handle'}} $content;
        return 1;
    }
    return 0;
}

# check if we have a glob handle 
# saved in the object variable
# that we can read from
# if we reached the end of the file
# close the buffer, and delete 
# the filehandle
sub read_file ($$$)
{
    # Required Values:
    # - Filename of Backupfile
    # Optional:
    # - Buffer Size: Size of Buffer in Bytes
    my $self = instance(shift);
    my $file = shift;
    my $buffsize = shift;
    my $buff = '';
    $buffsize = 1024 unless (defined $buffsize && $buffsize =~ /^\d+$/);
    
    throw Underground8::Exception::FileOpen("Invalid Filehandle for $file")
    if (ref($self->{'_dl'}->{$file}->{'_handle'}) ne 'GLOB');
    
    read($self->{'_dl'}->{$file}->{'_handle'}, $buff, $buffsize);
    
    # if there wasn't anything to read
    # close the handle and destroy our _dl->$file object
    unless (length $buff)
    {
        close $self->{'_dl'}->{$file}->{'_handle'};
        delete $self->{'_dl'}->{$file};
        
    }
    return $buff;
}
# create a tempdir for the process of
# backup creation or deployment
sub create_tempdir
{
    my $self = instance(shift);
    $self->{'_tempdir'} = File::Temp::tempdir ( 'tempXXXXX', DIR => $g->{'cfg_backup_dir'})
    or throw Underground8::Exception::CreateTmpDir($g->{'cfg_backup_dir'});
    return $self->{'_tempdir'};
}
# remove tempdirs
sub remove_tempdir
{
    my $self = instance(shift);
    if (defined $self->{'_tempdir'} && -d $self->{'_tempdir'})
    {
        try {
            safe_system("$g->{'cmd_rm'} -Rf $self->{'_tempdir'}");
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception::Remove([$self->{'_tempdir'}]);
        };
    }
    $self->{'_tempdir'} = undef;
}

# remove an encrypted file according to its
# array number in the array of the encrypted files
sub remove_encrypted_backup ($$)
{
    my $self = instance(shift);
    my $index = shift;
    my $backupdir = $g->{'cfg_backup_dir'};
    unless (length $self->{'_list_encrypted'}[$index])
    {
         throw Underground8::Exception::Remove([$self->{'_list_encrypted'}[$index]])
    }
    if ( -e "$backupdir/$self->{'_list_encrypted'}[$index]")
    {
        try {
            safe_system("$g->{'cmd_rm'} -Rf $backupdir/$self->{'_list_encrypted'}[$index]");
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception::Remove([$self->{'_list_encrypted'}[$index]]);
        };
    }
    splice(@{$self->{'_list_encrypted'}}, $index, 1);
}

# remove an uncrypted file according to its
# array number in the array of the uncrypted files
sub remove_unencrypted_backup ($$)
{
    my $self = instance(shift);
    my $index = shift;
    my $backupdir = $g->{'cfg_backup_dir'};
    unless (length $self->list_unencrypted->[$index])
    {
         throw Underground8::Exception::Remove([$self->{'_list_unencrypted'}[$index]])
    }
    if (-e ("$backupdir/" . $self->list_unencrypted->[$index] ))
    {
        try {
            safe_system(("$g->{'cmd_rm'} -Rf $backupdir/" . $self->list_unencrypted->[$index]));
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception::Remove([$self->list_unencrypted->[$index]]);
        };
    }
    splice(@{$self->list_unencrypted}, $index, 1);
}
# getter for the list of encrypted files
sub list_encrypted ($)
{
    my $self = instance(shift);
    return $self->{'_list_encrypted'};
}
# getter for the list of uncrypted files
sub list_unencrypted ($)
{
    my $self = instance(shift);
    return $self->{'_list_unencrypted'};
}
# getter for the encrypted backup filenames 
# by it's list index
sub get_encrypted_by_index ($$)
{
    my $self = instance(shift),
    my $index = shift;
    return $self->list_encrypted->[$index] if (defined $self->list_encrypted->[$index] && length $self->list_encrypted->[$index]);
}

# getter for the unencrypted backup filenames 
# by it's list index
sub get_unencrypted_by_index ($$)
{
    my $self = instance(shift),
    my $index = shift;
    return $self->list_unencrypted->[$index] if (defined $self->list_unencrypted->[$index] && length $self->list_unencrypted->[$index]);
}

# getter for list indexes
# returns both, if a file was in encrypted
# or in unencrypted file array
sub get_list_index ($$)
{
    my $self = instance(shift);
    my $desired = shift;
    my ($i, $limit);
    $self->read_list_encrypted;
    for ($i = 0, $limit = scalar @{$self->{'_list_encrypted'}}; $i < $limit; $i++)
    {
        return $i if ($desired eq $self->{'_list_encrypted'}->[$i]);
    }
    $self->read_list_unencrypted;
    for ($i = 0, $limit = scalar @{$self->{'_list_unencrypted'}}; $i < $limit; $i++)
    {
        return $i if ($desired eq $self->{'_list_unencrypted'}->[$i]);
    }
    return undef;
}
# reread the list of encrypted backups
# from the filesystem
sub read_list_encrypted ($)
{
    my $self = instance(shift);
    my $backupdir = $g->{'cfg_backup_dir'};
    my @files = <$backupdir/*.crypt>;
    @{$self->{'_list_encrypted'}} = grep { s/^.*\/(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.crypt)$/$1/ } @files;
}
# reread the list of uncrypted backups
# from the filesystem
sub read_list_unencrypted ($)
{
    my $self = instance(shift);
    my $backupdir = $g->{'cfg_backup_dir'};
    my @files = <$backupdir/*.tar.gz>;
    @{$self->{'_list_unencrypted'}} = grep { s/^.*\/(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.tar\.gz$)/$1/ } @files;
}

# First stage of backup creation
# checks if our tempdir is empty
# otherwise removes everything in there
# creates a tar of our to backup files 
# which are used from the 
# global cfg_backup_include file
# calculates the md5 checksum of the tar file
sub xml_to_tar ($)
{
    my $self = instance(shift);
    my $tempdir = $self->{'_tempdir'};
    my @files = <$tempdir/*>;
	my $versionspath = $g->{'cfg_system_version_file'};
	# Strip the path from the versions file
	$versionspath =~ s/(.*\/).*$/$1/;
    my $backupfile = $self->create_backup_name( 0 );
    if (scalar @files > 1) {
        foreach (@files)
        {
            try {
                if (-e $_)
                {
                    safe_system("$g->{'cmd_rm'} -Rf $_");
                }
            }
            catch Underground8::Exception with
            {
                throw Underground8::Exception::Remove([$_]);
            };
        }
        @files = ();
    }
    try {
        safe_system("$g->{'cmd_tar'} -cPf $self->{'_tempdir'}/$backupfile -C $versionspath -T $g->{'cfg_backup_include'} -X $g->{'cfg_backup_exclude'}");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::CreateArchive($backupfile);
    };
    $self->backup_filename($backupfile);
    try {
        open FILE, ("<" . $self->{'_tempdir'} . "/" . $backupfile)
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileOpen($self->{'_tempdir'} . "/" . $backupfile);
    };
    my $digest = Digest::MD5->new;
    $digest->addfile(*FILE);
    close FILE;
    my $c_checksum = $digest->hexdigest;
    return $c_checksum;

}
# untars a tar'ed backup to the tempdir it's in
# (in order to read from xml's temporarily and 
# remove them with the tempdir remove)
sub untar_to_tempdir($)
{
    my $self = instance(shift);
	my $versions = $g->{'cfg_system_version_file'};
	# versionsfile gets tarred into the rootdir of the tarfile
	# -> remove all path info to access it
	$versions =~ s/.*\/(.*)$/$1/;
    try {
        safe_system("$g->{'cmd_tar'} -xf $self->{'_tempdir'}/" . $self->backup_filename . " --exclude $versions -C /$self->{'_tempdir'}/");
        return ($self->{'_tempdir'} . "/" . $g->{'cfg_dir'})
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileExtract($self->backup_filename);
    };
    
}

# extract a backup tar to /
# that way we can include and restore pretty much anything
# on the system
sub tar_to_xml
{
    my $self = instance(shift);
	my $versions = $g->{'cfg_system_version_file'};
	# versionsfile gets tarred into the rootdir of the tarfile
	# -> remove all path info to access it
	$versions =~ s/.*\/(.*)$/$1/;
	
    try {
        safe_system("$g->{'cmd_tar'} -xf $self->{'_tempdir'}/" . $self->backup_filename . " --exclude $versions -C /");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileExtract($self->backup_filename);
    };
}

# creates a backup name
# can take arguments for the desired file ending
# any number for tar
# 1 for crypt
# 2 for tar.gz
# checks if the file with that name already exists
# and increases the counter if it's already existing
# till it finds a free slot 
# and returns the filename
sub create_backup_name ($$)
{
    # if 2nd Parameter is "1" it will return a .crypt Filename
    # if it isn't present or anything else than 1 it will return a  .tar.gz Filename
    my $self = instance(shift);
    my $type = shift;
    if (defined $type && $type eq '1')
    {
        $type = "crypt";
    }
    elsif (defined $type && $type eq '2')
    {
        $type = "tar.gz";        
    }
    else
    {
        $type = "tar";
    }
    # Gets formatted localdate+time
    # YYYY.MM.DD_HH-MM-SS
    my $time = Underground8::Utils::get_localtime();
    my $counter = 1;
    # Filename: Backup-YYYY.MM.DD_HH-MM-SS.tar.gz
    # if it exists count up to a nonexisting one like that:
    # Filename: Backup1-YYYY.MM.DD_HH-MM-SS.tar.gz
    # Filename: Backup2-YYYY.MM.DD_HH-MM-SS.tar.gz
    # ...
    my $backupfile;
    if (-e "$g->{'cfg_backup_dir'}/Backup-$time.$type")
    {
        while (-e "$g->{'cfg_backup_dir'}/Backup-$time$counter.$type")
        {
            $counter++;
        }
        $backupfile = "Backup$counter-$time$counter.$type";
    } 
    else
    {
        $backupfile = "Backup-$time.$type";
    }
    return $backupfile;
}

# Second step in Backup creation
# we have a tar file and want a gzip file
# removes the tar file after zipping
# returns the new backup filename
sub tar_to_gzip ($)
{
    my $self = instance(shift);
    my $backupfile = $self->backup_filename;
    my $targzbackupfile = $backupfile;
    $targzbackupfile =~ s/^(.*)\.tar$/$1.tar.gz/;
    # Zip the tar into our backup directory
    # -c prints the output we redirect to another directory
    try {
        safe_system("$g->{'cmd_gzip'} $self->{'_tempdir'}/$backupfile -c " .
        "> $g->{'cfg_backup_dir'}/$targzbackupfile");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::CreateArchive(("$g->{'cfg_backup_dir'}/$targzbackupfile"));
    };

    $self->backup_filename($targzbackupfile);

    try {
        if (-e "$self->{'_tempdir'}/$backupfile")
        {
            safe_system("$g->{'cmd_rm'} -Rf $self->{'_tempdir'}/$backupfile");
        }
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::Remove("$self->{'_tempdir'}/$backupfile");
    };
    return $targzbackupfile;
}
# Second Step on the way back from crypt to the uncompressed files
# takes a gzip backup file and unzips it
# makes sure that there are no files in the tempdir
# and deletes them if there should be any left there
# removes the gzip file after untarring
sub gzip_to_tar ($$)
{
    my $self = instance(shift);
    my $backupfile = shift;
    my $unzippedbackupfile = $backupfile;
    $unzippedbackupfile =~ s/(.*)\.tar\.gz/$1.tar/;
    my $tempdir = $self->{'_tempdir'};
    my @files = <$tempdir/*>;
    # Make sure only our backupfile is in here
    if (scalar @files > 2)
    {
        foreach (@files)
        {
            try {
                if (-e $_)
                {
                    safe_system("g->{'cmd_rm'} -Rf $_");
                }
            }
            catch Underground8::Exception with
            {
                throw Underground8::Exception::Remove(@files);
            };
        }        
    }

    try {
        safe_system("$g->{'cmd_gunzip'} $g->{'cfg_backup_dir'}/$backupfile -c > $tempdir/$unzippedbackupfile");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::Exctract("$g->{'cfg_backup_dir'}/$backupfile");
    };

    try 
    {
        if (-e "$g->{'cfg_backup_dir'}/$backupfile")
        {
            safe_system("$g->{'cmd_rm'} -Rf $g->{'cfg_backup_dir'}/$backupfile");
        }
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::Remove("$g->{'cfg_backup_dir'}/$backupfile");
    };
    $self->backup_filename($unzippedbackupfile);
}

# Third step on the way from config to crypt
# takes a gzip file and crypts it
# removes the gzip file as soon as we have a crypt one
# returns the Backupfilename + .crypt ending
sub gzip_to_crypt ($$)
{
    use Crypt::CBC;
    my $self = instance(shift);
    my $oldbackupfile = shift;
    my $backupfile = $oldbackupfile;
    $backupfile =~ s/(.*)\.tar\.gz$/$1.crypt/;
    my $buffer = '';
    my $cipher = Crypt::CBC->new( -key  => "$g->{'cfg_crypt_key'}",
                    -cipher => 'Blowfish',
                    -salt => 1
    );
    try {
        open (INPUT, "<$g->{'cfg_backup_dir'}/$oldbackupfile");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileOpen("$g->{'cfg_backup_dir'}/$oldbackupfile");
    };
    
    try {
        open (OUTPUT, ">$g->{'cfg_backup_dir'}/$backupfile");
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileOpen("$g->{'cfg_backup_dir'}/$backupfile");
    };

    $cipher->start('encrypt');
    while (read(INPUT,$buffer,1024))
    {
        print OUTPUT $cipher->crypt($buffer);
    }
    print OUTPUT $cipher->finish;
    close OUTPUT;
    close INPUT;
    try {
        unlink "$g->{'cfg_backup_dir'}/$oldbackupfile";
    }
    catch Underground8::Exception with
    {
        throw Underground8::Exception::FileRemove("$g->{'cfg_backup_dir'}/$oldbackupfile");
    };
    return "$backupfile";
}

# First step on the way back from .crypt to the installed
# backupfiles
# takes a .crypt and tries to decrypt it
# throws meaningful errors if decryption failed
# does NOT remove the .crypt backup after decryption
sub crypt_to_gzip ($$)
{
    use Crypt::CBC;
    my $self = instance(shift);
    my $oldbackupfile = shift;
    my $i = 0;
    if ($oldbackupfile =~ /^(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)\.crypt$/)
    {
        my $backupfile = "$1.tar.gz";
        my $buffer = '';
        my $cipher = Crypt::CBC->new( 
                        -key  => "$g->{'cfg_crypt_key'}",
                        -cipher => 'Blowfish',
                        -salt => 1
        );
        try {
            open (INPUT, "<$g->{'cfg_backup_dir'}/$oldbackupfile");
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception::FileOpen("$g->{'cfg_backup_dir'}/$oldbackupfile");
        };


        try {
            open (OUTPUT, ">$g->{'cfg_backup_dir'}/$backupfile");
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception::FileOpen("$g->{'cfg_backup_dir'}/$backupfile");
        };

        try {
            $cipher->start('decrypt');
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception("Could not decrypt $g->{'cfg_backup_dir'}/$oldbackupfile");
        };
        while (read(INPUT,$buffer,1024))
        {
            if ($i == 0)
            {
                unless ($buffer =~ /^Salted/)
                {
                    last;
                }
            }
            $i++;
            print OUTPUT $cipher->crypt($buffer) or throw Underground8::Exception("Could not decrypt $g->{'cfg_backup_dir'}/$oldbackupfile");
        }
        if ($i == 0)
        {
            throw Underground8::Exception("Could not decrypt $g->{'cfg_backup_dir'}/$oldbackupfile");
        }
        try {
            print OUTPUT $cipher->finish;
        }
        catch Underground8::Exception with
        {
            throw Underground8::Exception("Could not decrypt $g->{'cfg_backup_dir'}/$oldbackupfile");
        };
        close OUTPUT;
        close INPUT;
    
        return $backupfile;
    }
    elsif ($oldbackupfile =~ /^Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.tar\.gz$/)
    {
        return $oldbackupfile;
    }
}

# Check if a File is already existing as tar.gz or crypt
sub check_file
{
    my $self = instance(shift);
    my $file = shift;
    if (($file =~ /^Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.tar\.gz$/ ||
        $file =~ /^Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*\.crypt$/) &&
        -e "$g->{'cfg_backup_dir'}/$file")
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

1;

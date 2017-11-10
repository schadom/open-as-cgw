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


package Underground8::Configuration::LimesAS::Backup;
use base Underground8::Configuration;

use strict;
use warnings;

#use Clone::Any qw(clone);
use Clone qw(clone);

use Underground8::Utils;
use Underground8::Service::Backup;
use XML::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $appliance = shift;

    my $self = $class->SUPER::new("backup",$appliance);
    $self->{'_backup'} = new Underground8::Service::Backup;
    return $self;
}

#### Accessors ####
# local only
sub backup ($)
{
    my $self = instance(shift,__PACKAGE__);
    return $self->{'_backup'};
}

# Backup


sub backup_create_backup_name($$)
{
    my $self = instance(shift);
    return $self->backup->create_backup_name(shift);
}

sub add_backup_to_config ($$)
{
    my $self = instance(shift);
    return $self->backup->add_backup_to_config(shift);
}

sub backup_initialize_download($$)
{
    my $self = instance(shift);
    return $self->backup->initialize_download(shift);
}

sub backup_initialize_upload ($$)
{
    my $self = instance(shift);
    return $self->backup->initialize_upload(shift);
}

sub backup_write_file ($$$)
{
    my $self = instance(shift);
    return $self->backup->write_file(shift, shift);    
}

sub backup_read_file($$$)
{
    my $self = instance(shift);
    return $self->backup->read_file(shift,shift);
}

sub backup_check_file ($$)
{
    my $self = instance(shift);
    return $self->backup->check_file(shift);
}

sub get_net_interfaces ($$)
{
    my $self = instance(shift);
    return $self->backup->get_net_interfaces(shift);
}
sub backup_get_encrypted_by_index ($$)
{
    my $self = instance(shift);
    return $self->backup->get_encrypted_by_index(shift);
}

sub backup_get_list_index ($$)
{
    my $self = instance(shift);
    return $self->backup->get_list_index(shift);
}

sub backup_read_list_encrypted ($)
{
    my $self = instance(shift);
    $self->backup->read_list_encrypted();
}

sub backup_read_list_unencrypted ($)
{
    my $self = instance(shift);
    $self->backup->read_list_unencrypted();
}

sub backup_list_encrypted ($)
{
    my $self = instance(shift);
    return $self->backup->list_encrypted();
}

sub backup_list_unencrypted ($)
{
    my $self = instance(shift);
    return $self->backup->list_unencrypted();
}

sub backup_remove_encrypted_backup ($$)
{
    my $self = instance(shift);
    $self->backup->remove_encrypted_backup(shift);
}

sub backup_remove_unencrypted_backup ($$)
{
    my $self = instance(shift);
    $self->backup->remove_unencrypted_backup(shift);
}

sub backup_compare_backups ($$$)
{
    my $self = instance(shift);
    return $self->backup->compare_backups(shift, shift);
}

sub backup_remove_tempdir
{
    my $self = instance(shift);
    $self->backup->remove_tempdir();
}

sub backup_create_tempdir
{
    my $self = instance(shift);
    return $self->backup->create_tempdir();
}

sub untar_to_tempdir($)
{
    my $self = instance(shift);
    return $self->backup->untar_to_tempdir();
}

sub xml_to_tar ($$)
{
    my $self = instance(shift);
    $self->backup->xml_to_tar(shift);
}

sub tar_to_xml ($)
{
    my $self = instance(shift);
    $self->backup->tar_to_xml();
}

sub copy_from_backup ($)
{
    my $self = instance(shift);
    $self->backup->copy_from_backup();
}

sub tar_to_gzip($)
{
    my $self = instance(shift);
    $self->backup->tar_to_gzip();
}

sub gzip_to_tar($)
{
    my $self = instance(shift);
    $self->backup->gzip_to_tar();
}

sub gzip_to_crypt($)
{
    my $self = instance(shift);
    $self->backup->gzip_to_crypt();
}

sub crypt_to_gzip($)
{
    my $self = instance(shift);
    $self->backup->crypt_to_gzip();
}

sub backup_file($)
{
    my $self = instance(shift);
    return $self->{'_backup'}->backup_file();
}

sub backup_set_backup_file($$)
{
    my $self = instance(shift);
    $self->{'_backup'}->set_backup_file(shift);
}

#### CRUD Methods ####

sub commit($)
{
    my $self = instance(shift);
    $self->backup->commit() if $self->backup->is_changed;
    $self->save_config();
}


### Administration Ranges ###


#### Load / Save Configuration ####

sub load_config ($)
{
    my $self = instance(shift);
    $self->load_config_xml_smart();
}

sub load_config_xml_smart ($)
{
    my $self = instance(shift);
    my $infile = $self->config_filename();
    my ($i, $limit);
    my $XML = new XML::Dumper;
    my $params = $XML->xml2pl($infile);    
    $self->backup->import_params(\%{$params});    
}
sub save_config ($)
{
    my $self = instance(shift);
    $self->save_config_xml_smart();
}

sub save_config_xml_smart ($)
{
    my $self = instance(shift);

    my $outfile = $self->config_filename();

    my $XML = new XML::Dumper;
    # unbless the backup accounts
    my $temp = $self->backup->export_params;
    $XML->pl2xml($temp, $outfile);
}
sub restore_defaults($)
{
    my $self = instance(shift);    
	my $versions = $g->{'cfg_system_version_file'};
	
	# We just tar the versions file into the rootdir
	# change to the directory of the versionsfile before adding it to tar
	# so let's strip the path of the file
	$versions =~ s/.*\/(.*)$/$1/;
	
	
    ###### Binary Operations:
    # Set 1 to true:
    # $a |= (1 << 1)
    # Set 2 to true:
    # $a |= (1 << 2)
    # Toggle 1 (if set unset it, if unset, set it):
    # $a ^= (1 << 1)
    # Check if 1 is set:
    # if ($a & (1 << 1))
    # Check if 2 is set:
    # if ($a & (1 << 2))
    my $i = 0;
    # Check if the config file exists
    if (-e $g->{'cfg_backup_include'}
    )
    {
        # Read it andd check if at least our cfg_dir is included
        open INC, ("<" . $g->{'cfg_backup_include'});
        while (<INC>)
        {
            chomp;
            if (/^$g->{'cfg_dir'}\/$/)
            {
                $i |= (1 << 1);
            }
			if (/^$versions$/)
			{
				$i |= (1 << 2);
			}
        }
        close INC;
    }
    # if bothe were untrue (eighter include file missing or cfgline in there missing)
    # add it :-)
    unless ($i & (1 << 1) && $i & (1 << 2))
    {
        open INC, (">>" . $g->{'cfg_backup_include'});
        print INC ($g->{'cfg_dir'} . "/\n") unless ($i & (1 << 1));
        print INC ($versions . "\n") unless ($i & (1 << 2));
        close INC;
        safe_system("$g->{'cmd_chown'} $g->{'cfg_backup_include'}");
    }
    # reset our status var
    $i = 0;
    # if the exclude file exists
    if (-e $g->{'cfg_backup_exclude'})
    {
        # read it in and check if
        open EXC, ("<" . $g->{'cfg_backup_exclude'});
        while (<EXC>)
        {
            chomp;
            # the backup include file, the backup exclude file and the backup config file 
            # that holds the md5 checksums are excluded
            if (/^$g->{'cfg_backup_include'}$/)
            {
                # if include line was found, set binary 1 to true
                $i |= (1 << 1);
            }
            if (/^$g->{'cfg_backup_exclude'}$/)
            {
                # if exclude line was found, set binary 2 to true
                $i |= (1 << 2);
            }
            if (/^$self->config_filename$/)
            {
                # if config_filename line was found, set binary 3 to true
                $i |= (1 << 3);
            }
        }
        close EXC;
    }
    # as long as not all values are present
    unless ($i & (1 << 1) && $i & (1 << 2) && $i & (1 << 3))
    {
        # open the exclude file for appending
        open INC, (">>" . $g->{'cfg_backup_exclude'});
        # and append the lines as missing
        print INC ($g->{'cfg_backup_include'} . "\n") unless ($i & (1 << 1));
        print INC ($g->{'cfg_backup_exclude'} . "\n") unless ($i & (1 << 2));
        print INC ($self->config_filename . "\n") unless ($i & (1 << 3));
        close INC;
        safe_system("$g->{'cmd_chown'} $g->{'cfg_backup_exclude'}");
    }
    $self->backup->change();
    $self->commit();
}
1;

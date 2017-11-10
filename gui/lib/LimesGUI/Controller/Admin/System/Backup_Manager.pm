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


package LimesGUI::Controller::Admin::System::Backup_Manager;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use strict;
use warnings;
use Underground8::Utils;
use File::Copy;
use Error qw(:try);
use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Underground8::Exception;
use Underground8::Log;



sub index : Private {
	my ( $self, $c ) = @_;
	my $appliance = $c->config->{'appliance'};

	update_stash($self, $c);
}

sub update_stash {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	@{$c->stash->{'backup_list_encrypted'}} = @{$appliance->backup->backup_list_encrypted()};
	$c->stash->{'template'} = 'admin/system/backup_manager.tt2';
}


sub create : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};

	try {
		$appliance->set_config_lock_temp();
		$appliance->backup->backup_create_tempdir();
		$appliance->backup->xml_to_tar([{
			"_name" => $appliance->system->net_name,
			"_ip_address" => $appliance->system->ip_address,
			"_subnet_mask" => $appliance->system->subnet_mask,
			"_default_gateway" => $appliance->system->default_gateway
		}]);

		$appliance->backup->tar_to_gzip();
		$appliance->backup->backup_remove_tempdir();
		$appliance->set_config_lock_unlock();
		$appliance->backup->gzip_to_crypt();
		$appliance->backup->backup_read_list_encrypted();

		$c->stash->{'backup_file'} = $appliance->system->backup_file();
		$c->stash->{'box_status'}->{'success'} = 'success';
		aslog "info", "Created new backup-file";
	} catch Underground8::Exception with {
		$appliance->backup->backup_remove_tempdir();
		my $filename = $appliance->backup->backup_file();

		if(defined $filename && length $filename) {
			my $index = $appliance->backup->backup_get_list_index($filename);

			if(length $index && $index =~ /^\d+$/) {
				if($filename =~ /^.*\.crypt$/){
					$appliance->backup->backup_remove_encrypted_backup($index);
					$filename =~ s/^(.*)\.crypt/$1.tar.gz/;
					$index = $appliance->backup->backup_get_list_index($filename);
					if(defined $index && $index =~ /^\d+$/) {
						$appliance->backup->backup_remove_unecrypted_backup($index);
					}
				} elsif ($filename =~ /^.*\.tar.gz$/){
					$appliance->backup->backup_remove_unencrypted_backup($index);
				}
			}
		}
		
		aslog "warn", "Error creating backup file $filename, restoring previous state.";
		error($c, shift);
		$c->stash->{'box_status'}->{'custom_error'} = 'phail';
	};
	
	update_stash($self, $c);
	$c->stash->{'no_wrapper'} = "1";
}

sub error {
	my ($c, $E) = @_;
	$c->session->{'exception'} = $E;
	$c->stash->{'redirect_url'} = $c->uri_for('/error');
	$c->stash->{'template'} = 'redirect.inc.tt2';
}


sub upload : Local {
	my ($self, $c) = @_;
	my $appliance = $c->config->{'appliance'};
	my ($status, $buffer, $upload, $filename, $target);

	my $form_profile = {
		required => [qw(backup)],
	};

	my $result = $self->process_form($c, $form_profile);
	if($result->success()){
		try {
			$upload = $c->req->upload('backup');
			if($upload){
				$filename = $upload->filename;

				if( defined $filename &&
					($filename !~ /^(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)\.crypt$/ ||
					(defined $appliance->backup->backup_get_list_index($filename) &&
					 $appliance->backup->backup_get_list_index($filename) >= 0))){
					$filename = $appliance->backup->backup_create_backup_name(1);
				}

				$target = $c->config->{'backup'}{'absolutepath'} . "/" . $filename;

				unless ($upload->link_to($target) || $upload->copy_to($target)) {
					aslog "warn", "Could not store uploaded file $filename";
					throw Underground8::Exception( $c->localize('error_backup_could_not_store_upload') );
				} else {
					# Copy stored file to backup directory
					$appliance->backup->backup_initialize_upload($filename);
					open UL, "<$target" or throw Underground8::Exception($c->localize('error_backup_could_not_open_file'));
					while( read(UL, $buffer, 1024)) {
						$appliance->backup->backup_write_file($filename, $buffer);
					}
					
					$buffer = "";
					$appliance->backup->backup_write_file($filename, $buffer);
					$appliance->backup->backup_set_backup_file($filename);
					$appliance->backup->crypt_to_gzip();
					$appliance->backup->backup_create_tempdir();
					$appliance->backup->gzip_to_tar();

					my $tempdir = $appliance->backup->untar_to_tempdir();
					my $appfile = new Underground8::Appliance::LimesAS();
					my $backupname = $filename;

					$backupname =~ s/^(Backup\-\d\d\d\d\.\d\d\.\d\d\_\d\d\-\d\d\-\d\d\d*)(\.crypt|\.tar\.gz|\.tar)$/$1/;
					$appfile->system->config_filename($tempdir);
					$appfile->system->load_config();

					$appliance->backup->add_backup_to_config({
						'_name' => "$backupname",
						'_type' => "crypt",
						'_net_interface' => [{
							"_name" => $appfile->system->net_name,
							"_ip_address" => $appfile->system->ip_address,
							"_subnet_mask" => $appfile->system->subnet_mask,
							"_default_gateway" => $appfile->system->default_gateway
						}]
					});
					$appliance->backup->backup_remove_tempdir();
					$appliance->backup->commit;
				}
				
				aslog "info", "Upload of backup-cryptimage $filename successful";
				$c->stash->{'box_status'}->{'success'} = 'success';
			} else {
				aslog "warn", "Could not find uploaded file $filename";
				throw Underground8::Exception $c->localize('error_backup_no_upload_file_found');
			}
			$appliance->backup->backup_read_list_encrypted();
		} catch Underground8::Exception with {
			my $E = shift;
			if(length $filename) {
				my $index = $appliance->backup->backup_get_list_index($filename);
				if(length $index && $index =~ /^\d+$/) {
					if ($filename =~ /^.*\.crypt$/){
						$appliance->backup->backup_remove_encrypted_backup($index);
						$filename =~ s/^(.*)\.crypt$/$1.tar.gz/;
						$index = $appliance->backup->backup_get_list_index($filename);
						if(defined $index && $index =~ /^\d+$/) {
							$appliance->backup->backup_remove_unencrypted_backup($index);
						}
					} elsif ($filename =~ /^.*\.tar.gz$/){
						$appliance->backup->backup_remove_unencrypted_backup($index);
					}
					$appliance->backup->commit;
				}
				$appliance->backup->backup_remove_tempdir();
			}
			aslog "warn", "Caught exception $E while managing upload of backup $filename, revoking to previous state.";
		};
	}

	# $c->stash->{'no_wrapper'} = "1";
	update_stash($self, $c);
}


sub delete : Local {
	my ($self, $c, $file_index) = @_;
	my $appliance = $c->config->{'appliance'};

	my $filename;

	if(defined $file_index && $file_index =~ /^\d+$/){
		try {
			$filename = $appliance->backup->backup_get_encrypted_by_index($file_index);
			$appliance->backup->backup_remove_encrypted_backup($file_index);
			$appliance->backup->commit;

			aslog "info", "Deleted backup $filename";
			$c->stash->{'box_status'}->{'success'} = 'success';
		} catch Underground8::Exception with {
			aslog "warn", "Error deleting backup $filename";
			error($c, shift);
			$c->stash->{'box_status'}->{'custom_error'} = 'del_error';
		};
	} 

	$c->stash->{'box_status'}->{'success'} = 'success';
	# update_stash($self, $c);
	$c->stash->{'deleted'} = "1";

	@{$c->stash->{'backup_list_encrypted'}} = @{$appliance->backup->backup_list_encrypted()};
	# $c->stash->{'template'} = 'admin/system/backup_manager/list.inc.tt2';
	$c->stash->{'template'} = 'admin/system/backup_manager.tt2';
	$c->stash->{'no_wrapper'} = "1";
}

sub install : Local {
	my ($self, $c, $file_index) = @_;
	my $appliance = $c->config->{'appliance'}; 
	my $filename;

	if(defined $file_index && $file_index =~ /^\d+$/){
		try {
			$filename = $appliance->backup->backup_get_encrypted_by_index($file_index);
			$appliance->backup->backup_set_backup_file($filename);
			$appliance->backup->crypt_to_gzip();
			$appliance->set_config_lock_block();
			$appliance->backup->backup_create_tempdir();
			$appliance->backup->gzip_to_tar();
			$appliance->backup->tar_to_xml();
			$appliance->set_config_lock_unlock();
			$appliance->backup->backup_remove_tempdir();
			$appliance->backup->backup_read_list_encrypted();
		
			aslog "info", "Successfully installed backup $filename, initiating reboot...";
			$appliance->system->reboot();
			return;
		} catch Underground8::Exception with {
			$filename = $appliance->backup->backup_get_encrypted_by_index($file_index);
			if(defined $filename && length $filename) {
				$filename =~ s/^(.*)\.crypt/$1.tar.gz/;
				$file_index = $appliance->backup->backup_get_unecrypted_by_index($file_index);
				if( length $file_index && $file_index =~ /^\d+$/){
					$appliance->backup->backup_remove_unencrypted_backup($file_index);
				}
			}

			$appliance->backup->backup_remove_tempdir();
			aslog "warn", "Error installing given backup file $filename, recovering previous state.";
			error($c, shift);
		};
	}

	update_stash($self, $c);
}


sub download : Local {
	my ($self, $c, $file_index) = @_;
	my ($time, $modtime, $buffer) = (time(), undef, undef);

	my $absolutepath = $c->config->{'backup'}{'absolutepath'};
	my $appliance = $c->config->{'appliance'};

	if(defined $file_index && $file_index =~ /^\d+$/){
		my $file = $appliance->backup->backup_get_encrypted_by_index($file_index);

		try {
			# Delete files older than 1 day, if still in static directory
			my @oldfiles = <$absolutepath/*.crypt>;
			foreach (@oldfiles) {
				$modtime = (stat $_)[9];
				unlink $_ if ($time - $modtime > 86400);
			}

			$c->response->header('Content-Type' => 'application/octet-stream');
			$c->response->header('Content-Disposition' => 'attachment; filename=' . "ccc.crypt");

			$appliance->backup->backup_initialize_download($file);
			open DL, (">" . $absolutepath . "/" . $file);
			flock DL, 2;
			while ($buffer = $appliance->backup->backup_read_file($file)) {
				print DL $buffer;
			}
			close DL;

			$c->response->header('Content-Type' => 'application/octet-stream');
			$c->response->header('Content-Disposition' => 'attachment; filename=' . $file);
			$c->config->{'static'}->{'mime_types'} = { "crypt" => 'application/octet-stream'};
			$c->serve_static_file( $absolutepath . "/" . $file );
			aslog "info", "Successfully served backup-file $file as download";
		} catch Underground8::Exception with {
			aslog "warn", "Error serving backup-file $file as download";
			error($c, shift);
		};
	}

	# update_stash($self, $c);
}

1;

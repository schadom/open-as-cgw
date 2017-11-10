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


package Underground8::Service::Amavis::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Error;
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Template;
use Data::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('amavis');
    return $self;
}

sub service_restart ($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_amavis_restart'});
}

sub write_config ($$)
{
    my $self = instance(shift); 
    my $warn_recipient_virus = shift;
    my $warn_recipient_banned_file = shift;
    my $notification_admin = shift;
    my $spam_subject_tag = shift;
    my $banned_attachments = shift;
    my $score_map = shift;
    my $policy = shift;
    my $clamav_enabled = shift;
    my $archive_maxfiles = shift;
    my $archive_recursion = shift;
    my $unchecked_subject_tag = shift;
    my $quarantine_enabled = shift;
    my $mails_destiny = shift;
    my $admin_boxes = shift;
    $self->write_amavis_config( $warn_recipient_virus,
                                $warn_recipient_banned_file,
                                $notification_admin,
                                $spam_subject_tag,
	                            $score_map,
                                $policy,
                                $archive_maxfiles,
                                $archive_recursion,
                                $unchecked_subject_tag,
                                $quarantine_enabled,
                                $mails_destiny,
                                $admin_boxes,
				);

    $self->write_amavis_cfm(1);
    $self->write_amavis_dd($banned_attachments);

    $self->write_amavis_vs($clamav_enabled);
}

# write amavis 99-openas
sub write_amavis_config($$)
{
    my $self = shift;
    my $warn_recipient_virus = shift;
    my $warn_recipient_banned_file = shift;
    my $spam_quarantine_admin = shift;
    my $spam_subject_tag = shift;
    my $score_map = shift;
    my $policy = shift;
    my $archive_maxfiles = shift;
    my $archive_recursion = shift;
    my $unchecked_subject_tag = shift;
    my $quarantine_enabled = shift;
    my $mails_destiny = shift;
    my $admin_boxes = shift;

    my $memory_factor = $self->memory_factor;
                                             

    my $max_servers = 4 * $memory_factor;
     
    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 
    my $options = {
                    max_servers => $max_servers,
                    warn_recipient_virus => $warn_recipient_virus ? 1 : 0,
                    warn_recipient_banned_file  => $warn_recipient_banned_file ? 1 : 0,
                    notification_admin => $spam_quarantine_admin,
                    quarantine_enabled => $quarantine_enabled,
                    spam_subject_tag => quotemeta($spam_subject_tag),
                    score_map => check_quarantine_scores($score_map,$mails_destiny->{'spam_destiny'},$admin_boxes->{'spam_box'}),
                    policy => $policy,
                    archive_maxfiles => $archive_maxfiles,
                    archive_recursion => $archive_recursion,
                    unchecked_subject_tag => $unchecked_subject_tag,
                    mails_destiny =>$mails_destiny ,
                    admin_boxes  => $admin_boxes,
    };
    

    my $config_content;
    $template->process($g->{'template_amavis_99_openas'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (AMAVIS_LIMES,'>',$g->{'file_amavis_99_openas'})
        or throw Underground8::Exception::FileOpen($g->{'file_amavis_99_openas'});

    print AMAVIS_LIMES $config_content;

    close (AMAVIS_LIMES);
}

# write amavis 15-content_filter_mode
sub write_amavis_cfm ($$)
{
    my $self = instance(shift);
    my $enable = shift;
    
#    my $bypass_antivirus = $ref->{'bypass_virus'};
#    my $bypass_spam = $ref->{'bypass_spam'};

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });  

    my $options = {
#            bypass_antivirus => $bypass_antivirus,
#            bypass_spam => $bypass_spam
            bypass_antivirus => 1 - $enable,
            bypass_spam => 1 - $enable
    };

    my $config_content;
    $template->process($g->{'template_amavis_15_cfm'},$options,\$config_content)
        or throw Underground8::Exception($template->error);

    open (AMAVIS_CFM,'>',$g->{'file_amavis_15_cfm'})
        or throw Underground8::Exception::FileOpen($g->{'file_amavis_15_cfm'});
    
    print AMAVIS_CFM $config_content;

    close (AMAVIS_CFM);
}

### Changes by Brucki ###
### START ###

sub write_amavis_dd($@)
{
    my $self = instance(shift);
    my $banned = shift;

    # each (ext,ext) -> ext|ext
    my (@banned_arr, @banned_arr_contenttype);
    if( ref($banned) eq "HASH" ) {
		my $banned_ext = $banned->{ 'banned' };
		my $ch = substr( $banned_ext, 0, 1 );
		$banned_ext =~ s/[()]//g;
		$banned_ext =~ s/,/|/g;
		$banned_ext =~ s/\./\\./g;

		# if( $ch eq '[' ) {
		if( $banned_ext =~ /\// ) {
		    $banned_ext =~ s/\[//g;
		    $banned_ext =~ s/\]//g;
		    $banned_ext =~ s/\+/\\+/g;
		    push @banned_arr_contenttype, $banned_ext;
		} else {
		    push @banned_arr, $banned_ext;
		}
    } else {
		foreach my $hash_ref ( @$banned ) {
		    my $banned_ext = $hash_ref->{'banned'};
		    my $ch = substr( $banned_ext, 0, 1 );
		    $banned_ext =~ s/[()]//g;
		    $banned_ext =~ s/,/|/g;
		    $banned_ext =~ s/\./\\./g;

		    # if( $ch eq '[' ) {
			if( $banned_ext =~ /\// ) {
				$banned_ext =~ s/\[//g;
				$banned_ext =~ s/\]//g;
				$banned_ext =~ s/\+/\\+/g;
				push @banned_arr_contenttype, $banned_ext;
		    } else {
				push @banned_arr, $banned_ext;
		    }
		}
    }

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });  

    my $options = {
	banned_attachments => \@banned_arr,
	banned_attachments_contenttype => \@banned_arr_contenttype,
    };

    my $config_content;
    $template->process($g->{'template_amavis_20_dd'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (AMAVIS_DD,'>',$g->{'file_amavis_20_dd'})
      or throw Underground8::Exception::FileOpen($g->{'file_amavis_20_dd'});
    
    print AMAVIS_DD $config_content;
    
    close (AMAVIS_DD);
}


sub write_amavis_vs($@)
{
    my $self = instance(shift);
    my $clamav_enabled = shift;

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      });  

    my $options = {
        clamav_enabled => $clamav_enabled,
    };

    my $config_content;
    $template->process($g->{'template_amavis_15_vs'},$options,\$config_content)
      or throw Underground8::Exception($template->error);
    
    open (AMAVIS_VS,'>',$g->{'file_amavis_15_vs'})
      or throw Underground8::Exception::FileOpen($g->{'file_amavis_15_vs'});
    
    print AMAVIS_VS $config_content;
    
    close (AMAVIS_VS);
}
### END ###

###THIS is a function that checks if quarantine is ON or OFF , if OFF the kill score becomes = cutoff score
#@params : scoremap , quarantine_enabled, admin adress for spam
#returns the new hash with values changed if Q is OFF
sub check_quarantine_scores ($$$)
{
    ##REMINDER OF SCORES
    #
    #tag =>tag2_level
    #block=>kill_level
    #cutoff =>quarantine_cutoff_level
    #dsn => dsn_cutoff_level
    #

    my $scores_map = shift;
    my $quarantine_enabled = shift;
    my $new_map ;
    my $quarantine_address = shift;
    if ($quarantine_enabled >= 1) # means quarantine to admin box or Per user quarantine
    {  
        foreach my $k (keys %$scores_map)
        {
            foreach my $score (keys %{$scores_map->{$k}}){
                
                $new_map->{$k}->{$score} = $scores_map->{$k}->{$score};
            }
            if($new_map->{$k}->{'block'} == 0)
            {
                $new_map->{$k}->{'block'} = $new_map->{$k}->{'cutoff'};
            }
        }
     
    }
    elsif($quarantine_enabled == 0) # throwing spam 
    {
        foreach my $k (keys %$scores_map)
        {
            foreach my $score (keys %{$scores_map->{$k}}){
               
                $new_map->{$k}->{$score} = $scores_map->{$k}->{$score};
            }
            #throwning spam mail if the score is above cutoff score -> this is done by setting every block score to the cutoff score
            #this way amavis will block mail and discard it .
            $new_map->{$k}->{'block'} = $new_map->{$k}->{'cutoff'};
        }
    }
    
    return $new_map;
}



1;

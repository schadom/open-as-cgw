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


package Underground8::Service::Amavis;
use base Underground8::Service;

use strict;
use warnings;
use Underground8::QuarantineNG::Base;
use Underground8::QuarantineNG::Common;
use Underground8::Utils;
use Underground8::Service::Amavis::SLAVE;

use Data::Dumper;
use XML::Dumper;
#Constructor
sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::Amavis::SLAVE();
    $self->{'_warn_recipient_virus'} = 0;
    $self->{'_warn_recipient_banned_file'} = 0;    
    $self->{'_notification_admin'} = '';
    $self->{'_spam_subject_tag'} = '';
    $self->{'_has_changes'} = '';
    $self->{'_banned_attachments'} = [];
    $self->{'_score_map'} = {
            DEFAULT => {tag =>4.0, block=> 5.0, cutoff=> 0,dsn =>25.0 },
            SMTPAUTH => {tag => 4.0, block=> 5.0, cutoff=>0 ,dsn =>25.0 } ,
            RELAYHOSTS => {tag =>4.0, block=> 5.0, cutoff=> 0,dsn => 25.0 },
            WHITELIST => {tag => 4.0 , block=> 5.0, cutoff=> 0 ,dsn => 25.0 },
            DEFAULTQON =>{tag => 4.0 , block=> 5.0, cutoff=> 0,dsn => 25.0 },
            DEFAULTQOFF =>{tag => 4.0 , block=> 5.0, cutoff=> 0,dsn => 25.0 }
    };

    $self->{'_policy'} =  { 
        external =>  { bypass_spam => 0, bypass_att => 0, bypass_virus => 0 },
        whitelist => { bypass_spam => 1, bypass_att => 1, bypass_virus => 1 },
        smtpauth =>  { bypass_spam => 1, bypass_att => 0, bypass_virus => 1 },
        internal =>  { bypass_spam => 1, bypass_att => 1, bypass_virus => 1 },
    };

    $self->{'_clamav_enabled'} = 1;
    $self->{'_archive_maxfiles'} = 1000;
    $self->{'_archive_recursion'} = 12;
    $self->{'_unchecked_subject_tag'} = '** UNCHECKED **';
    
    $self->{'_credentials'}={
            'username' =>'amavis',
            'password' => 're2dd3j',
            'host' =>'localhost'};
    
    $self->{'_quarantine_enabled'} = 0;    #quarantine state
        
    #DESTINIES ARE :
    # 0 : Throw away
    # 1 : Send to Admin Mailbox
    # 2 : Store in User Quarantine 

    $self->{'_mails_destiny'} = {   
            spam_destiny =>2,
            virus_destiny =>2,
            banned_destiny =>2,
            };

    # where infected mails(SPAM/VIRUS/BANNED) get sent if mails_destiny is 1
    $self->{'_admin_boxes'} ={
            'spam_box'  => '',
            'virus_box' => '',
            'banned_box'=> ''
            };    
    return $self;
}

#### Accessors ####

sub remove_slave ($)
{
    my $self = instance(shift);
    delete $self->{'_slave'};
}

sub policy
{
    my $self = instance(shift);
    return $self->{'_policy'};
}

sub policy_external
{
    my $self = shift;
    my $setting = shift;

    unless ($setting)
    {
        warn "No policy setting defined!";
    }
    else
    {
        unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/)
        {
            warn "No valid setting supplied!"; 
        }
        else
        {
            if (@_)
            {
                $self->policy->{'external'}->{$setting} = shift;
                $self->change;
            }
            return $self->policy->{'external'}->{$setting};
        }
    }
}

sub policy_whitelist
{
    my $self = shift;
    my $setting = shift;

    unless ($setting)
    {
        warn "No policy setting defined!";
    }
    else
    {
        unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/)
        {
            warn "No valid setting supplied!"; 
        }
        else
        {
            if (@_)
            {
                $self->policy->{'whitelist'}->{$setting} = shift;
                $self->change;
            }
            return $self->policy->{'whitelist'}->{$setting};
        }
    }
}

sub policy_smtpauth
{
    my $self = shift;
    my $setting = shift;

    unless ($setting)
    {
        warn "No policy setting defined!";
    }
    else
    {
        unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/)
        {
            warn "No valid setting supplied!"; 
        }
        else
        {
            if (@_)
            {
                $self->policy->{'smtpauth'}->{$setting} = shift;
                $self->change;
            }
            return $self->policy->{'smtpauth'}->{$setting};
        }
    }
}

sub policy_internal
{
    my $self = shift;
    my $setting = shift;

    unless ($setting)
    {
        warn "No policy setting defined!";
    }
    else
    {
        unless ($setting =~ qr/bypass_spam|bypass_att|bypass_virus/)
        {
            warn "No valid setting supplied!"; 
        }
        else
        {
            if (@_)
            {
                $self->policy->{'internal'}->{$setting} = shift;
                $self->change;
            }
            return $self->policy->{'internal'}->{$setting};
        }
    }
} 

sub warn_recipient_virus ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_warn_recipient_virus'} = shift;
        $self->change;
    }
    return $self->{'_warn_recipient_virus'};
}

sub warn_recipient_banned_file ($@)
{
    my $self = instance(shift);
    if (@_) 
    {
        $self->{'_warn_recipient_banned_file'} = shift;
        $self->change;
    }
    return $self->{'_warn_recipient_banned_file'};
}

sub notification_admin ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_notification_admin'} = shift;
        $self->change;
    }
    return $self->{'_notification_admin'};
}

sub quarantine_admin ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_quarantine_admin'} = shift;
        $self->change;
    }
    return $self->{'_quarantine_admin'};
} 

sub quarantine_enabled ($$)
{
    my $self = instance(shift);
    if (@_)
    {   
        $self->{'_quarantine_enabled'} = shift;
        $self->change;
    }
    return $self->{'_quarantine_enabled'};
}

sub spam_subject_tag ($@)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_spam_subject_tag'} = shift;
        $self->change;
    }
    return $self->{'_spam_subject_tag'};
}


### Changes by Brucki ###
### START ###
sub banned_attachments ($@)
{
    my $self = instance(shift);
    
    if(@_ && !($self->banned_attachment_exists(my $banned_attachment = shift)))
    {
        my $description = shift;
        my $grp = shift;
        my $touple = {'banned' => $banned_attachment, 'description' => $description };
        #a third parameter may exist, in this case we add it to the touple
        if (defined $grp) {$touple->{'grp'} = $grp};
        push @{$self->{'_banned_attachments'}}, $touple;
        $self->change;
    }

    my @sorted = sort { $a->{'banned'} cmp $b->{'banned'} } @{ $self->{'_banned_attachments'} };
    $self->{'_banned_attachments'} = \@sorted;

    return $self->{'_banned_attachments'};
}

 #returns a hash of arrays, each array is of the form  ['group description',['ext1','ext2'.....]]
sub attachments_groups($){
    my $self = instance(shift);
    return new XML::Dumper->xml2pl($g->{'extensions_groups'}); 
}
#returns the groups names list, ie : "images" "Archives"...
sub banned_attachments_groups($@)
{
    my $self = instance(shift);
    my $groups =  new XML::Dumper->xml2pl($g->{'extensions_groups'});
    return keys %$groups;  
}
sub banned_attachments_contenttypes ($@)
{
    my $self = instance(shift);
    
    my @arr;
    # all the information are took from /etc/mime.types
    # open( MIME, $g->{'mime_types'} );
    open( MIME, $g->{'mime_types_amavis'} );
    while( my $line = <MIME> )
    {
        next if $line =~ /^\s*$/;
        next if $line =~ /^#/;
        my @fields = split( /\s+/, $line );
        my $banned = $fields[0] ? $fields[0] : $fields[1];
        eval
        {
            next if $self->banned_attachment_exists( '[' . $banned . ']' );
        };
        if( $@ ) 
        {
        next;
        }
	    push @arr, $banned;
    }
    close( MIME );
    return \@arr;
}


sub del_banned_attachment($$)
{
    my $self = instance(shift);
    my $banned_attachment = shift;
    my $loop = 0;
    foreach my $banned_hash (@{$self->{'_banned_attachments'}})
    {
	if($banned_hash->{'banned'} eq "$banned_attachment")
	{
	    splice(@{$self->{'_banned_attachments'}},$loop,1);
	    $self->change;
	    return 1;
	}
	$loop++;	
    }
    throw Underground8::Exception::EntryNotExists();
}

sub banned_attachment_exists($$)
{
    my $self = instance(shift);
    my $banned_attachment = shift;
    my $length = @{$self->{'_banned_attachments'}};

    if($length > 0)
    {
	foreach my $attachment (@{$self->{'_banned_attachments'}})
	{
	    if($attachment->{'banned'} eq "$banned_attachment")
	    {
		throw Underground8::Exception::EntryExists();
	    }
	}
    }
    return 0;
}

##  Change all the scores in once
#param : reference to a hash of the new values.
sub score_map ($$)
{
    my $self = instance(shift);
    if(@_)
    {
        my $new_scores=shift;
        my $score_map=$self->{'_score_map'};
        #assign the values of the recieved hash to the field _score_map
        foreach my $policy (keys %$score_map)
        {
            foreach my $score (keys %{$score_map->{DEFAULT}})
            {   
                $score_map->{$policy}->{$score} = $new_scores->{$policy}->{$score};
            }
        }
        $self->change();
    }
    return $self->{'_score_map'};
    
}

# set a specified score of a specified policy to the new given value
# in our system ZERO is a special score that means not defined
sub set_score($$$$)
{
    my $self = instance(shift);
    if(@_)
    {
        my $policy = shift;
        my $score = shift;
        my $value = shift;
        $self->{'_score_map'}->{$policy}->{$score} = $value ;
        $self->change;
    }
    
}
sub enable_clamav()
{
    my $self = instance(shift);

    $self->{'_clamav_enabled'} = 1;
    $self->change;
}

sub disable_clamav()
{
    my $self = instance(shift);

    $self->{'_clamav_enabled'} = 0;
    $self->change;
}

sub clamav_enabled
{
    my $self = instance(shift);
    return $self->{'_clamav_enabled'};
}

sub archive_maxfiles
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_archive_maxfiles'} = shift;
        $self->change;
    }
    return $self->{'_archive_maxfiles'};
}

sub archive_recursion
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_archive_recursion'} = shift;
        $self->change;
    }
    return $self->{'_archive_recursion'};
}

sub unchecked_subject_tag
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_unchecked_subject_tag'} = shift;
        $self->change;
    }
    return $self->{'_unchecked_subject_tag'};
}


sub mails_destiny
{
    my $self = instance(shift);
    if (@_)
    {   
        $self->{'_mails_destiny'} = shift;
        $self->change;
    }
    return $self->{'_mails_destiny'};
}


sub get_mails_destiny
{
    my $self = instance(shift);
    return $self->{'_mails_destiny'};
}


#admin mailboxes for quarantining
sub get_admin_boxes {
    my $self = instance(shift);
    return $self->{'_admin_boxes'};
}

sub admin_boxes($)
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_admin_boxes'} = shift;
        $self->change;
    }
    return $self->{'_admin_boxes'};
}


sub write_quarantine_scores($$)
{   
    my $self = instance(shift);
    my $scores = shift;
    my $spam_destiny = $self->get_mails_destiny->{'spam_destiny'};

    #update_policy_scores is located in QuarantineNG/Base.pm
    update_policy_scores($self->{'_credentials'},'DEFAULTQON',$scores->{'DEFAULTQON'},$spam_destiny,$self->admin_boxes->{'spam_box'});
    update_policy_scores($self->{'_credentials'},'DEFAULTQOFF',$scores->{'DEFAULTQOFF'},$spam_destiny ,$self->admin_boxes->{'spam_box'});
}


sub commit ($)
{
    my $self = instance(shift);
    $self->write_quarantine_scores($self->score_map); #updating SQL DB with new scores.
    
    my $files;
    push @{$files}, $g->{'file_amavis_15_vs'};
    push @{$files}, $g->{'file_amavis_15_cfm'};
    push @{$files}, $g->{'file_amavis_20_dd'};
    push @{$files}, $g->{'file_amavis_99_openas'};

    my $md5_first = $self->create_md5_sums($files);

    $self->slave->write_config( 
	    $self->warn_recipient_virus,
	    $self->warn_recipient_banned_file,
	    $self->notification_admin,
	    $self->spam_subject_tag,
	    $self->banned_attachments,
	    $self->score_map,
    	$self->policy,
        $self->clamav_enabled,
        $self->archive_maxfiles,
        $self->archive_recursion,
        $self->unchecked_subject_tag,
        $self->quarantine_enabled,
        $self->get_mails_destiny,
        $self->admin_boxes,
    );

    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }
    $self->unchange;
}

sub restart($){
	my $self = instance(shift);
	$self->slave->service_restart();
}

###IMPORT overriding ####
sub import_params ($$)
{
    my $self = instance(shift);
    my $import = shift;
    if (ref($import) eq 'HASH')
    {
        # backwards compatibility with the old system ('spam_score' + 'block_score')
        foreach my $key (keys %$import)
        {
            #we translate "possible" old configuration to the new one (with score map)
            if($key eq '_spam_score') 
            { 
                $self->{'_score_map'}->{DEFAULT}->{'tag'} = $import->{$key};
            }
            elsif($key eq '_block_score'){
                $self->{'_score_map'}->{DEFAULT}->{'cutoff'} = $import->{$key};
            }
            elsif($key eq '_info_score'){}# info score is no more used, so the object don't have this information any more
            else {$self->{$key} = $import->{$key};}
        }
        # backwards compatibility with the old system (quarantine_enabled + quarantine_admin)

        if(not defined $import->{'_mails_destiny'}) #we are in an old system
        {
            if($import->{'_quarantine_enabled'} == 1){
                #we translate this to the new System i.e all mails_destiny goes to PerUserQuarantine
                foreach my $dest (keys %{$self->get_mails_destiny})
                {
                    $self->{'_mails_destiny'}->{$dest} = 2;
                }
            }
            #if an email addresse was given we set the right mails_destiny and Admin mailboxes
            elsif(defined $import->{'_quarantine_admin'} && $import->{'_quarantine_admin'} ne '') 
            {
                foreach my $dest (keys %{$self->get_mails_destiny}) 
                {
                    $self->{'_mails_destiny'}->{$dest} = 1;
                }

            }
            #If it was not given then we set the right destiny
            else 
            {
                foreach my $dest (keys %{$self->get_mails_destiny})
                {
                    $self->{'_mails_destiny'}->{$dest} = 0;
                }
            }
            #save the eventual Admin address to the new hash
            foreach my $adr (keys %{$self->admin_boxes})
            {
                $self->{'_admin_boxes'}->{$adr} = $import->{'_quarantine_admin'} ;
            }
            #delete the quarantine_admin key since we have replaced it 
            delete $self->{'_quarantine_admin'};

            # do not delete quarantine_enabled option !!!
        }
        
        $self->change;
    }
    else
    {
        warn 'No hash supplied!, keeping default built-on values';
    }
}

### END ###
1;

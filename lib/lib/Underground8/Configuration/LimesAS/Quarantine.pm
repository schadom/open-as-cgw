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


package Underground8::Configuration::LimesAS::Quarantine;
use base Underground8::Configuration;

use strict;
use warnings;


use Underground8::Utils;
use Underground8::Service::QuarantineNG;
use XML::Dumper;
use Data::Dumper;

# Constructor
sub new ($$)
{
    my $class = shift;
    my $appliance = shift;

    my $self = $class->SUPER::new("quarantine",$appliance);
    $self->{'_quarantineNG'} = new Underground8::Service::QuarantineNG(); 
    return $self;
}

#### Accessors ####
sub quarantineNG 
{
    my $self = instance(shift);
    return $self->{'_quarantineNG'};
}


#### Methods ####
sub whitelisted_domains 
{
    my $self = instance(shift);

    return $self->quarantineNG->whitelisted_domains();
}

sub notify_unconfirmees_interval
{
    my $self = instance(shift);

    return $self->quarantineNG->notify_unconfirmees_interval();
}

sub send_spamreport_interval
{
    my $self = instance(shift);

    return $self->quarantineNG->send_spamreport_interval();
}


sub quarantine_enabled
{
    my $self = instance(shift);
   
    return $self->quarantineNG->quarantine_enabled();
}

sub max_confirm_retries
{
    my $self = instance(shift);
    return $self->quarantineNG->max_confirm_retries(shift);
}

sub max_confirm_interval 
{
    my $self = instance(shift);
    return $self->quarantineNG->max_confirm_interval(shift);
}

sub max_quarantine_size 
{
    my $self = instance(shift);
    return $self->quarantineNG->max_quarantine_size(shift);
}

sub global_item_lifetime
{   
    my $self = instance(shift);
    return $self->quarantineNG->global_item_lifetime(shift);
}

sub user_item_lifetime
{   
    my $self = instance(shift);
    return $self->quarantineNG->user_item_lifetime(shift);
}

sub sender_name
{   
    my $self = instance(shift);
    return $self->quarantineNG->sender_name(shift);
}

sub sizelimit_address
{   
    my $self = instance(shift);
    return $self->quarantineNG->sizelimit_address(shift);
}

sub language
{
    my $self = instance(shift);
    return $self->quarantineNG->language(shift);
}

sub check_sender
{
    my $self = instance(shift);
    return $self->quarantineNG->check_sender(shift);
}


sub global_enable 
{
   my $self = instance(shift);
   $self->quarantineNG->global_enable(shift);
}

sub global_disable 
{
    my $self = instance(shift);
    $self->quarantineNG->global_disable(shift);
}

sub toggle_notifications
{
    my $self = instance(shift);
    $self->quarantineNG->toggle_notifications(shift,shift);
}

sub get_notification_state
{
    my $self = instance(shift);
    $self->quarantineNG->get_notification_state(shift);
}
sub quarantine_state
{
    my $self = instance(shift);
    return $self->quarantineNG->quarantine_state() ;
}

sub notification_sending_state
{
    my $self = instance(shift);
    return $self->quarantineNG->notification_sending_state() ;
}


sub report_sending_state
{
    my $self = instance(shift);
    return $self->quarantineNG->report_sending_state() ;
}


sub show_virus_state
{
    my $self = instance(shift);
    return $self->quarantineNG->show_virus_state() ;
}

sub show_banned_state
{
    my $self = instance(shift);
    return $self->quarantineNG->show_banned_state() ;
}

sub show_spam_state
{
    my $self = instance(shift);
    return $self->quarantineNG->show_spam_state() ;
}

sub hide_links_virus_state
{
    my $self = instance(shift);
    return $self->quarantineNG->hide_links_virus_state() ;
}

sub hide_links_banned_state
{
    my $self = instance(shift);
    return $self->quarantineNG->hide_links_banned_state() ;
}

sub hide_links_spam_state
{
    my $self = instance(shift);
    return $self->quarantineNG->hide_links_spam_state() ;
}

sub change_multiple_settings ($)
{
    my $self = instance(shift);
    $self->quarantineNG->change_multiple_settings(shift) ;
}
sub change_intervals($$)
{
    my $self = instance(shift);
    $self->quarantineNG->change_intervals(shift,shift);
}
sub get_interval ($)
{
    my $self = instance(shift);
    $self->quarantineNG->get_interval(shift) ;
}
sub valid($)
{
    my $self = instance(shift);
    $self->quarantineNG->valid(shift) ;
}
sub recipients_list_by_domain($)
{
    my $self = instance(shift);
    $self->quarantineNG->recipients_list_by_domain(shift) ;
}

sub recipients_list($)
{
    my $self = instance(shift);
    $self->quarantineNG->recipients_list(shift) ;

}

sub toggle_quarantine_recipient ($$)
{
    my $self = instance(shift);
    $self->quarantineNG->toggle_quarantine_recipient(shift,shift) ;

}

sub notify_recipient($)
{
    my $self = instance(shift);
    $self->quarantineNG->notify_recipient(shift) ;

} 
sub recipient_mails($)
{
    my $self = instance(shift);
    $self->quarantineNG->recipient_mails(shift) ;
}    
sub reset_counters($)
{
    my $self = instance(shift);
    $self->quarantineNG->reset_counters(shift);
}
sub delete_mail($$)
{
    my $self = instance(shift);
    $self->quarantineNG->delete_mail(shift,shift);

}

sub delete_all_mails($)
{
    my $self = instance(shift);
    $self->quarantineNG->delete_all_mails(shift);
}


sub release_mail($$)
{
    my $self = instance(shift);
    $self->quarantineNG->release_mail(shift,shift);

}

sub update_sql_quarantine_location($$)
{
    my $self = instance(shift);
    $self->quarantineNG->update_sql_quarantine_location(shift,shift);
}

sub update_quarantine_domains($$$)
{
    my $self = instance(shift);
    $self->quarantineNG->update_quarantine_domains(shift,shift,shift);
}

sub update_quarantine_whitelist($@)
{
    my $self = instance(shift);
    $self->quarantineNG->update_quarantine_whitelist(shift,@_);
}
#### CRUD Methods ####

sub commit($)
{
    my $self = instance(shift);
    $self->quarantineNG->commit() if $self->quarantineNG->is_changed;
    $self->save_config();
}


### Administration Ranges ###


#### Load / Save Configuration ####

sub load_config ($)
{
    my $self = instance(shift);
    my $dump = new XML::Dumper();
    my $infile = $self->config_filename();
    if (-e $infile)
    {
        my $config = $dump->xml2pl($infile);
        $self->quarantineNG->import_params($config); 
    } else {
        # maybe create the empty file?
    }
}


sub save_config ($)
{
    my $self = instance(shift);
    my $dump = new XML::Dumper();
    my $outfile = $self->config_filename();
    $dump->pl2xml($self->quarantineNG->export_params(),$outfile) or throw Underground8::Exception::FileOpen($outfile);
}


1;

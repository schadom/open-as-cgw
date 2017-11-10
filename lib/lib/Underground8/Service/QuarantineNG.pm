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


package Underground8::Service::QuarantineNG;
use base Underground8::Service;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Service::QuarantineNG::SLAVE;
use Digest::MD5 qw(md5_base64);
use Email::MIME::CreateHTML;
use Email::Sender::Simple qw(sendmail);
use Template;
use DateTime;
use Underground8::QuarantineNG::Common;
use Underground8::QuarantineNG::Base;
use Encode;

#Constructor
sub new ($$)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_slave'} = new Underground8::Service::QuarantineNG::SLAVE();
    $self->{'_listen_port'} = 10010 ;
    $self->{'_db_name'} = 'amavis' ;
    $self->{'_db_host'} = 'localhost' ;
    $self->{'_db_user'} = 'amavis' ;
    $self->{'_db_password'} = 're2dd3j' ;
    $self->{'_listen_address'} = 'localhost' ;
    $self->{'_quarantine_path'} = '/var/lib/mysql/amavis';
    $self->{'_quarantine_enabled'} = 0;
    $self->{'_send_notifications_enabled'} = 1;
    $self->{'_send_reports_enabled'} = 1;
    $self->{'_domain_map'} = '/etc/postfix/transport.db';
    $self->{'_language'} = 'en' ;
    $self->{'_check_sender'} = 0 ;
    $self->{'_max_confirm_retries'} = 3;
    $self->{'_max_confirm_interval'} = 7;
    $self->{'_max_quarantine_size'} = 5120; # in megabyte
    $self->{'_global_item_lifetime'} = 7;
    $self->{'_user_item_lifetime'} = 14;
    $self->{'_sender_name'} = 'AS Communication Gateway';
    $self->{'_sizelimit_address'} = 'support@underground8.com';
    $self->{'_show_virus'} = 1;
    $self->{'_show_banned'} = 1;
    $self->{'_show_spam'} = 1;
    $self->{'_hide_links_virus'} = 0;
    $self->{'_hide_links_banned'} = 0;
    $self->{'_hide_links_spam'} = 0;
    $self->{'_whitelisted_domains'} = "";
    $self->{'_notify_unconfirmees_interval'} ={
                                                'min'     =>"0",
                                                'h'       =>"5",
                                                'd_of_m'  =>"*",
                                                'month'   =>"*",
                                                'd_of_w'  =>"*"};
    $self->{'_send_spamreport_interval'} = {
                                                'min'     =>"0",
                                                'h'       =>"6",
                                                'd_of_m'  =>"*",
                                                'month'   =>"*",
                                                'd_of_w'  =>"*"};

    return $self;
}                                                        
                                                         
#### Accessors ####

sub whitelisted_domains
{
    my $self = instance(shift);
    return $self->{'_whitelisted_domains'};
}

sub notify_unconfirmees_interval
{   
    my $self = instance(shift);
    return $self->{'_notify_unconfirmees_interval'};
}

sub send_spamreport_interval
{   
    my $self = instance(shift);
    return $self->{'_send_spamreport_interval'};
}

sub quarantine_enabled
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_quarantine_enabled'} = shift;
        $self->change;
    }
    return $self->{'_quarantine_enabled'};
}

sub language
{
    my $self = instance(shift);
    if (@_)
    {   
        $self->{'_language'} = shift;
        $self->change;
    }
    return $self->{'_language'};
}

sub check_sender
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_check_sender'} = shift;
        $self->change;
    }
    return $self->{'_check_sender'};
}


sub max_confirm_retries
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_max_confirm_retries'} = shift;
        $self->change;
    }
    return $self->{'_max_confirm_retries'};
}

sub max_confirm_interval 
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_max_confirm_interval'} = shift;
        $self->change;
    }
    return $self->{'_max_confirm_interval'};
}

sub max_quarantine_size 
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_max_quarantine_size'} = shift;
        $self->change;
    }
    return $self->{'_max_quarantine_size'};
}

sub global_item_lifetime
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_global_item_lifetime'} = shift;
        $self->change;
    }
    return $self->{'_global_item_lifetime'};
}

sub user_item_lifetime
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_user_item_lifetime'} = shift;
        $self->change;
    }
    return $self->{'_user_item_lifetime'};
}

sub sender_name
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_sender_name'} = shift;
        $self->change;
    }
    return $self->{'_sender_name'};
}

sub sizelimit_address
{
    my $self = instance(shift);
    if (@_)
    {
        $self->{'_sizelimit_address'} = shift;
        $self->change;
    }
    return $self->{'_sizelimit_address'};
}

###Utility functions
#
sub global_enable 
{
    my $self = instance(shift); 
    my $admin_boxes = shift;
    my $mails_destiny = shift;
    $self->update_sql_quarantine_location($admin_boxes,$mails_destiny);
    $self->{'_quarantine_enabled'} = 1 ;
    $self->change;
}

sub global_disable 
{
    my $self = instance(shift);   
    my $admin_boxes = shift;
    my $mails_destiny = shift;
    $self->update_sql_quarantine_location($admin_boxes,$mails_destiny);
    $self->{'_quarantine_enabled'} = 0 ;
    $self->change;
}

#used to enable or disable a notification type
#@params : notification_name , value : 0 or 1
sub toggle_notifications($$)
{
    my $self = instance(shift);
    my $notification = shift;
    my $value = shift;
    $self->{'_'.$notification} = $value;
}
#return the notification state 
#params : notification name  e.g. send_reports_enabled , send_notifications_enabled
sub get_notification_state ($$)
{
    my $self = instance(shift);
    my $notification_name = shift;
    return $self->{'_' . $notification_name}  ;
}
sub quarantine_state
{  
    my $self = instance(shift);
    return $self->{'_quarantine_enabled'}  ;
}

sub notification_sending_state
{  
    my $self = instance(shift);
    return $self->{'_send_notifications_enabled'}  ;
}



sub report_sending_state
{  
    my $self = instance(shift);
    return $self->{'_send_reports_enabled'}  ;
}

sub show_virus_state
{  
    my $self = instance(shift);
    return $self->{'_show_virus'}  ;
}

sub show_banned_state
{  
    my $self = instance(shift);
    return $self->{'_show_banned'}  ;
}

sub show_spam_state
{  
    my $self = instance(shift);
    return $self->{'_show_spam'}  ;
}

sub hide_links_virus_state
{  
    my $self = instance(shift);
    return $self->{'_hide_links_virus'}  ;
}

sub hide_links_banned_state
{  
    my $self = instance(shift);
    return $self->{'_hide_links_banned'}  ;
}

sub hide_links_spam_state
{  
    my $self = instance(shift);
    return $self->{'_hide_links_spam'}  ;
}

#allows you to change multiple values at the same time
sub change_multiple_settings ($)
{
    my $self = instance(shift);
    my $params = shift;
    foreach my $key (keys %$params)
    {
        $self->{"_$key"} = $params->{$key};
    }
    $self->change();
}

#returns the interval hash, based on its name 
sub get_interval ($)
{
    my $self = instance(shift);
    my $interval_name = shift;
    $interval_name = "_" . $interval_name . "_interval";
    return $self->{$interval_name};
}

sub change_intervals($$)
{
    my $self = instance(shift);
    my $intervals = shift;
    foreach my $interval (keys %$intervals)
    {
        foreach my $cron_col (keys %{$intervals->{$interval}})
        {
            if($intervals->{$interval}->{$cron_col} eq "all"  )
            {
                $self->{'_'.$interval}->{$cron_col} = "*";
            }
            elsif(ref $intervals->{$interval}->{$cron_col}  eq 'ARRAY')
            {
                if( grep /all/, @{$intervals->{$interval}->{$cron_col}})
                {
                    $self->{'_'.$interval}->{$cron_col} = "*";
                }
                else
                {
                    $self->{'_'.$interval}->{$cron_col} = join ',' , @{$intervals->{$interval}->{$cron_col}};
                }
            }
            else
            {
                $self->{'_'.$interval}->{$cron_col} = $intervals->{$interval}->{$cron_col};
            }
        }
    }
    $self->change();
}

#valid recipient ?
sub valid($)
{   
    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $email = shift;
    my $sth = $dbh->prepare("SELECT policy_id from users where email=?");
    $sth->bind_param(1,$email);
    my $rows = $sth->execute();
    my $res;
    # if rows == 0 the user has no quarantine defined,-->maybe unconfirmed yet or inexistant 
    if($rows == 0)
    {
       # if email doesn't exist return -1 else if unconfirmed return 0
        my $sth1 = $dbh->prepare("SELECT * from maddr where email=?");
        $sth1->bind_param(1,$email);
        my $rows2 = $sth1->execute();

        $res = ($rows2 > 0) ? 0 : -1 ;
        $sth1->finish();
    }
    else
    {
        my $ref = $sth->fetchrow_hashref();
        $res = $ref->{'policy_id'};
    }
    $sth->finish();
    $dbh->disconnect();
    return $res;
}


#all_configured domains


sub recipients_list($)
{
    my $self = instance(shift);
    my $domains_hash = shift;
    my @domains = keys %$domains_hash;
    my @all_recipients;
    foreach my $domain (@domains)
    {
        push @all_recipients, @{$self->recipients_list_by_domain($domain)};
    }
    @all_recipients = sort { $a->{'email'} cmp $b->{'email'} } @all_recipients;

    return \@all_recipients;
}
# returns the list of recipients configured for a certain domain
# @params : domain_name
sub recipients_list_by_domain($)
{ 
    my $self = instance(shift); 
    my $domain = shift;
    my $mydbh = $self->db_connect();
    my @emails=();
    if($mydbh)
    {  
       
       #magic : office.u8.com becomes com.u8.office -> this is needed because the entries in DB are in the 2nd format...don't ask me why!
        $domain = join ('.',reverse (split(/\./,$domain) ));
        my $req =$mydbh->prepare("SELECT * FROM maddr WHERE domain=?;");
        $req->bind_param(1,$domain);
        $req->execute();
        while(my $row=$req->fetchrow_hashref())
        {   
            if($row->{'quarantiny'}== 0)
            {   
                $row->{'status'} = 'notconfirmed';
                $row->{'decision'} = 0;
            }
            elsif($row->{'quarantiny'}== 1 || $row->{'quarantiny'}== 2)
            {   
                $row->{'status'} = 'confirmed';
                my $usr =$mydbh->prepare("SELECT * FROM users WHERE email =? ;");
                $usr->bind_param(1,$row->{'email'});
                $usr->execute();
                my $user_info = $usr->fetchrow_hashref();
                $row->{'decision'} = $user_info->{'policy_id'};
            }

            push @emails, $row;
        }
    }

    $mydbh->disconnect();
    $self->change();
    @emails = sort { $a->{'email'} cmp $b->{'email'} } @emails;
    return \@emails;

}

#Sets notifications counter to 0 and first notification to 00:00:00...
sub reset_counters($)
{
   my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $email = shift;
    my $sth = $dbh->prepare("UPDATE maddr SET confirmation_counter = 0, first_confirmation =0 WHERE email = ?");
    $sth->bind_param(1,$email);
    $sth->execute();
    $sth->finish();
    $dbh->disconnect();
}


sub notify_recipient($)
{
    my $self = instance(shift);
    my $dbh = $self->db_connect(); 
    my $host_name = `hostname -f`;
    my $quarantine_address = get_quarantine_address_from_map();
    my $unconfirmed_mail = shift;
    my $unconfirmed_domain = undef;
    if ($unconfirmed_mail =~ /\@(.*)$/)
    {   
        $unconfirmed_domain = $1;
    }
    #First we locate the recipient inside the maddr and we get the confirmation counter
    my $unconf = $dbh->prepare("SELECT * FROM maddr WHERE email =?");
    $unconf->bind_param(1, $unconfirmed_mail);
    $unconf->execute();
    my $ref = $unconf->fetchrow_hashref();
    $unconf->finish();
    my $confirmation_counter = $ref->{'confirmation_counter'};
    my $unconfirmed_id = $ref->{'id'};
    my $domain_state = confirm_domain($self->{'_domain_map'}, $unconfirmed_domain);
    if ($domain_state == 1)
    {   
        #confirmation id
        my $confirmation_id ;
        my $sth2 = $dbh->prepare("SELECT * FROM confirmation where maddr_id=? ");
        $sth2->bind_param(1,$unconfirmed_id);
        my $match = $sth2->execute();
        if($match >0)
        {
            my $confirmation = $sth2->fetchrow_hashref();      
            $confirmation_id = $confirmation->{'confirmation_id'}; 
        } 
        else{
            #generate a new one
            $confirmation_id = substr(md5_base64(rand(100)), 0, 12);
            my $sth3 = $dbh->prepare("INSERT INTO confirmation (maddr_id,confirmation_id) VALUES (?,?)");
            $sth3->bind_param(1, $unconfirmed_id);
            $sth3->bind_param(2, $confirmation_id);
            $sth3->execute();
            $sth3->finish();
        }
        $sth2->finish();
        # send notification mail to possible quarantine users
        my $img_path = $g->{'cfg_template_dir'} . "/email";
        my $plain;
        my $html;
        my $date_string = localtime();

        # template object
        my $template = Template->new({
            INCLUDE_PATH => $g->{'cfg_template_dir'},
        });

        my $current_from = $quarantine_address . "\@" . $host_name;
        my $current_language = $self->language;
                    my %selected_language = ();

                    if (!$current_language || $current_language eq "")
                    {   
                        $current_language = "en";
                    }

                    if ($current_language eq "en")
                    {
                        %selected_language = %LimesGUI::I18N::en::quar_tmpl;
                    }
                    elsif ($current_language eq "de")
                    {
                        %selected_language = %LimesGUI::I18N::de::quar_tmpl;
                    }

        my $options = {
                recipient_address => $unconfirmed_mail,
                sender_address => $current_from,
                img_path => $img_path,
                date_string => $date_string,
                confirmation_id => $confirmation_id,
                language_strings => \%selected_language
        };

        $template->process($g->{'template_email_quarantine_confirmation_html'},$options,\$html);
        $template->process($g->{'template_email_quarantine_confirmation_plain'},$options,\$plain);


        my %attrs = ( charset => 'UTF-8' );

        my $email = Email::MIME->create_html(
                    header => [
                    From => "$self->{'_sender_name'} <$current_from> ($host_name)",
                            To => $unconfirmed_mail,
                            Subject => $selected_language{'quar_confirmation_subject'},
                        ],
                        attributes => \%attrs,
                        body_attributes => \%attrs,
                        text_body_attributes => \%attrs,
                        body => Encode::encode_utf8($html),
                        text_body => Encode::encode_utf8($plain),
                    );

        # send notification mail to possible quarantine users
	sendmail($email);

        # update confirmation counter for the user
        my $sth3 = undef;
        if ($confirmation_counter == 0)
        {
            $confirmation_counter++;
            $sth3 = $dbh->prepare("UPDATE maddr SET confirmation_counter = $confirmation_counter,first_confirmation = NOW() WHERE id = ?");
            $sth3->bind_param(1, $unconfirmed_id);
            $sth3->execute();
            $sth3->finish();
        }
        
    }
    $dbh->disconnect() ;

}

##This not function is not used ,
#we tought about having a function that sends a notification with a new generated confirmation_Id
#may be for futur use

sub notify_recipient_with_new_confirmation_Id($)
{
    my $self = instance(shift);
    my $dbh = $self->db_connect(); 
    my $host_name = `hostname -f`;
    my $quarantine_address = get_quarantine_address_from_map();
    my $unconfirmed_mail = shift;
    my $unconfirmed_domain = undef;
    if ($unconfirmed_mail =~ /\@(.*)$/)
    {   
        $unconfirmed_domain = $1;
    }
    #First we locate the recipient inside the maddr and we get the confirmation counter
    my $unconf = $dbh->prepare("SELECT * FROM maddr WHERE email =?");
    $unconf->bind_param(1, $unconfirmed_mail);
    $unconf->execute();
    
    my $ref = $unconf->fetchrow_hashref();
    $unconf->finish();
    my $confirmation_counter = $ref->{'confirmation_counter'};
    my $unconfirmed_id = $ref->{'id'};
    my $domain_state = confirm_domain($self->{'_domain_map'}, $unconfirmed_domain);
    if ($domain_state == 1)
    {   
    #create secret confirmation id
        my $confirmation_id = substr(md5_base64(rand(100)), 0, 12);
        my $sth3 = $dbh->prepare("INSERT INTO confirmation (maddr_id,confirmation_id) VALUES (?,?)");
        $sth3->bind_param(1, $unconfirmed_id);
        $sth3->bind_param(2, $confirmation_id);
        $sth3->execute();
        $sth3->finish();

        # send notification mail to possible quarantine users
        my $img_path = $g->{'cfg_template_dir'} . "/email";
        my $plain;
        my $html;
        my $date_string = localtime();

        # template object
        my $template = Template->new({
            INCLUDE_PATH => $g->{'cfg_template_dir'},
        });

        my $current_from = $quarantine_address . "\@" . $host_name;
        my $current_language = $self->language;
                    my %selected_language = ();

                    if (!$current_language || $current_language eq "")
                    {   
                        $current_language = "en";
                    }

                    if ($current_language eq "en")
                    {
                        %selected_language = %LimesGUI::I18N::en::quar_tmpl;
                    }
                    elsif ($current_language eq "de")
                    {
                        %selected_language = %LimesGUI::I18N::de::quar_tmpl;
                    }

        my $options = {
                recipient_address => $unconfirmed_mail,
                sender_address => $current_from,
                img_path => $img_path,
                date_string => $date_string,
                confirmation_id => $confirmation_id,
                language_strings => \%selected_language
        };

        $template->process($g->{'template_email_quarantine_confirmation_html'},$options,\$html);
        $template->process($g->{'template_email_quarantine_confirmation_plain'},$options,\$plain);


        my %attrs = ( charset => 'UTF-8' );

        my $email = Email::MIME->create_html(
                    header => [
                    From => "$self->{'_sender_name'} <$current_from> ($host_name)",
                            To => $unconfirmed_mail,
                            Subject => $selected_language{'quar_confirmation_subject'},
                        ],
                        attributes => \%attrs,
                        body_attributes => \%attrs,
                        text_body_attributes => \%attrs,
                        body => Encode::encode_utf8($html),
                        text_body => Encode::encode_utf8($plain),
                    );

        # send notification mail to possible quarantine users
	sendmail($email);

        # update confirmation counter for the user
        my $sth2 = undef;
        if ($confirmation_counter == 0)
        {
            $confirmation_counter++;
            $sth2 = $dbh->prepare("UPDATE maddr SET confirmation_counter = $confirmation_counter,first_confirmation = NOW() WHERE id = ?");
            $sth2->bind_param(1, $unconfirmed_id);
            $sth2->execute();
            $sth2->finish();
        }
        
    }
    $dbh->disconnect() ;

}

sub release_mail($$)
{   
    my $self = instance(shift);
    my $dbh = $self->db_connect();

    my $email = shift;
    my $mail_id = shift;

    my $sth = $dbh->prepare("SELECT quar_loc FROM msgs WHERE mail_id=?");
    $sth->bind_param(1, $mail_id);
    my $rows = $sth->execute();
    if ($rows == 1)
    {   
        #quarantined item found
        my $ref = $sth->fetchrow_hashref();
        try
        {   

            my $result = safe_system($g->{'cmd_amavis_release'}. " " .$ref->{'quar_loc'}) ;
            #mark for deletion, real deletion is done by cleanup cron
            my $sth1 = $dbh->prepare("UPDATE msgrcpt SET rs='1', ds='1' WHERE mail_id=?");
            $sth1->bind_param(1, $mail_id);
            $rows = $sth1->execute();
            $sth1->finish();
        }
        catch Underground8::Exception::Execution with
        {
         return 1;
        }


    }
    $sth->finish();
    $dbh->disconnect();

}

sub delete_all_mails($)
{
    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $email = shift;
    my $sth = $dbh->prepare("SELECT id FROM maddr WHERE email = ?");
    $sth->bind_param(1,$email);
    my $rowss  = $sth->execute();
    my $ref = $sth->fetchrow_hashref();
    my $maddr_id = $ref->{'id'};
    my $sth1 = $dbh->prepare("UPDATE msgrcpt SET ds ='1' WHERE rid=? AND (ds='D' OR ds='B')");
    $sth1->bind_param(1, $maddr_id);
    my $rows = $sth1->execute();
    $sth1->finish();
    if ($rows > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
    $dbh->disconnect();

}


sub delete_mail($$)
{   
    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $email = shift;
    my $mail_id = shift;
    #get maddr_id from email
    my $sth = $dbh->prepare("SELECT id FROM maddr WHERE email = ?");
    $sth->bind_param(1,$email);
    my $rowss  = $sth->execute();
    my $ref = $sth->fetchrow_hashref();
    my $maddr_id = $ref->{'id'};
    #mark the message
    my $sth1 = $dbh->prepare("UPDATE msgrcpt SET ds ='1' WHERE mail_id=?");
    $sth1->bind_param(1, $mail_id);
    my $rows = $sth1->execute();
    $sth1->finish();
    if ($rows == 1)
    {
        return 1;
    }
    else
    {
        return 0;
    }
    $dbh->disconnect();
}


sub toggle_quarantine_recipient ($$)
{   

    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $decision = shift;
    my $email = shift;
    #we find the confirmation id by recipient email 
    if($decision  == 0)
    {
        my $sth = $dbh->prepare("UPDATE users SET policy_id=( SELECT id FROM policy WHERE policy_name='DEFAULTQOFF') WHERE email=?");
        $sth->bind_param(1, $email);
        my $rows = $sth->execute();
        $sth->finish();
    }elsif($decision == 1){
        # first we check if the quarantiny state was time out, i.e equal to 2  
        my $sth1 =  $dbh->prepare("SELECT id,quarantiny FROM maddr WHERE email = ?");
        $sth1->bind_param(1, $email);
        my $nb = $sth1->execute();
        if ( $nb>0 )
        {
            my $ref = $sth1->fetchrow_hashref();
            if($ref->{'quarantiny'} == 2) 
            {

                my $maddr_id = $ref->{'id'};

                my $sth5 = $dbh->prepare("SELECT confirmation_id, maddr_id FROM confirmation WHERE maddr_id = ?");
                $sth5->bind_param(1, $maddr_id);
                my $rows5 = $sth5->execute();

                if ($rows5 == 0)
                {
                        #generate a new one
                        my $confirmation_id = substr(md5_base64(rand(100)), 0, 12);
                        my $sth6 = $dbh->prepare("INSERT INTO confirmation (maddr_id,confirmation_id) VALUES (?,?)");
                        $sth6->bind_param(1, $maddr_id);
                        $sth6->bind_param(2, $confirmation_id);
                        $sth6->execute();
                        $sth6->finish();
                }

                $sth5->finish(); 

                my $sth3 = $dbh->prepare("UPDATE maddr SET quarantiny = ? WHERE email=?");
                $sth3->bind_param(1, 1);
                $sth3->bind_param(2, $email);
                $sth3->execute();
                $sth3->finish();
            } 
        }
        # we update the policy_id field 
        my $sth = $dbh->prepare("UPDATE users SET policy_id=( SELECT id FROM policy WHERE policy_name='DEFAULTQON') WHERE email=?");
        $sth->bind_param(1, $email);
        my $rows = $sth->execute();
        $sth->finish();
    }


    $dbh->disconnect() ;
    $self->change();
}

#returns the lists of recipient's quarantined items 
sub recipient_mails($)
{
    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $email = shift;

    my $sth = $dbh->prepare("SELECT * FROM maddr WHERE email = ?");
    $sth->bind_param(1,$email);
    my $rowss  = $sth->execute();
    my $ref = $sth->fetchrow_hashref();
    my $maddr_id = $ref->{'id'};
    my $sth2 = $dbh->prepare("SELECT mail_id,ds,rs FROM msgrcpt WHERE rid = ? AND (((ds = ?) OR (ds = ?)) OR (rs =1))");
    $sth2->bind_param(1, $maddr_id);
    $sth2->bind_param(2, 'D');
    $sth2->bind_param(3, 'B');
    my $rows = $sth2->execute();
    my @quarantined_messages = ();
    while (my $ref2 = $sth2->fetchrow_hashref())
    {
        my $mail_id = $ref2->{'mail_id'};
        my $sth3 = $dbh->prepare("SELECT from_addr,subject,time_iso,quar_loc,content FROM msgs WHERE mail_id = ? AND quar_type = 'Q'");
        $sth3->bind_param(1, $mail_id);
        $sth3->execute();
        my $ref3 = $sth3->fetchrow_hashref();
        my $subject = $ref3->{'subject'};
        my $from_addr = $ref3->{'from_addr'};
        my $time_iso = $ref3->{'time_iso'};
        my $released= $ref2->{'ds'};
        my $mail_type= $ref3->{'content'};
        my %message = (
                date => $time_iso,
                from => $from_addr,
                subject => $subject,
                mail_id => $mail_id ,
                released => $released,
                mail_type => $mail_type,
            );
			print STDERR "mail tyoe is :>".$message{'mail_type'}."<\n";
         if(defined $ref3->{'quar_loc'}){ push(@quarantined_messages, \%message);}
        $sth3->finish();
    }
    $sth->finish();
    $sth2->finish();

    return (scalar @quarantined_messages > 0) ? \@quarantined_messages : undef  ;
    $dbh->disconnect();
}

#this function sets the values of *_quarantine_to in the MYSQL DB to the appropriate values depending on the quarantine state,
#the functions gets called on every Enable/Disable of the quarantine
#If Q is off && quarantine_admin is given then we update it
#If Q is on we set back to a normal string that is not an email
#
sub update_sql_quarantine_location($$)
{
    my $self = instance(shift);
    my $dbh = $self->db_connect();
    my $admin_boxes=shift;
    my $mails_destiny= shift;
    my $sth;
    foreach my $key (keys %$mails_destiny)
    {
        my $quarantine_to =$key;
        $quarantine_to =~ s/destiny/quarantine_to/;
        my $dest_QON = $key;
        #deciding the destination either '*-quarantine' for SQL , 'somemail@somedomain' if admin mailbox or '' if Throw away
        
        if($mails_destiny->{$key}==2)  {
            $dest_QON =~ s/_destiny/-quarantine/; 
        }
        elsif($mails_destiny->{$key}==1)  { 
            $dest_QON =~ s/destiny/box/;
            $dest_QON = $admin_boxes->{$dest_QON}; 
        }
        else {
            $dest_QON = '';
        }
        # writing to DB for User with Quarantine Enabled
        $sth = $dbh->prepare("UPDATE policy SET $quarantine_to = ? where id=1");
        $sth->bind_param(1, $dest_QON);
        $sth->execute();
    }
    $sth->finish() if defined $sth;
    $dbh->disconnect();
}

sub update_quarantine_whitelist($@){
	my $self = instance(shift);
	my @wl_domains = @_;

	my $wl = "";
	foreach my $wl_d (@wl_domains) {
		$wl = $wl . $wl_d . ",";
	}

	$self->{'_whitelisted_domains'} = $wl;
	$self->change;
}

sub update_quarantine_domains($$$)
{
    my $self = instance(shift);
    my $domain = shift;
    my $domain_enabled = shift;
    my $available_domains = shift;

    if (!defined $domain_enabled) {
       $domain_enabled = "no";
    }

    my @domains;
    if (defined $self->{'_whitelisted_domains'}) {
        @domains = split(',',$self->{'_whitelisted_domains'});
    }

    if (!($domain eq "all")) {
        my $found = 0;
        my $cnt = 0;
        foreach my $d (@domains) {
            if ($d eq $domain) {
                $found = 1;
                last;
            }
            $cnt++;
        }

        if ($domain_enabled eq "yes") {
            if (!$found) {
                push(@domains, $domain);
            }
        } elsif ($domain_enabled eq "no") {
            if ($found) {
                splice(@domains, $cnt, 1);
            }
        }
    } else {
        if ($domain_enabled eq "yes") {
                @domains = "";
                foreach my $key (keys %$available_domains) {
                        push(@domains, $key);
                }
        } elsif ($domain_enabled eq "no") {
                @domains = "";
        }
    }
    my $new_domains = "";
    foreach my $d (@domains) {
        $new_domains = $new_domains . $d . ",";
    }
    $self->{'_whitelisted_domains'} = $new_domains;
    $self->change;
}

##DB methods :

sub db_connect ()
{
    my $self = instance(shift);
    # connect to database
    my $dsn = "DBI:mysql:$self->{'_db_name'}:$self->{'_db_host'};mysql_server_prepare=0";
    my $_dbh = DBI->connect($dsn, $self->{'_db_user'}, $self->{'_db_password'}, {
                RaiseError => 0,
                AutoCommit => 1,
                mysql_auto_reconnect => 1,
                });
    unless ($_dbh)  {warn "Error while connecting: $DBI::errstr\nTrying Again...\n"; return $self->db_connect();}
    return $_dbh;
}


sub commit
{
    my $self = shift;
    my $files;
    push @{$files}, $g->{'file_quarantine_ng_conf'};
    my $md5_first = $self->create_md5_sums($files);

    $self->slave->write_config(
    $self->{'_listen_port'} ,
    $self->{'_db_name'}  ,
    $self->{'_db_host'}  ,
    $self->{'_db_user'}  ,
    $self->{'_db_password'}  ,
    $self->{'_listen_address'}  ,
    $self->{'_quarantine_path'} ,
    $self->{'_quarantine_enabled'} ,
    $self->{'_send_notifications_enabled'} ,
    $self->{'_send_reports_enabled'} ,
    $self->{'_domain_map'} ,
    $self->{'_language'}  ,
    $self->{'_check_sender'}  ,
    $self->{'_max_confirm_retries'} ,
    $self->{'_max_confirm_interval'} ,
    $self->{'_max_quarantine_size'} ,
    $self->{'_global_item_lifetime'} ,
    $self->{'_user_item_lifetime'} ,
    $self->{'_sender_name'},
    $self->{'_sizelimit_address'},
    $self->{'_show_virus'},
    $self->{'_show_banned'},
    $self->{'_show_spam'},
    $self->{'_hide_links_virus'},
    $self->{'_hide_links_banned'},
    $self->{'_hide_links_spam'},
    $self->{'_notify_unconfirmees_interval'} ,
    $self->{'_send_spamreport_interval'},
    $self->{'_whitelisted_domains'}
    );

    my $md5_second = $self->create_md5_sums($files);

    if ($self->compare_md5_hashes($md5_first, $md5_second))
    {
        $self->slave->service_restart();
    }

    $self->unchange;
}

##override of import_params



1;

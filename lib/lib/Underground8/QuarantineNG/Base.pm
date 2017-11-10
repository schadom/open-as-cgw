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


package Underground8::QuarantineNG::Base;

use Underground8::QuarantineNG::Common;
use Underground8::Utils;
use Underground8::Exception::MySQLScoreMaps;
use DBI;
require Exporter;
use Digest::MD5 qw(md5_base64);
use Email::MIME::CreateHTML;
use Email::Sender::Simple qw(sendmail);
use Template;
use DateTime;
use DateTime::Format::Strptime;
use Data::Dumper;
use Encode;

BEGIN
{
    if ($ENV{'LIMESGUI'})
    {
        push @INC, "$ENV{'LIMESGUI'}/lib";
    }
    else
    {
        push @INC, '/var/www/LimesGUI';
    }
}

use LimesGUI::I18N::en;
use LimesGUI::I18N::de;

use strict;
use warnings;

use constant USER_UNCONFIRMED => 0;
use constant USER_CONFIRMED => 1;
use constant USER_TIMEOUT => 2;

our @ISA = qw(Exporter);
our @EXPORT = qw(base_init base_destroy 
                add_user get_userid_from_confirmationid 
                activate_quarantine deactivate_quarantine 
                release_message delete_message delete_day 
                get_report send_all_reports delete_all_messages check_quarantinystate 
                set_timeouts notify_unconfirmees
                cleanup_unconfirmees cleanup_releases_deletions cleanup_old_quarantines cleanup_old_unconfirmed_quarantines
                read_policy_scores
                update_policy_score 
                update_policy_scores
                );

#### vars ####
my $dbh = undef;
my $conf = undef;
my $quarantine_address = undef;
my $amavisd_release_location = "/usr/sbin/amavisd-release";
my $host_name = `hostname -f`;

### functions ####
# connect to database
sub base_init
{
    $quarantine_address = get_quarantine_address_from_map();
    my $config = shift;
    my $access_success = 0;
    while (!$access_success)
    {
        $access_success = 1;
        if((!$dbh) and $config)
        {   
            my $dsn = "DBI:mysql:$config->{'db_name'}:$config->{'db_host'};mysql_server_prepare=0";
            $dbh = DBI->connect($dsn, $config->{'db_user'}, $config->{'db_password'}, {
                    RaiseError => 0,
                    AutoCommit => 1,
                    mysql_auto_reconnect => 1,
                    })
                or $access_success = 0; #die "Error while connecting to database: $DBI::errstr\n";
            $conf = $config;
            if ($access_success == 0)
            {
                sleep 5;
            }
        }
    }
}

# disconnect from database
sub base_destroy
{   
    if ($dbh)
    {   
        $dbh->disconnect() or warn "Error while disconnecting: $DBI::errstr\n";
    }
}

# confirm unknown user 
sub add_user
{
    my $confirmation_id = shift;
    my $ret = undef;
    my $user_email = undef;
    my $quarantine_sender_name = $conf->{'sender_name'};
    my $check_sender = $conf->{'check_sender'};
    my $given_sender = shift;

    my $sth = $dbh->prepare("SELECT id,email FROM maddr WHERE " .
        "first_confirmation > DATE_SUB(NOW(), INTERVAL ? DAY) AND " .
        "id = (SELECT maddr_id FROM confirmation WHERE confirmation_id = ?) AND quarantiny = '0'");
    $sth->bind_param(1, $conf->{'max_confirm_interval'});
    $sth->bind_param(2, $confirmation_id);

    my $rows = $sth->execute();

    if ($rows > 0)
    {
        # there is one user
        # TODO error handling

        my $ref = $sth->fetchrow_hashref();
        $user_email = $ref->{'email'};

        # sender mail check
        if ($check_sender && $user_email ne $given_sender)
        {
            log_message("err", "add_user -> given sender-address $given_sender does not correspond the database-sender-address");
            return 0;
        }

        my $sth2 = $dbh->prepare("INSERT INTO users (email) VALUES (?)");
        $sth2->bind_param(1, $ref->{'email'});
        my $rows = $sth2->execute();

        my $sth3 = $dbh->prepare("SELECT id FROM users WHERE email = ?");
        $sth3->bind_param(1, $ref->{'email'});
        $sth3->execute();
        my $tmp = $sth3->fetchrow_hashref();
        my $user_id = $tmp->{'id'};
        $sth3->finish();

        my $sth1 = $dbh->prepare("UPDATE maddr SET quarantiny = ? WHERE id = ?");
        $sth1->bind_param(1, USER_CONFIRMED);
        $sth1->bind_param(2, $ref->{'id'});
        $sth1->execute();
        $sth1->finish();

        #TODO check what this was standing for??? $dbh->do("DELETE FROM confirmation WHERE confirmation_id = '$confirmation_id'");
        
        $ret = $user_id;
    }
    else
    {
        my $sth4 = $dbh->prepare("SELECT id FROM maddr WHERE id = (SELECT maddr_id FROM confirmation WHERE confirmation_id = ?) AND quarantiny = ?");
        $sth4->bind_param(1, $confirmation_id);
        $sth4->bind_param(2, '2');
        my $rows4 = $sth4->execute();
        my $ref4 = $sth4->fetchrow_hashref();
        $sth4->finish();

        if ($rows4 > 0)
        {
                my $sth5 = $dbh->prepare("UPDATE maddr SET quarantiny = ? WHERE id = ?");
                $sth5->bind_param(1, USER_CONFIRMED);
                $sth5->bind_param(2, $ref4->{'id'});
                $sth5->execute();
                $sth5->finish();
                log_message("debug", "reset quarantiny for timed out user"); 
        }

        # no user
        log_message("debug", "No maddr-entry for given ID $confirmation_id with date_sub\n");

    }

    $sth->finish();
    return($ret);
}

# activate users quarantine
sub activate_quarantine
{
    my $confirmation_id = shift;

    my $given_sender = shift;
    my $check_sender = $conf->{'check_sender'};
    my $user_id = get_userid_from_confirmationid($confirmation_id);

    my $user_email = undef;

    if (defined($user_id))
    {
        my $sth2 = $dbh->prepare("SELECT email FROM users WHERE id = ?");
        $sth2->bind_param(1, $user_id);
        my $rows2 = $sth2->execute();
        #my $quarantine_sender_name = $conf->{'sender_name'};

        if ($rows2 > 0)
        {
            my $ref2 = $sth2->fetchrow_hashref();
            $user_email = $ref2->{'email'};

            # sender mail check
            if ($check_sender && $user_email ne $given_sender)
            {
                log_message("err", "activate_quarantine -> given sender-address $given_sender does not correspond the database-sender-address");
                return 0;
            }

        }
        else
        {
            log_message("err", "Email not found");
        }
        $sth2->finish(); 

        my $sth = $dbh->prepare("UPDATE users SET policy_id = (SELECT id FROM policy WHERE policy_name = 'DEFAULTQON') WHERE id = ?");
        $sth->bind_param(1, $user_id);
        my $rows = $sth->execute();
        $sth->finish();

        if ($rows == 1)
        {
            log_message("debug", "activation of quarantine succeeded");

            send_user_mail($user_email, $confirmation_id, "quar_activate_subject", "template_email_quarantine_activate", undef);

            return 1;
        }
        else
        {
            log_message("debug", "activation of quarantine failed");
            return 0;
        }
   }
}

sub send_user_mail
{

    my $user_email = shift;
    my $confirmation_id = shift;
    my $current_subject = shift;
    my $current_template = shift;
    my $quarantined_messages = shift;

    $user_email =~ /.+@(.+)/;
    my $mail_domain = $1;
    if (!check_domain_whitelist($mail_domain, $conf->{'whitelisted_domains'}))
    {
        log_message("debug", "Recipient address not in whitelist, not sending report.");
        return 0;
    }

    # send command mail to quarantine users
    my $img_path = $g->{'cfg_template_dir'} . "/email";
    my $plain;
    my $html;
    my $date_string = localtime();
    my $quarantine_sender_name = $conf->{'sender_name'};

    # template object
    my $template = Template->new({
        INCLUDE_PATH => $g->{'cfg_template_dir'},
    });

    my $current_from = $quarantine_address . "\@" . $host_name;

    my $current_language = $conf->{'language'};
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
        show_virus => $conf->{'show_virus'},
        show_banned => $conf->{'show_banned'},
        show_spam => $conf->{'show_spam'},
        hide_links_virus => $conf->{'hide_links_virus'},
        hide_links_banned => $conf->{'hide_links_banned'},
        hide_links_spam => $conf->{'hide_links_spam'},
        recipient_address => $user_email,
        sender_address => $current_from,
        img_path => $img_path,
        date_string => $date_string,
        confirmation_id => $confirmation_id,
        language_strings => \%selected_language,
        quarantined_messages => $quarantined_messages
    };

    my $html_template_error = 0;
    my $plain_template_error = 0;
    $template->process($g->{$current_template . '_html'},$options,\$html) or $html_template_error = 1;
    if ($html_template_error == 1)
    {
        log_message("err", "html_template_error: $template->error()");
        return 0;
    }

    $template->process($g->{$current_template . '_plain'},$options,\$plain) or $plain_template_error = 1;
    if ($plain_template_error == 1)
    {
        log_message("err", "plain_template_error: $template->error()");
        return 0;
    }

    my %attrs = ( charset => 'UTF-8' );

    my $email = Email::MIME->create_html(
        header => [
            From => "$quarantine_sender_name <$current_from> ($host_name)",
            To => $user_email,
            Subject => $selected_language{$current_subject},
        ],
        attributes => \%attrs,
        body_attributes => \%attrs,
        text_body_attributes => \%attrs,
        body => Encode::encode_utf8($html),
        text_body => Encode::encode_utf8($plain),
    );

    # send notification mail to possible quarantine users
    sendmail($email);
}

# deactivate users quarantine
sub deactivate_quarantine
{
    my $confirmation_id = shift;

    my $check_sender = $conf->{'check_sender'};
    my $given_sender = shift;

    my $user_id = get_userid_from_confirmationid($confirmation_id);

    my $user_email = undef;

    if (defined($user_id))
    {

        my $sth2 = $dbh->prepare("SELECT email FROM users WHERE id = ?");
        $sth2->bind_param(1, $user_id);
        my $rows2 = $sth2->execute();
        #my $quarantine_sender_name = $conf->{'sender_name'};

        if ($rows2 > 0)
        {
            my $ref2 = $sth2->fetchrow_hashref();
            $user_email = $ref2->{'email'};

            # sender mail check
            if ($check_sender && $user_email ne $given_sender)
            {
                log_message("err", "deactivate_quarantine -> given sender-address $given_sender does not correspond the database-sender-address");
                return 0;
            } 

        }
        else
        {
            log_message("err", "Email not found");
        }
        $sth2->finish();

        my $sth = $dbh->prepare("UPDATE users SET policy_id = ( SELECT id FROM policy WHERE policy_name = 'DEFAULTQOFF') WHERE id = ?");
        $sth->bind_param(1, $user_id);
        my $rows = $sth->execute();
        $sth->finish();

        if ($rows == 1)
        {
            log_message("debug", "deactivation of quarantine succeeded");
          
            send_user_mail($user_email, $confirmation_id, "quar_disabled_subject", "template_email_quarantine_disabled", undef);

            return 1;
        }
        else
        {
            log_message("debug", "deactivation if quarantine failed");
            return 0;
        }
    }
    else
    {
        log_message("err", "no user-id found for $confirmation_id");
        return 0;
    }
}

# get user_id from confirmation_id
sub get_userid_from_confirmationid
{
    my $confirmation_id = shift;
    
    if (defined($confirmation_id))
    {
        my $sth = $dbh->prepare("SELECT maddr_id FROM confirmation WHERE confirmation_id = ?");
        $sth->bind_param(1, $confirmation_id); 
        my $rows = $sth->execute();
        my $maddr_id = undef;
        if ($rows > 0)
        { 
            my $ref = $sth->fetchrow_hashref();
            $maddr_id = $ref->{'maddr_id'};
        }
        $sth->finish();

        my $sth2 = $dbh->prepare("SELECT email FROM maddr WHERE id = ?");
        $sth2->bind_param(1, $maddr_id);
        $rows = $sth2->execute();
        my $email = undef;
        if ($rows > 0)
        {
            my $ref = $sth2->fetchrow_hashref();
            $email = $ref->{'email'};
        } 
        $sth2->finish();

        my $sth3 = $dbh->prepare("SELECT id FROM users WHERE email = ?");
        $sth3->bind_param(1, $email);
        $rows = $sth3->execute();
        my $user_id = undef;
        if ($rows > 0)
        {
            my $ref = $sth3->fetchrow_hashref();
            $user_id = $ref->{'id'};
        }
        $sth3->finish;

        log_message("debug", "returning user-id $user_id for confirmation-id $confirmation_id");
        return $user_id;
    }
    else
    {
        log_message("err", "given confirmation-id was undefined");
        return undef;
    }
}

# release quarantined message
sub release_message
{   
    my ($mail_id, $confirmation_id, $given_sender) = @_;
    my $check_sender = $conf->{'check_sender'};

    my $sth2 = $dbh->prepare("SELECT id,email FROM maddr WHERE id = (SELECT maddr_id FROM confirmation WHERE confirmation_id = ?)");
    $sth2->bind_param(1, $confirmation_id);
    my $rows = $sth2->execute();
    my $ref2 = $sth2->fetchrow_hashref();
    if ($rows == 1)
    {

        # check sender
        my $user_email = $ref2->{'email'};
        if ($check_sender && $user_email ne $given_sender)
        {
            log_message("err", "release_message -> given sender-address $given_sender does not correspond the database-sender-address");
            return 0;
        }

        my $sth = $dbh->prepare("SELECT quar_loc FROM msgs WHERE mail_id = ?");
        $sth->bind_param(1, $mail_id);
        $rows = $sth->execute();

        if ($rows == 1)
        {
            # quarantined item found
            my $ref = $sth->fetchrow_hashref();
            my $result = `$amavisd_release_location $ref->{'quar_loc'} $ref2->{'email'} 2>&1`;
            if ($? != 0)
            {
                log_message("err", "problem executing amavisd-release: $!\n");
                return 0;
            }
            else
            {
                # mark for deletion if last recipient, real deletion is done by cleanup cron
                my $sth1 = $dbh->prepare("UPDATE msgrcpt SET rs = '1',ds = '1' WHERE mail_id = ? AND rid = ?");
                $sth1->bind_param(1, $mail_id);
                $sth1->bind_param(2, $ref2->{'id'});
                $rows = $sth1->execute();
                $sth1->finish();

                if ($rows == 1)
                {
                    chomp($result);
                    log_message("info", "$mail_id released - release-result $result");
                    return 1;
                }
                else
                {
                    log_message("err", "$mail_id released but database deletion-update failed");
                    return 0;
                }
            }

            $sth->finish();

        }
        else
        {
            log_message("debug", "no quarantined item found");
            return 0;
        }
        
        
    }
    
    $sth2->finish();
}

# delete a quarantined message
sub delete_message
{
    my ($mail_id, $confirmation_id, $given_sender) = @_;
    my $check_sender = $conf->{'check_sender'};

    my $sth3 = $dbh->prepare("SELECT maddr_id FROM confirmation WHERE confirmation_id = ?");
    $sth3->bind_param(1, $confirmation_id);
    my $rows3 = $sth3->execute();
    my $maddr_id = undef;
    if ($rows3 > 0)
    {   
        my $ref3 = $sth3->fetchrow_hashref();
        $maddr_id = $ref3->{'maddr_id'};
    }
    $sth3->finish();

    my $sth2 = $dbh->prepare("SELECT id,email FROM maddr WHERE id = (SELECT maddr_id FROM confirmation WHERE confirmation_id = ?)");
    $sth2->bind_param(1, $confirmation_id);
    my $rows = $sth2->execute();
    my $ref2 = $sth2->fetchrow_hashref();
    if ($rows == 1)
    {

        # check sender
        my $user_email = $ref2->{'email'};
        if ($check_sender && $user_email ne $given_sender)
        {
            log_message("err", "delete_message -> given sender-address $given_sender does not correspond the database-sender-address");
            return 0;
        } 

        my $sth = $dbh->prepare("SELECT mail_id FROM msgs WHERE mail_id = ?");
        $sth->bind_param(1, $mail_id);
        my $row_count = $sth->execute();
        $sth->finish();

        if ($row_count == 1)
        {
            # only mark for deletion, real deletion is done by cleanup script
            my $sth1 = $dbh->prepare("UPDATE msgrcpt SET ds = '1' WHERE mail_id = ? AND rid = ?");
            $sth1->bind_param(1, $mail_id);
            $sth1->bind_param(2, $maddr_id);
            $rows = $sth1->execute();
            $sth1->finish();
            if ($rows == 1)
            {
                log_message("info", "$mail_id marked for deletion");   
                return 1;
            }
            else
            {
                log_message("err", "$mail_id deleted but database deletion-update failed");
                return 0;
            }
        }
        else
        {   
            log_message("debug", "no quarantined item found");
            return 0;
        }
    }

    $sth2->finish();
}

# delete messages for given day 
sub delete_day
{
    my ($temp_date, $confirmation_id, $given_sender) = @_;

    my $check_sender = $conf->{'check_sender'};

    $temp_date =~ /st(.*)/;
    my $date = $1;

    my $sth3 = $dbh->prepare("SELECT maddr_id FROM confirmation WHERE confirmation_id = ?");
    $sth3->bind_param(1, $confirmation_id);
    my $rows3 = $sth3->execute();
    my $maddr_id = undef;
    if ($rows3 > 0)
    {   
        my $ref3 = $sth3->fetchrow_hashref();
        $maddr_id = $ref3->{'maddr_id'};
    }
    else
    {
        log_message("err", "maddr_id not found for confirmation_id $confirmation_id");
        $sth3->finish();
        return 0;
    }
    $sth3->finish();

    my $sth5 = $dbh->prepare("SELECT email FROM maddr WHERE id = ?");
    $sth5->bind_param(1, $maddr_id);
    my $rows5 = $sth5->execute();
    my $user_email = undef;
    if ($rows5 > 0)
    {
        my $ref5 = $sth5->fetchrow_hashref();
        $user_email = $ref5->{'email'};
    }
    $sth5->finish();

    # check sender
    if ($check_sender && $user_email ne $given_sender)
    {
        log_message("err", "delete_day -> given sender-address $given_sender does not correspond the database-sender-address");
        return 0;
    } 

    my $sth2 = $dbh->prepare("SELECT mail_id FROM msgrcpt WHERE rid = ? AND (ds = ? OR ds = ?)");
    $sth2->bind_param(1, $maddr_id);
    $sth2->bind_param(2, 'D');
    $sth2->bind_param(3, 'B');
    my $rows = $sth2->execute();
    if ($rows >= 1)
    {
        while (my $ref2 = $sth2->fetchrow_hashref())
        {
            my $mail_id = $ref2->{'mail_id'};
            my $sth4 = $dbh->prepare("SELECT time_iso FROM msgs WHERE mail_id = ?");
            $sth4->bind_param(1, $mail_id);
            my $rows4 = $sth4->execute();
            if ($rows4 >= 1)
            {
                my $ref4 = $sth4->fetchrow_hashref();
                my $time_iso = $ref4->{'time_iso'};
                my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );
                my $dt = $parser->parse_datetime($time_iso);
                my $date_temp = $dt->strftime("%d.%m.%Y");
                if ($date_temp eq $date)
                {
                    delete_message($mail_id, $confirmation_id, $given_sender);
                    log_message("info", "deletion mark for message_id $mail_id and confirmation_id $confirmation_id");
                }
            }
            $sth4->finish();
        } 
    }

    $sth2->finish();
}
# returns a report of quarantined elements to the user
sub get_report
{
    my $confirmation_id = shift;
    my $get_all_caller = shift;
    my $given_sender = shift;
    
    my $check_sender = $conf->{'check_sender'};
 
    my $single_flag = 1;

    # different between call from send_all_reports and single get_report call for empty-report-handling
    if (defined($get_all_caller))
    {
        $single_flag = $get_all_caller;
    }

    if (defined($confirmation_id))
    {
        my $user_id = get_userid_from_confirmationid($confirmation_id);

        if (defined($user_id))
        {
            my $sth4 = $dbh->prepare("SELECT email FROM users WHERE id = ?");
            $sth4->bind_param(1, $user_id);
            my $rows4 = $sth4->execute();
            my $user_email = undef;
            my $quarantine_sender_name = $conf->{'sender_name'};

            if ($rows4 > 0)
            {
                my $ref4 = $sth4->fetchrow_hashref();
                $user_email = $ref4->{'email'};
            }
            else
            {
                log_message("err", "Email not found");
            }
           
            # check sender
            if ($single_flag)
            {
                if ($check_sender && $user_email ne $given_sender)
                {
                    log_message("err", "get_report -> given sender-address $given_sender does not correspond the database-sender-address");
                    return 0;
                }
            } 
 
            $sth4->finish();

            my $sth = $dbh->prepare("SELECT maddr_id FROM confirmation WHERE confirmation_id = ?");
            $sth->bind_param(1, $confirmation_id);
            my $rows = $sth->execute();
            my $date_string = localtime();
            # template object
            my $template = Template->new({
                INCLUDE_PATH => $g->{'cfg_template_dir'},
            });

            my $maddr_id = undef;
            if ($rows > 0)
            {
                my $ref = $sth->fetchrow_hashref();
                $maddr_id = $ref->{'maddr_id'};



                # avoid sending report to deactivated users
                my $sth9 = $dbh->prepare("SELECT quarantiny FROM maddr WHERE id = ?");
                $sth9->bind_param(1, $maddr_id);
                my $rows9 = $sth9->execute();
                my $ref9 = $sth9->fetchrow_hashref();
                my $current_quarantiny_state = $ref9->{'quarantiny'};
                $sth9->finish();
                if ($current_quarantiny_state == 2 && !$single_flag)
                {
                    log_message("debug", "not sending report to deactivated users");
                    return 0;
                }



                my $sth2 = $dbh->prepare("SELECT mail_id FROM msgrcpt WHERE rid = ? AND (ds = ? OR ds = ?)");
                $sth2->bind_param(1, $maddr_id);
                $sth2->bind_param(2, 'D');
                $sth2->bind_param(3, 'B');
                $rows = $sth2->execute();
                my $current_from = $quarantine_address . "\@" . $host_name;

                my $img_path = $g->{'cfg_template_dir'} . "/email";
                my $plain;
                my $html;
                my %quarantined_messages = ();
                my $msg_cnt = 0;

                while (my $ref2 = $sth2->fetchrow_hashref())
                {
                    my $mail_id = $ref2->{'mail_id'};
                    my $sth3 = $dbh->prepare("SELECT from_addr,subject,time_iso,content,spam_level FROM msgs WHERE mail_id = ? AND quar_type = ?");
                    $sth3->bind_param(1, $mail_id);
                    $sth3->bind_param(2, 'Q');
                    my $rows3 = $sth3->execute();
                    if ($rows3 == 1)
                    {
                        my $ref3 = $sth3->fetchrow_hashref();
                        my $plain_from = $ref3->{'from_addr'};

                        my $current_addr = $plain_from;

                        if ($plain_from =~ m/.*<.*>.*/)
                        {
                                $plain_from =~ /\<(.*)\>/;
                                $current_addr = $1;
                        }

                        my $from_addr = substr $current_addr, 0, 35;

                        my $subject = substr Encode::decode_utf8($ref3->{'subject'}), 0, 50;
                        my $time_iso = $ref3->{'time_iso'};
                        my $quar_type = $ref3->{'content'};
                        my $spam_level = $ref3->{'spam_level'};
						
						#round the spam score to only one digit after the comma
						$spam_level = (int($spam_level * 10))/10;

                        my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );
                        my $dt = $parser->parse_datetime($time_iso);
                        my $now = DateTime->today();
                        my $now_subtract = $now->clone()->subtract( days => 1 );

                        my $prefix = "";
                        if ($dt->ymd eq $now->ymd)
                        {
                            $prefix = "Today, ";
                        }
                        elsif ($dt->ymd eq $now_subtract->ymd)
                        {
                            $prefix = "Yesterday, ";
                        }

                        my $date_temp = $dt->strftime("%d.%m.%Y");
                        my $time_temp = $dt->strftime("%H:%M:%S");

                        my $date_plain = $dt->strftime("%Y%m%d");

                        my %message = (
                            date => $time_temp,
                            from => $from_addr,
                            subject => $subject,
                            confirmation_id => $confirmation_id,
                            mail_id => $mail_id,
                            quar_type => $quar_type,
                            spam_level => $spam_level
                        ); 
                        push(@{$quarantined_messages{$date_plain}}, \%message);
                        $msg_cnt++;
                        $sth3->finish();
                        log_message("debug", "confirmation_id = $confirmation_id - mail_id = $mail_id -> date = $time_iso - type = $quar_type - subject = $subject - from_addr = $from_addr");
                    }
                }

                my $message_count = $msg_cnt;
                log_message("debug", "current message-count to send in quarantine-report is $message_count - single_flag = $single_flag - user_email = $user_email");

                # automatically send mail only if there are messages available or the user explicitly requested the report
                if ($message_count > 0 || $single_flag)
                {

                    send_user_mail($user_email, $confirmation_id, "quar_report_subject", "template_email_quarantine_report", \%quarantined_messages);
                    
                }
                else
                {
                    log_message("debug", "not sending empty report in send_all mode");
                }

                $sth2->finish();
                $sth->finish();
            }
        }
        else
        {
            log_message("debug", "no user_id found for $confirmation_id");
            return 0;
        }
    }
    else
    {
        log_message("err", "given confirmation-id was undefined");
        return 0;
    }
}

sub send_all_reports
{
    
    my $cf = shift;

    base_init($cf);

    my $sth = $dbh->prepare("SELECT confirmation.confirmation_id from users,maddr,confirmation WHERE users.email = maddr.email AND maddr.id = confirmation.maddr_id;");
    my $rows = $sth->execute();
    if ($rows > 0)
    {
        while (my $ref = $sth->fetchrow_hashref())
        {
           my $confirmation_id = $ref->{'confirmation_id'};
           # set single_flag to false due to send_all call
           get_report($confirmation_id, 0, undef); 
        }
    }

    $sth->finish();
    
    base_destroy();
}

# delete all quarantined messages for a user
sub delete_all_messages
{
    my $confirmation_id = shift;

    my $check_sender = $conf->{'check_sender'};
    my $given_sender = shift;
    
    if (defined($confirmation_id))
    {

        my $user_id = get_userid_from_confirmationid($confirmation_id);

        if (defined($user_id))
        {
            my $sth4 = $dbh->prepare("SELECT email FROM users WHERE id = ?");
            $sth4->bind_param(1, $user_id);
            my $rows4 = $sth4->execute();
            my $user_email = undef;

            if ($rows4 > 0)
            {
                my $ref4 = $sth4->fetchrow_hashref();
                $user_email = $ref4->{'email'};

                # sender mail check
                if ($check_sender && $user_email ne $given_sender)
                {
                    log_message("err", "delete_all_messages -> delete_all_messages -> given sender-address $given_sender does not correspond the database-sender-address");
                    return 0;
                }

            }
            else
            {
                log_message("err", "Email not found");
            }

            $sth4->finish();
        } 
        else
        {
            log_message("debug", "no user_id found for $confirmation_id");
            return 0;
        }

        my $sth = $dbh->prepare("SELECT maddr_id FROM confirmation WHERE confirmation_id = ?");
        $sth->bind_param(1, $confirmation_id);
        my $rows = $sth->execute();

        my $maddr_id = undef;
        if ($rows > 0)
        {
            my $ref = $sth->fetchrow_hashref();
            my $maddr_id = $ref->{'maddr_id'};
            my $sth2 = $dbh->prepare("SELECT mail_id FROM msgrcpt WHERE rid = ? AND (ds = ? OR ds = ?)");
            $sth2->bind_param(1, $maddr_id);
            $sth2->bind_param(2, 'D');
            $sth2->bind_param(3, 'B');
            $rows = $sth2->execute(); 

            while (my $ref2 = $sth2->fetchrow_hashref())
            {
                my $mail_id = $ref2->{'mail_id'};
                my $sth3 = $dbh->prepare("UPDATE msgrcpt SET ds = '1' WHERE mail_id = ? AND rid = ?");
                $sth3->bind_param(1, $mail_id);
                $sth3->bind_param(2, $maddr_id);
                $sth3->execute();
                $sth3->finish();
                log_message("debug", "marked $mail_id for deletion");
            }

            $sth2->finish();
            $sth->finish();
        }
        else
        {
            log_message("err", "no maddr-entry for given confirmation $confirmation_id found");
            return 0;
        }
    }
    else
    {
        log_message("err", "given confirmation-id was undefined");
        return 0;
    }
}

# check for possible quarantinies
#TODO: check the sense of this function and if needed any more
sub check_quarantinystate
{
    # TODO: save/get last Id of check run
    my $sth = $dbh->prepare("SELECT id,email FROM maddr WHERE quarantiny = ?");
    $sth->bind_param(1, '0');
    $sth->execute();
    while(my $ref = $sth->fetchrow_hashref())
    {
        my $unconfirmed_id = $ref->{'id'};
        my $unconfirmed_mail = $ref->{'email'};
        my $unconfirmed_domain = undef;        

        if ($ref->{'email'} =~ /@(.*)$/)
        {
            $unconfirmed_domain = $1;
        }
        else
        {
            # TODO error handling
        }

        my $domain_state = confirm_domain($conf->{'domain_map'}, $unconfirmed_domain, $conf->{'whitelisted_domains'});
        if ($domain_state == 1)
        {
            my $sth2 = $dbh->prepare("UPDATE maddr SET quarantiny = ? WHERE id = ?");
            $sth2->bind_param(1, '1');
            $sth2->bind_param(2, $unconfirmed_id);
            $sth2->execute();
            $sth2->finish();
        }
        else
        {
            # TODO error handling
        }
    }
    $sth->finish();
}

# check for timeouts of quarantinies
sub set_timeouts
{

    my $cf = shift;

    base_init($cf);

    my $sth = $dbh->prepare("SELECT id,email FROM maddr WHERE quarantiny = ? AND confirmation_counter > ? AND first_confirmation <> '0000-00-00 00:00:00' AND first_confirmation <= DATE_SUB(NOW(), INTERVAL ? DAY)");
    $sth->bind_param(1, '0');
    $sth->bind_param(2, $conf->{'max_confirm_retries'});
    $sth->bind_param(3, $conf->{'max_confirm_interval'});
    $sth->execute();

    while (my $ref = $sth->fetchrow_hashref())
    {   
        #TODO: insert user
        my $sth3 = $dbh->prepare("INSERT INTO users (email, policy_id) VALUES (?,?)");
        $sth3->bind_param(1, $ref->{'email'});
        $sth3->bind_param(2, "2");
        my $rows3 = $sth3->execute();
        $sth3->finish();

        my $current_id = $ref->{'id'};
        my $sth2 = $dbh->prepare("UPDATE maddr SET quarantiny = ? WHERE id = ?");
        $sth2->bind_param(1, '2');
        $sth2->bind_param(2, $current_id);
        $sth2->execute();
        $sth2->finish();
        log_message("debug", "set timeout for $current_id");

        if ($conf->{'send_notifications'})
        {
            send_user_mail($ref->{'email'}, undef, "quar_deactivate_subject", "template_email_quarantine_deactivate", undef);
        }

    }

    $sth->finish();

    base_destroy();

}

# send notifications to unconfirmed users to confirm themselves
#TODO: check this for correct behaviour with single id generation now
sub notify_unconfirmees
{  
    my $cf = shift;

    base_init($cf);

    my $quarantine_sender_name = $conf->{'sender_name'};

    # get all unconfirmed 
    my $sth = $dbh->prepare("SELECT id,email,confirmation_counter FROM maddr WHERE quarantiny = ? AND confirmation_counter <= ? AND email <> ''");
    $sth->bind_param(1, USER_UNCONFIRMED);
    $sth->bind_param(2, $conf->{'max_confirm_retries'});
    $sth->execute();

    while (my $ref = $sth->fetchrow_hashref())
    {   
        my $unconfirmed_id = $ref->{'id'};
        my $unconfirmed_mail = $ref->{'email'};
        my $unconfirmed_domain = undef;
        if ($ref->{'email'} =~ /\@(.*)$/)
        {
            $unconfirmed_domain = $1;
        }
        else
        {
            log_message("err", "domain extraction failed for $ref->{'email'}");
            return 0;
        }
 
        my $confirmation_counter = $ref->{'confirmation_counter'};

        my $confirmation_id = undef;
        # create only one confirmation id
        if ($confirmation_counter == 0)
        {
            my $domain_state = confirm_domain($conf->{'domain_map'}, $unconfirmed_domain, $conf->{'whitelisted_domains'});
            if ($domain_state == 1)
            {
                # create secret confirmation id
                $confirmation_id = substr(md5_base64(rand(100)), 0, 12);
                my $sth3 = $dbh->prepare("INSERT INTO confirmation (maddr_id,confirmation_id) VALUES (?,?)"); 
                $sth3->bind_param(1, $unconfirmed_id);
                $sth3->bind_param(2, $confirmation_id);
                $sth3->execute();
                $sth3->finish();

            }
            else
            {
                log_message("debug", "domain '$unconfirmed_domain' confirmed with $domain_state and so is unconfirmed");
                next;
            }
        }
        else
        {
            my $sth4 = $dbh->prepare("SELECT confirmation_id FROM confirmation WHERE maddr_id = ?");
            $sth4->bind_param(1, $ref->{'id'});
            $sth4->execute();
            my $ref4 = $sth4->fetchrow_hashref();
            $confirmation_id = $ref4->{'confirmation_id'};
            $sth4->finish();
        }

        log_message("debug", "sending notification to $unconfirmed_mail");

        send_user_mail($unconfirmed_mail, $confirmation_id, "quar_confirmation_subject", "template_email_quarantine_confirmation", undef);

        # update confirmation counter for the user
        my $sth2 = undef;
        if ($confirmation_counter == 0)
        {
            $confirmation_counter++;
            $sth2 = $dbh->prepare("UPDATE maddr SET confirmation_counter = $confirmation_counter,first_confirmation = NOW() WHERE id = ?");
        }
        else
        {
            $confirmation_counter++;
            $sth2 = $dbh->prepare("UPDATE maddr SET confirmation_counter = $confirmation_counter WHERE id = ?");
        }

        log_message("debug", "Unconfirmed id: $unconfirmed_id\n");
        $sth2->bind_param(1, $unconfirmed_id);
        $sth2->execute();
        $sth2->finish();
    }
    
    $sth->finish();
    
    base_destroy();

}

# cleanup quarantines of unconfirmed users which are timed out 
sub cleanup_unconfirmees
{   

    my $cf = shift;

    base_init($cf);

    my $sth = $dbh->prepare("SELECT id FROM maddr WHERE quarantiny = ?");
    $sth->bind_param(1, '2');
    $sth->execute();

    while (my $ref = $sth->fetchrow_hashref())
    {
        my $sth2 = $dbh->prepare("SELECT mail_id,ds FROM msgrcpt WHERE rid = ?");
        $sth2->bind_param(1, $ref->{'id'});
        $sth2->execute();

        while (my $ref2 = $sth2->fetchrow_hashref())
        {
            ##my $ds = $ref2->{'ds'};

            # do not use mails in "Passed" state
            ##if ($ds ne "P")
            ##{
            ##    my $sth3 = $dbh->prepare("DELETE FROM quarantine WHERE mail_id = ?");
            ##    $sth3->bind_param(1, $ref2->{'mail_id'});
            ##    my $rows3 = $sth3->execute();

            ##    if ($rows3 > 0)
            ##    {
            ##        log_message("info", "mail_id $ref2->{'mail_id'} successfully deleted from quarantine table");
            ##    }
            ##    else
            ##    {
            ##        log_message("err", "deletion of mail_id $ref2->{'mail_id'} from quarantine table failed");
            ##    } 

            ##    $sth3->finish();
            ##}

            # delete msg entries for user in database
            ##my $sth4 = $dbh->prepare("DELETE FROM msgs WHERE mail_id = ?");
            ##$sth4->bind_param(1, $ref2->{'mail_id'});
            ##$sth4->execute();
            ##$sth4->finish();
            
            ##log_message("debug", "cleanup_unconfirmees message $ref2->{'mail_id'}");

        }

        # delete msgrcpt entries for user in database
        ##my $sth5 = $dbh->prepare("DELETE FROM msgrcpt WHERE rid = ?");
        ##$sth5->bind_param(1, $ref->{'id'});
        ##$sth5->execute();

        ##$sth5->finish();
        ##$sth2->finish();

        #my $sth6 = $dbh->prepare("DELETE FROM maddr WHERE id = ?");
        #$sth6->bind_param(1, $ref->{'id'});
        #$sth6->execute();
   
        #$sth6->finish(); 

        # delete confirmation entries for user cleaned up user in database
        my $sth7 = $dbh->prepare("DELETE FROM confirmation WHERE maddr_id = ?");
        $sth7->bind_param(1, $ref->{'id'});
        $sth7->execute();
        $sth7->finish();

        log_message("debug", "cleanup_unconfirmees from database $ref->{'id'}");

        #my $sth8 = $dbh->prepare("SELECT confirmation_id FROM confirmation WHERE maddr_id = ?");
        #$sth8->bind_param(1, $ref->{'id'});
        #$sth8->execute();
        #my $ref3 = $sth8->fetchrow_hashref();
        #my $current_confirmation_id = $ref3->{'confirmation_id'};
        #$sth8->finish();
        #deactivate_quarantine($current_confirmation_id);
    }
   
    $sth->finish();

    base_destroy();

}

# cleanup released/deleted messages from database and filesystem
sub cleanup_releases_deletions
{

    my $cf = shift;

    base_init($cf);

    my $sth = $dbh->prepare("SELECT mail_id FROM msgrcpt WHERE rs = ? OR ds = ?");
    $sth->bind_param(1, '1');
    $sth->bind_param(2, '1');
    my $rows = $sth->execute();

    if ($rows > 0)
    {
        while (my $ref = $sth->fetchrow_hashref())
        {
            my $sth2 = $dbh->prepare("SELECT quar_loc FROM msgs WHERE mail_id = ?");
            $sth2->bind_param(1, $ref->{'mail_id'});
            my $rows2 = $sth2->execute();
            my $ref2 = $sth2->fetchrow_hashref();
            my $quarantine_location = $ref2->{'quar_loc'};
          
            my $sth5 = $dbh->prepare("SELECT rid FROM msgrcpt WHERE mail_id = ?");
            $sth5->bind_param(1, $ref->{'mail_id'});
            my $rows5 = $sth5->execute();
            $sth5->finish(); 

            my $sth6 = $dbh->prepare("SELECT rid FROM msgrcpt WHERE mail_id = ? AND ds = ?");
            $sth6->bind_param(1, $ref->{'mail_id'});
            $sth6->bind_param(2, '1');
            my $rows6 = $sth6->execute();
            $sth6->finish();

            # only delete physically if there exists only one user that owns the message
            if ($rows5 == $rows6)
            { 
                # physically delete file
                my $sth6 = $dbh->prepare("DELETE FROM quarantine WHERE mail_id = ?");
                $sth6->bind_param(1, $ref->{'mail_id'});
                my $rows6 = $sth6->execute();

                if ($rows6 > 0)
                {
                    log_message("info", "mail_id $ref->{'mail_id'} successfully deleted from quarantine table");
                }
                else
                {
                    log_message("err", "deletion of mail_id $ref->{'mail_id'} from quarantine table failed");
                }

                $sth6->finish();

                # delete msg entries in database
                my $sth3 = $dbh->prepare("DELETE FROM msgs WHERE mail_id = ?");
                $sth3->bind_param(1, $ref->{'mail_id'});
                $sth3->execute();
                $sth3->finish();

                # delete msgrcpt entries in database
                my $sth4 = $dbh->prepare("DELETE FROM msgrcpt WHERE rs = ? AND mail_id = ?");
                $sth4->bind_param(1, '1');
                $sth4->execute();
                $sth4->finish();
            
            }

            $sth2->finish();

            log_message("debug", "cleanup_releases_deletions $ref->{'mail_id'}");

        }

                        
    }
    else
    {
        log_message("info", "No releases to cleanup");
    }
    
    $sth->finish();

    base_destroy();

}

# cleanup old quarantine messages from database and filesystem
sub cleanup_old_quarantines
{   

    my $cf = shift;

    base_init($cf);

    my $user_item_lifetime = $conf->{'user_item_lifetime'};
    my $sth = $dbh->prepare("SELECT msgs.mail_id, msgs.time_iso FROM msgrcpt, msgs WHERE msgrcpt.mail_id = msgs.mail_id AND (msgrcpt.ds = ? OR msgrcpt.ds = ?) AND msgs.time_iso <= DATE_SUB(NOW(),INTERVAL ? DAY) AND msgrcpt.rid IN (SELECT id FROM maddr WHERE quarantiny = ?)");
    $sth->bind_param(1, 'D');
    $sth->bind_param(2, 'B');
    $sth->bind_param(3, $user_item_lifetime);
    $sth->bind_param(4, '1');

    my $rows = $sth->execute();

    if ($rows > 0)
    {   
        while (my $ref = $sth->fetchrow_hashref())
        {   
            my $sth2 = $dbh->prepare("SELECT quar_loc FROM msgs WHERE mail_id = ?");
            $sth2->bind_param(1, $ref->{'mail_id'});
            my $rows2 = $sth2->execute();
            my $ref2 = $sth2->fetchrow_hashref();
            my $quarantine_location = $ref2->{'quar_loc'};
            
            # physically delete file
            if (defined($quarantine_location))
            {
                my $sth6 = $dbh->prepare("DELETE FROM quarantine WHERE mail_id = ?");
                $sth6->bind_param(1, $ref->{'mail_id'});
                my $rows6 = $sth6->execute();

                if ($rows6 > 0)
                {
                    log_message("info", "mail_id $ref->{'mail_id'} successfully deleted from quarantine table");
                }
                else
                {
                    log_message("err", "deletion of mail_id $ref->{'mail_id'} from quarantine table failed");
                }

                $sth6->finish();
            }

            # delete msgs in database
            my $sth3 = $dbh->prepare("DELETE FROM msgs WHERE mail_id = ?");
            $sth3->bind_param(1, $ref->{'mail_id'});
            $sth3->execute();
            $sth3->finish();

            # delete msgrcpt in database
            my $sth4 = $dbh->prepare("DELETE FROM msgrcpt WHERE rs = ? AND mail_id = ?");
            $sth4->bind_param(1, '1');
            $sth4->bind_param(2, $ref->{'mail_id'});
            $sth4->execute();
            $sth4->finish();

            $sth2->finish();

            log_message("debug", "cleanup_old_quarantines $ref->{'mail_id'}");

        }
        
    }
    else
    {   
        log_message("info", "No releases to cleanup");
    }

    $sth->finish();

    base_destroy();

}

# cleanup old unconfirmed quarantine messages from database and filesystem
sub cleanup_old_unconfirmed_quarantines
{   

    my $cf = shift;

    base_init($cf);

    my $global_item_lifetime = $conf->{'global_item_lifetime'};
    my $sth = $dbh->prepare("SELECT msgs.mail_id, msgs.time_iso FROM msgrcpt, msgs WHERE msgrcpt.mail_id = msgs.mail_id AND (msgrcpt.ds = ? OR msgrcpt.ds = ?) AND msgs.time_iso <= DATE_SUB(NOW(),INTERVAL ? DAY) AND msgrcpt.rid IN (SELECT id FROM maddr WHERE quarantiny = ?)");
    $sth->bind_param(1, 'D');
    $sth->bind_param(2, 'B');
    $sth->bind_param(3, $global_item_lifetime);
    $sth->bind_param(4, '2');

    my $rows = $sth->execute();

    if ($rows > 0)
    {   
        while (my $ref = $sth->fetchrow_hashref())
        {   
            my $sth2 = $dbh->prepare("SELECT quar_loc FROM msgs WHERE mail_id = ?");
            $sth2->bind_param(1, $ref->{'mail_id'});
            my $rows2 = $sth2->execute();
            my $ref2 = $sth2->fetchrow_hashref();
            my $quarantine_location = $ref2->{'quar_loc'};
            
            # physically delete file
            if (defined($quarantine_location))
            { 
                my $sth6 = $dbh->prepare("DELETE FROM quarantine WHERE mail_id = ?");
                $sth6->bind_param(1, $ref->{'mail_id'});
                my $rows6 = $sth6->execute();

                if ($rows6 > 0)
                {
                    log_message("info", "mail_id $ref->{'mail_id'} successfully deleted from quarantine table");
                }
                else
                {
                    log_message("err", "deletion of mail_id $ref->{'mail_id'} from quarantine table failed");
                }

                $sth6->finish();
            }

            # delete msgs in database
            my $sth3 = $dbh->prepare("DELETE FROM msgs WHERE mail_id = ?");
            $sth3->bind_param(1, $ref->{'mail_id'});
            $sth3->execute();
            $sth3->finish();

            # delete msgrcpt in database
            my $sth4 = $dbh->prepare("DELETE FROM msgrcpt WHERE rs = ? AND mail_id = ?");
            $sth4->bind_param(1, '1');
            $sth4->bind_param(2, $ref->{'mail_id'});
            $sth4->execute();
            $sth4->finish();

            $sth2->finish();

            log_message("debug", "cleanup_old_unconfirmed_quarantines $ref->{'mail_id'}");

        }
        
    }
    else
    {   
        log_message("info", "No releases to cleanup");
    }

    $sth->finish();

    base_destroy();

}

#read policy scores ...

#@param : policy name
sub read_policy_scores ($)
{
    my $policy_name= shift;
    my $pol = $dbh->prepare("SELECT pol FROM policy WHERE policy_name = ?");
    $pol->bind_param(1,$policy_name);
    $pol->execute();
    my $ref= $pol->fetchrow_hashref();
    return ($ref->spam_tag2_level,$ref->spam_kill_level,$ref->spam_quarantine_cutoff_level,$ref->spam_dsn_cutoff_level); 
}

##
#update specified score for the given policy.
#
#@params : policy_name, score to change, new value for this score.
sub update_policy_score($$$)
{
    base_init(read_quarantine_config);
    my $policy_name = shift;
    my $score = shift;
    my $value = shift;
    my $pol = $dbh->prepare("UPDATE policy SET $score=? WHERE policy_name=?");
        $pol->bind_param(1, $value);
        $pol->bind_param(2,$policy_name);
    $pol->execute();
    base_destroy();
}

#update all scores for some policy
#
#@params : policy_name, reference to a hash of the new scores,quarantine_enabled 
sub update_policy_scores($$$$$)
{
    my $cred = shift;
    my $policy_name = shift;
    my $score_hash = shift;
    my $quarantine_enabled = shift; # this value is equal to Service::QuarantineNG->mails_destiny->{'spam_destiny'}
    my $quarantine_admin = shift; # this value is equal to Service::QuarantineNG->admin_boxes->{'spam_box'}
    my $translate ={  # the score names on the template and those in data structure(Amavis.pm) are not the same, so we need translation..
       'tag' => 'spam_tag2_level',
       'block' => 'spam_kill_level' ,
       'dsn' => 'spam_dsn_cutoff_level',
       'cutoff' => 'spam_quarantine_cutoff_level'
       }; 
    foreach my $score (keys %$score_hash)
    {   
        my $dsn = "DBI:mysql:database=amavis;host=localhost;mysql_server_prepare=1";
        my $dbhh = DBI->connect($dsn, $cred->{'username'}, $cred->{'password'}, {
                                    RaiseError => 1,
                                    AutoCommit => 1,
                                    });

        $dbhh->{'mysql_auto_reconnect'} = 1;
        my $new_val;
        ##Be aware that the scores that are written to DB can be different from those in configuration, the lines below test the quarantine state and write a diffenrent value for some cases.
      #if spam quarantine is enabled we write scores normaly , if some kill(block) score is null then we set it to be equal to the cutoff
      #if spam quarantine is disabled every kill becomes equal to cutoff score 
      #if spam quarantine is disabled and a quarantine_mail is given then we start sending to the quarantine email above the quarantine score

        $new_val=$score_hash->{$score};
        if($score eq 'block')
        {
            
            if($quarantine_enabled < 1 ||($quarantine_enabled ==2 &&  $score_hash->{'block'}==0) || $policy_name eq "DEFAULTQOFF")
            {
                $new_val=$score_hash->{'cutoff'};
            }
            
        }

        my $pol;
        if(defined $new_val && $new_val != 0) 
        {
            $pol = $dbhh->prepare("UPDATE policy SET $translate->{$score}=? WHERE policy_name = ?");
            $pol->bind_param(1, $new_val);
            $pol->bind_param(2,$policy_name);
        }
        else 
        {
            $pol = $dbhh->prepare("UPDATE policy SET $translate->{$score}=999999 WHERE policy_name = ?");
            $pol->bind_param(1,$policy_name);
        }
        $pol->execute or throw Underground8::Exception::MySQLScoreMaps;
        $pol->finish();
        $dbhh->disconnect() or warn "Error while disconnecting: $DBI::errstr\n";
    }
}

1;

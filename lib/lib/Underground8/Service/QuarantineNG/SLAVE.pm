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


package Underground8::Service::QuarantineNG::SLAVE;
use base Underground8::Service::SLAVE;
use Template;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Utils;

use strict;
use warnings;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('quarantineNG');
    return $self;
}

sub write_config
{
    my $self = instance(shift);

    my $listen_port = shift ;
    my $db_name = shift ; 
    my $db_host = shift  ;
    my $db_user = shift ;  
    my $db_password = shift ;
    my $listen_address = shift ;
    my $quarantine_path = shift ;
    my $quarantine_enabled = shift ;
    my $send_notifications_enabled = shift ;
    my $send_reports_enabled = shift ;
    my $domain_map = shift ;
    my $language = shift ;
    my $check_sender = shift ;
    my $max_confirm_retries = shift ;
    my $max_confirm_interval = shift ;
    my $max_quarantine_size = shift ;
    my $global_item_lifetime = shift ;
    my $user_item_lifetime = shift ;
    my $sender_name = shift ;
    my $sizelimit_address = shift ;
    my $show_virus = shift ;
    my $show_banned = shift ;
    my $show_spam = shift ;
    my $hide_links_virus = shift ;
    my $hide_links_banned = shift ;
    my $hide_links_spam = shift ;
    my $notify_unconfirmees_interval = shift;
    my $send_spamreport_interval = shift;
    my $whitelisted_domains = shift;
    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 

    my @keys = ("min" , "h" , "d_of_m","month","d_of_w");
     
    my $options = {
    listen_port => $listen_port ,
    db_name => $db_name ,
    db_host => $db_host ,
    db_user => $db_user ,
    db_password => $db_password ,
    listen_address => $listen_address ,
    quarantine_path => $quarantine_path ,
    quarantine_enabled => $quarantine_enabled ,
    send_notifications_enabled => $send_notifications_enabled ,
    send_reports_enabled => $send_reports_enabled ,
    domain_map => $domain_map ,
    language => $language ,
    check_sender  => $check_sender ,
    max_confirm_retries => $max_confirm_retries ,
    max_confirm_interval => $max_confirm_interval ,
    max_quarantine_size => $max_quarantine_size ,
    global_item_lifetime => $global_item_lifetime ,
    user_item_lifetime => $user_item_lifetime ,
    sender_name => $sender_name ,
    sizelimit_address => $sizelimit_address,
    show_virus => $show_virus ,
    show_banned => $show_banned ,
    show_spam => $show_spam ,
    hide_links_virus => $hide_links_virus ,
    hide_links_banned => $hide_links_banned ,
    hide_links_spam => $hide_links_spam ,
    notify_unconfirmees_interval => _append($notify_unconfirmees_interval,@keys),
    send_spamreport_interval =>_append($send_spamreport_interval,@keys ),
    whitelisted_domains => $whitelisted_domains
    };
    
    my $config_content;
    $template->process($g->{'template_quarantine_ng_conf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (QNG_LIMES,'>',$g->{'file_quarantine_ng_conf'})
        or throw Underground8::Exception::FileOpen($g->{'file_quarantine_ng_conf'});

    print QNG_LIMES $config_content;

    close (QNG_LIMES); 
}

sub service_restart ($)
{
    my $self = instance(shift);
    
    my $out1 = safe_system($g->{'cmd_quarantine_ng_restart'});
    my $out2 = safe_system($g->{'cmd_quarantine_cron_restart'});
}
 
sub _append 
{
    my $hash = shift;
    my @keyz =@_;
    my $str = " ";
    foreach my $k (@keyz)
    {
        $str= $str. " " .$hash->{$k}; 
    }
    return $str;
}

1;


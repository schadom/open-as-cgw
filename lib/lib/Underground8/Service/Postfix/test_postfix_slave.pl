#!/usr/bin/perl

# The following code uses the postfix slave module to configure postfix



BEGIN {
    my $homedir = (getpwuid($<))[7];
    unshift(@INC,"$homedir/devel/limesgui/trunk/limes-as/lib");
}


use Underground8::Service::Postfix::SLAVE;

use strict;
use warnings;

my $slave = new Underground8::Service::Postfix::SLAVE ();

my $config;
$config->{'strict_rfc281'} = 'yes';
$config->{'smtpd_banner'} = 'LimesAS Test';
$config->{'inet_protocols'} = 'ipv4';
$config->{'content_filter'} = 'smtp-amavis:[127.0.0.1]:10024';
$config->{'transport_maps'} = 'hash:/etc/postfix/transport';
$config->{'relay_domains'}->{'lol.at'}->{'dest_mailserver_addr'} = '1.2.3.4';
$config->{'relay_domains'}->{'lol.at'}->{'dest_mailserver_port'} = '25';
$config->{'relay_domains'}->{'lol.at'}->{'enabled'} = 'yes';
$config->{'relay_domains'}->{'pony.com'}->{'dest_mailserver_addr'} = 'host.lol.at';
$config->{'relay_domains'}->{'pony.com'}->{'dest_mailserver_port'} = '598';
$config->{'relay_domains'}->{'pony.com'}->{'enabled'} = 'no';
$config->{'smtpd_recipient_restrictions'}->[0] = 'permit_sasl_authenticated';
$config->{'smtpd_recipient_restrictions'}->[1] = 'permit_mynetworks';
$config->{'smtpd_recipient_restrictions'}->[2] = 'reject_unauth_destination';
$config->{'smtpd_recipient_restrictions'}->[3] = 'reject_non_fqdn_recipient';
$config->{'smtpd_recipient_restrictions'}->[4] = 'reject_unknown_sender_domain';
$config->{'smtpd_recipient_restrictions'}->[5] = 'check_policy_service inet:127.0.0.1:2501';
$config->{'smtpd_recipient_restrictions'}->[6] = 'permit';
$config->{'smtpd_sender_restrictions'}->[0] = 'permit_sasl_authenticated';
$config->{'smtpd_sender_restrictions'}->[1] = 'permit_mynetworks';
$config->{'smtpd_sender_restrictions'}->[2] = 'reject_non_fqdn_sender';
$config->{'smtpd_sender_restrictions'}->[3] = 'permit';
$config->{'biff'} = 'no';


$slave->write_postfix_config($config);

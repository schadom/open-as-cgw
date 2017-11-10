#!/usr/bin/perl
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



use strict;
use warnings;

use Error qw(:try);
use Underground8::Exception;
use Underground8::Exception::Execution;
use Underground8::Configuration::LimesAS::Antispam;
use Underground8::Appliance::LimesAS;
use Data::Dumper;

###########################################################



print "#" x 80 . "\n";
print "### LIMES AS DEFAULT SETTINGS" . " " x 48 . "###\n"; 
print "#" x 80 . "\n\n";

# prepare
my $appliance = new Underground8::Appliance::LimesAS;

$appliance->antispam->set_sqlgrey_mysql_password('loltruck2000');

### APPLIANCE ###
print "APPLIANCE SETTINGS\n";

    ## NETWORK ##
    print "\tNETWORK\n";
    
        # IP CONFIGURATION #
        print "\t\tApplying IP Settings...";
        $appliance->system->set_ip_address('10.2.0.1');
        $appliance->system->set_subnet_mask('255.255.255.0');
        $appliance->system->set_default_gateway('10.2.0.254');
        print "done.\n";

        # DNS CONFIGURATION #
        print "\t\tApplying DNS Settings...";
        $appliance->system->set_primary_dns('10.2.200.11');
        $appliance->system->set_secondary_dns('4.2.2.1');
        print "done.\n";

    ## SYSTEM ##
    print "\tSYSTEM\n";

        ## HOST / DOMAINNAME ##
        print "\t\tApplying Host/Domainname...";
        $appliance->system->set_hostname('antispam');

        $appliance->system->set_domainname('localdomain');
        print "done.\n";

    ## AUTHENTICATION ##
    print "\tAUTHENTICATION\n";

        ## USERS ##
        print "\t\tCreating user \"admin\" with password \"test\"...";
        $appliance->system->set_user_password('admin', 'test');
        print "done.\n";

    ## TIME ##
    print "\tTIME\n";

        ## TIMEZONE ##
        print "\t\tSetting timezone to \"Europe/Vienna\"...";
        $appliance->system->set_tz('Europe/Vienna');
        print "done.\n";
        print "\t\tInitializing timezones...";
        $appliance->system->initialize_timezones();
        print "done.\n";
        
        ## TIMESYNC ##
        print "\t\tSetting ntp servers...";
        $appliance->system->add_ntp_server('0.pool.ntp.org');
        $appliance->system->add_ntp_server('1.pool.ntp.org');
        $appliance->system->add_ntp_server('2.pool.ntp.org');
        $appliance->system->add_ntp_server('3.pool.ntp.org');
        print "done.\n";

print "\n";
### ANTISPAM ###
print "ANTISPAM SETTINGS\n";

    ## GENERAL ##           
    print "\tGENERAL\n";

        # SPAM SETTINGS #
        print "\t\tApplying Spam Settings...";
        $appliance->antispam->set_spam_admin('box-master@openas.org');
        $appliance->antispam->set_spam_subject_tag('** SPAM **');
        print "done.\n";

        # SMTP SETTINGS #
        print "\t\tApplying SMTP Settings...";
        $appliance->antispam->enable_sender_domain_verify();
        $appliance->antispam->enable_sender_fqdn_required();
        $appliance->antispam->enable_helo_required();
        $appliance->antispam->enable_rfc_strict();
        $appliance->antispam->set_smtpd_banner('L0LSMTP');
        $appliance->antispam->set_incoming_smtp_connection(50);
        $appliance->antispam->set_smtpd_timeout(30);
        print "done.\n";

        # ANTIVIRUS
        print "\t\tEnabling AntiVirus...";
        $appliance->antispam->enable_anti_virus();
        print "done.\n";

        # GREYLISTING
        print "\t\tEnabling Greylisting...";
        $appliance->antispam->enable_greylisting();
        print "done.\n";

    ## DOMAINS ##
    print "\tDOMAINS\n";

        # add one default domain
        print "\t\tAdding Default Domain...";
        $appliance->antispam->domain_create('domain.tld',
                                            '10.0.0.1',
                                            '25');
        
        $appliance->antispam->domain_create('stealth.kicks-ass.net',
                                            '10.2.200.63',
                                            '25');
        
        $appliance->antispam->domain_create('calimero',
                                            '10.2.200.63',
                                            '25');
        print "done.\n";

    ## IP BLACKLIST ##
    print "\tIP BLACKLIST\n";
        
        # enable
        $appliance->antispam->enable_ip_blacklisting();
        # add one entry
        print "\t\tAdding Default IP Blacklist Entry...";
        $appliance->antispam->create_blacklist_ip('6.6.6.6','Banned IP Address');
        #$appliance->antispam->create_blacklist_ip('10.2.200.10','Banned IP Address');
        print "done.\n";

    ## IP WHITELIST ##
    print "\tIP WHITELIST\n";
        
        # enable
        $appliance->antispam->enable_ip_whitelisting();
        # add one entry
        print "\t\tAdding Default IP Whitelist Entry...";
        $appliance->antispam->create_whitelist_ip('1.3.3.7','My Favourite IP Address');
        $appliance->antispam->create_whitelist_ip('10.2.200.137','dizzle lokal');
        $appliance->antispam->create_whitelist_ip('10.2.200.136','harri lokal');
        print "done.\n";

    ## EMAIL ADDRESS BLACKLIST ##
    print "\tEMAIL ADDRESS BLACKLIST\n";
        
        # enable
        $appliance->antispam->enable_addr_blacklisting();
        # add one entry
        print "\t\tAdding Default Email Address Blacklist Entry...";
        $appliance->antispam->create_blacklist_addr('death@hell.com','Banned Email Address');
        print "done.\n";

    ## EMAIL ADDRESS WHITELIST ##
    print "\tEMAIL ADDRESS WHITELIST\n";
        
        # enable
        $appliance->antispam->enable_addr_whitelisting();
        # add one entry
        print "\t\tAdding Default Email Address Whitelist Entry...";
        $appliance->antispam->create_whitelist_addr('god@heaven.com','Allowed Email Address');
        print "done.\n";


    ## ATTACHMENTS ##
    print "\tATTACHMENTS\n";

        # enable
        print "\t\tEnabling Warnings on Virus and Banned Files...";
        $appliance->antispam->enable_warn_recipient_virus();
        $appliance->antispam->enable_warn_recipient_banned_file();
        print "done.\n";

        print "\t\tSetting banned attachments...";
        $appliance->antispam->add_banned_attachments('exe','windows executable');
        $appliance->antispam->add_banned_attachments('dll','dynamic linked lybrary');
        $appliance->antispam->add_banned_attachments('com','executable program package');
        $appliance->antispam->add_banned_attachments('dat','batch file');
        $appliance->antispam->add_banned_attachments('bin','binary file');
        print "done.\n";
   ## Scores ##
   print "\tSCORES\n";
   print "\t\tSetting Scores...";
   $appliance->antispam->set_info_score(0);
   $appliance->antispam->set_spam_score(5);
   $appliance->antispam->set_block_score(50);
   print "done.\n";

   ### DNSRBLs ###
   print "\tDNSRBL\n";
   print "\t\tSetting RBL...";
   $appliance->antispam->disable_rbl_checks();
   print "done.\n";

   # SASLAUTHENTICATION
   print "\tSASL\n";
   print "\t\tDisabling SASL...";
   $appliance->antispam->disable_sasl();
   print "done.\n";

print "\n";

try {
    print "Commiting Settings...";
    $appliance->commit();
    print "done.\n";
}
catch Underground8::Exception::Execution with
{
    my $E = shift;
    print $E->{'-text'} . "\n";
    print $E->{'-output'} . "\n";
}
catch Underground8::Exception with
{
    my $E = shift;
    print $E->{'-text'} . "\n";
}

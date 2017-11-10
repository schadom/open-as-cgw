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
use Underground8::Configuration::LimesAS::Antispam;
use Underground8::Appliance::LimesAS;
use Underground8::Utils;
use Data::Dumper;

###########################################################

my $import_dir = $g->{'cfg_dir'};

print "#" x 80 . "\n";
print "### LIMES AS IMPORT SETTINGS" . " " x 49 . "###\n"; 
print "#" x 80 . "\n\n";
print "Using directory: $import_dir\n\n";

# prepare
my $appliance = new Underground8::Appliance::LimesAS;
$appliance->load_config();

### APPLIANCE ###
print "APPLIANCE SETTINGS\n";

    ## NETWORK ##
    print "\tNETWORK\n";
    
        # IP CONFIGURATION #
        print "\t\tIP Configuration\n";
        print "\t\t\tIP Address: " . $appliance->system->ip_address() . "\n";
        print "\t\t\tSubnet Mask: " . $appliance->system->subnet_mask() . "\n";
        print "\t\t\tDefault Gateway: " . $appliance->system->default_gateway() . "\n\n";

        # DNS CONFIGURATION #
        print "\t\tDNS Settings\n";
        print "\t\t\tPrimary DNS: " . $appliance->system->primary_dns() . "\n";
        print "\t\t\tSecondary DNS: " . $appliance->system->secondary_dns() . "\n\n";

    ## SYSTEM ##
    print "\tSYSTEM\n";

        ## HOST / DOMAINNAME ##
        print "\t\tHost/Domainname\n";
        print "\t\t\tHostname: " . $appliance->system->hostname() . "\n";
        print "\t\t\tDomainname: " . $appliance->system->domainname() . "\n\n";

print "\n";
### ANTISPAM ###
print "ANTISPAM SETTINGS\n";

    ## GENERAL ##           
    print "\tGENERAL\n";

        # SPAM SETTINGS #
        print "\t\tApplying Spam Settings...";
        $appliance->antispam->set_spam_admin('mp@underground8.com');
        $appliance->antispam->set_spam_subject_tag('** SPAM **');
        print "done.\n";

        # SMTP SETTINGS #
        print "\t\tApplying SMTP Settings...";
        $appliance->antispam->enable_sender_domain_verify();
        $appliance->antispam->enable_sender_fqdn_required();
        $appliance->antispam->enable_helo_required();
        $appliance->antispam->enable_rfc_strict();
        $appliance->antispam->set_smtpd_banner('L0LSMTP');
        print "done.\n";

        # ANTIVIRUS
        print "\t\tEnabling AntiVirus...";
        $appliance->antispam->enable_anti_virus();
        print "done.\n";

    ## DOMAINS ##
    print "\tDOMAINS\n";

        # add one default domain
        print "\t\tAdding Default Domain...";
        $appliance->antispam->domain_create('domain.tld',
                                            '10.0.0.1',
                                            '25');
        print "done.\n";

    ## IP BLACKLIST ##
    print "\tIP BLACKLIST\n";
        
        # enable
        $appliance->antispam->enable_ip_blacklisting();
        # add one entry
        print "\t\tAdding Default IP Blacklist Entry...";
        $appliance->antispam->create_blacklist_ip('6.6.6.6','Banned IP Address');
        print "done.\n";

    ## IP WHITELIST ##
    print "\tIP WHITELIST\n";
        
        # enable
        $appliance->antispam->enable_ip_whitelisting();
        # add one entry
        print "\t\tAdding Default IP Whitelist Entry...";
        $appliance->antispam->create_whitelist_ip('1.3.3.7','My Favourite IP Address');
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
    print "\tEMAIL ADDRESS BLACKLIST\n";
        
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


print "\n";

try {
}
catch Underground8::Exception with
{
    my $E = shift;
    print $E->{'-text'} . "\n";
}

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
use File::stat;

my $group = 'limes';
my $gid   = getgrnam($group);

my @files = qw(
/etc/environment
/etc/network/interfaces
/etc/postfix/main.cf
/etc/postfix/master.cf
/etc/postfix/transport
/etc/postfix/sasl/smtpd.conf 
/etc/resolv.conf
/etc/hosts
/etc/hostname
/etc/mailname
/etc/amavis/conf.d/15-av_scanners
/etc/amavis/conf.d/15-content_filter_mode
/etc/amavis/conf.d/20-debian_defaults
/etc/amavis/conf.d/99-openas
/etc/clamav/clamd.conf
/etc/clamav/freshclam.conf
/etc/kav/kav_server.conf
/etc/kav/kav_updater.conf
/etc/sambucus/main.cfg
/etc/sambucus/roles.cfg
/etc/sqlgrey/sqlgrey.conf
/etc/default/sqlgrey
/etc/postfix/main.cf
/etc/postfix/filter-dynip.pcre
/etc/postfix/amavis_bypass_filter
/etc/postfix/amavis_bypass_filter_smtpcrypt
/etc/postfix/amavis_bypass_accept
/etc/postfix/amavis_senderbypass_filter
/etc/postfix/amavis_senderbypass_accept
/etc/postfix/amavis_bypass_internal_filter
/etc/postfix/amavis_bypass_internal_warn
/etc/postfix/amavis_bypass_internal_accept
/etc/postfix/mynetworks
/etc/postfix/local_rcpt_map
/etc/postfix/mbox_transport
/etc/postfix/virtual_mbox
/etc/postfix/virtual_alias
/etc/postfix/usermaps
/etc/postfix/header_checks
/etc/postfix/postfwd.cf
/etc/default/postfwd
/etc/spamassassin/local.cf
/var/log/open-as-cgw/mail.log
/etc/localtime
/etc/ntp.conf
/var/lib/spamassassin/updates_spamassassin_org.cf
/usr/local/bin/firewall.sh
/etc/sasl.cf
/etc/mysql/my.cnf
/etc/monit/monitrc
/etc/default/monit
/etc/syslog-ng/conf.d/open-as-cgw.conf
/etc/logrotate.d/syslog-ng
/boot/grub/menu.lst
/etc/lsb-release
/etc/default/batv-filter
/etc/mail/batv-filter.relay
/etc/mail/batv-filter.domains
/etc/mail/batv-filter.key
/etc/open-as-cgw/xml/antispam.xml
/etc/open-as-cgw/xml/backup.exclude
/etc/open-as-cgw/xml/backup.include
/etc/open-as-cgw/xml/backup.xml
/etc/open-as-cgw/xml/notification.xml
/etc/open-as-cgw/xml/postfwd.xml
/etc/open-as-cgw/xml/quarantine.xml
/etc/open-as-cgw/xml/system.xml
/etc/open-as-cgw/xml/usermaps.xml
/etc/open-as-cgw/xml/smtpcrypt.xml
/etc/open-as-cgw/conf/as_license.ulf
/etc/default/snmpd
/etc/snmp/snmpd.conf
/var/log/open-as-cgw/LimesGUI.log
);

print "\n\nChanging file ownerships and permissions to read/write for group: $group\n";
print "-" x 75 . "\n";
foreach my $file (@files) {
    printf("File: %s\n",$file);
    chomp $file;
    unless (-e $file) {
        print "does not exist - creating directory and touching file\n";
        system("mkdir -p $1") if $file =~ /^(\/.+)\/.+?$/;
        system("touch $file");
    }

    my $info = stat($file) or die "$file does not exist!";
    unless (chown ($info->uid, $gid, $file)) {
        print "Failed to set ownership.\n";
    } # else { print "\tOwner: ".getpwuid($info->uid).".".getgrgid($info->gid)." --> ".getpwuid($info->uid).".".$group."\n"; }
    
    my $mode = $info->mode & 07777 | 48; # add read+write to group permissions
    unless (chmod ($mode,$file)) {
        print "Failed to set permissions.\n";
    } # else { printf("\tPermissions: %04o --> %04o\n",$info->mode & 07777, $mode); }
}

system("/bin/chmod 755 /usr/bin/sasl_auth.pl");
system("/bin/chown smtpcrypt:limes /etc/open-as-cgw/xml/smtpcrypt.xml");
system("/bin/chgrp limes /var/log/mail-simple*");

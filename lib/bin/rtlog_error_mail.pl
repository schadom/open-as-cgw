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



BEGIN { 
    my $homedir = (getpwuid($<))[7];
    unshift(@INC,"$homedir/devel/limesas/lib/trunk/lib");
}                                                                                                                            
 

use strict;
use warnings;

use Net::SMTP::TLS;
use File::Slurp;
use Underground8::Appliance::LimesAS;


my $dumpfile = "/var/log/open-as-cgw/rtlogd.dump";
my $snfile = "/etc/open-as-cgw/sn";
my $versionsfile = "/etc/open-as-cgw/versions";
my $address = "limesas\@underground8.com";

my $appliance = new Underground8::Appliance::LimesAS;
$appliance->load_config;

my $domainname = $appliance->system->domainname;
my $hostname = $appliance->system->hostname;
my $email_sender = "limesas\@$domainname"; 

my @mailer_options = (
    Hello => "$hostname.$domainname",
    NoTLS => 1,
    Debug => 1,
);

my @df_lines;

if (-e $dumpfile && -f $dumpfile)
{
    @df_lines = read_file($dumpfile);
}

my $sn;
if (-e $snfile && -f $snfile)
{
    $sn = read_file($snfile);
}

my @versions_lines;
if (-e $versionsfile && -f $versionsfile)
{
    @versions_lines = read_file($versionsfile);
}

my $mailer = new Net::SMTP::TLS("localhost",@mailer_options);
$mailer->mail($email_sender);
$mailer->to($address);
$mailer->data;        

$mailer->datasend("From: Limes Anti-Spam <$email_sender>\n");
$mailer->datasend("To: Limes Anti-Spam Team <$address>\n");
$mailer->datasend("Subject: rtlogd died on $hostname.$domainname\n\n");

$mailer->datasend("rtlogd died on $hostname.$domainname\n\n");
$mailer->datasend("sn: $sn\n");
foreach my $line (@versions_lines)
{
    $mailer->datasend("$line\n");
}
$mailer->datasend("Here's the Dump:\n\n");
foreach my $line (@df_lines)
{
    $mailer->datasend("$line\n");
}
$mailer->dataend();
$mailer->quit(); 

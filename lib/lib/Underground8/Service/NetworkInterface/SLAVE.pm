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


package Underground8::Service::NetworkInterface::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Time::Local;
use File::Temp qw/ tempfile /;
sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('networkinterface');
}

sub service_start ($)
{
    # network is never stopped, so why start it? :) 
}

sub service_stop ($)
{
    # you freak.
}

sub trigger_service_restart ($$)
{
    my $self = instance(shift);
    my $ifname = shift;
    system("$g->{'cmd_network_restart'} $ifname > /dev/null 2>&1 &");
}

sub service_restart ($$)
{
    my $self = instance(shift);
    my $ifname = shift;
    safe_system("$g->{'cmd_network_ifdown'} $ifname > /dev/null 2>&1");
    system("$g->{'cmd_network_route'} del default > /dev/null 2>&1");
    safe_system("$g->{'cmd_network_ifup'} $ifname > /dev/null 2>&1");
}

sub write_config ($$$$$)
{
    my $self = instance(shift);
    $self->write_network_config(@_);
}

sub revoke_crontab
{
    my $self = instance(shift);
    my $if_name = shift;
    my $flag = 0;
    my $temp = '';
    my $tmp_cronname = "crontab.$>.XXXXXX";
    my $start_marker = "#--start-revoke-network-settings:$if_name--\n";
    my $end_marker = "#--end-revoke-network-settings:$if_name--\n";
    my $fh = new File::Temp() or throw Underground8::Exception::CreateTmpFile("/tmp/");
    my $fname = $fh->filename;
    open CRON, ($g->{'cmd_crontab'} . " -l |")
    or throw Underground8::Exception::FileOpen(($g->{'cmd_crontab'} . " -l |"));
    while (<CRON>)
    {
        if (/$start_marker/)
        {
            $flag = 1;
            $temp .= $_;
        }
        elsif (/$end_marker/)
        {
            $flag = 0;
        }
        if ($flag == 0)
        {
           $temp .= $_; 
        }
    }
    close CRON;
    print $fh $temp;
    
    safe_system(($g->{'cmd_crontab'} . " $fname > /dev/null 2>&1"));
}

sub create_crontab ($$)
{
    my $self = instance(shift);
    my $if_name = shift;
    my $minute = ((localtime)[1] + 10) % 60;
    my $flag = 0;
    my $found = 0;
    my $temp = '';
    my $tmp_cronname = "crontab.$>.XXXXXX";
    my $start_marker = "#--start-revoke-network-settings:$if_name--\n";
    my $end_marker = "#--end-revoke-network-settings:$if_name--\n";
    my $fh = new File::Temp() or throw Underground8::Exception::CreateTmpFile("/tmp/");
    my $fname = $fh->filename;
    open CRON, ($g->{'cmd_crontab'} . " -l |")
    or throw Underground8::Exception::FileOpen(($g->{'cmd_crontab'} . " -l |"));
    while (<CRON>)
    {
        if (/$start_marker/)
        {
            $flag = 1;
            $found = 1;
            $temp .= $_;
            $temp .= qq~$minute * * * * ~ . $g->{'cmd_revoke_network_settings'} . qq~ > /dev/null 2>&1\n~;
        }
        elsif (/$end_marker/)
        {
            $flag = 0;
        }
        if ($flag == 0)
        {
           $temp .= $_; 
        }
    }
    if ($found == 0)
    {
        $temp .= "\n" . $start_marker . qq~$minute * * * * ~ . $g->{'cmd_revoke_network_settings'} . qq~\n~ . $end_marker;
    }
    close CRON;
    print $fh $temp;
    safe_system(($g->{'cmd_crontab'} . " " . "$fname > /dev/null 2>&1"));

}

sub restart_webserver
{
    my $self = instance(shift);
    safe_system($g->{'cmd_webserver_restart'});
}

sub write_network_config($$$$$)
{
    my $self = instance(shift);
    my $if_name = shift;
    my $if_ip_addr = shift;
    my $if_sn_mask = shift;
    my $if_def_gw = shift;
    my $primary_dns = shift;
    my $secondary_dns = shift;
    my $use_local_cache = shift;
    my $domainname = shift;

    my @interface_file;
    open (INTERFACES, '<', $g->{'file_networking_interfaces'})
        or throw Underground8::Exception::FileOpen($g->{'file_networking_interfaces'});
    
    my $start_marker = "#--start:$if_name--";
    my $end_marker = "#--end:$if_name--";

    my $skip = 0;
    while (my $line = <INTERFACES>)
    {
        #chomp($line);
        if ($line =~ m/$start_marker/)
        {
            $skip=1;
            push (@interface_file,$line);
            push (@interface_file,"auto $if_name\n");
            push (@interface_file,"iface $if_name inet static\n");
            push (@interface_file,"    address $if_ip_addr\n");
            push (@interface_file,"    netmask $if_sn_mask\n");
            push (@interface_file,"    gateway $if_def_gw\n");
            if ($use_local_cache) {
                push (@interface_file,"    dns-nameservers 127.0.0.1 $primary_dns $secondary_dns\n");
            } else {
                push (@interface_file,"    dns-nameservers $primary_dns $secondary_dns\n");
            }
            if ($domainname ne '') { push (@interface_file,"    dns-search $domainname\n"); }
               
        }
        elsif($line =~ m/$end_marker/)
        {
            $skip=0;
        }
       
        if ($skip == 0) 
        {
            push (@interface_file,$line);
        }
    }
     
    close(INTERFACES); 
    
    open (INTERFACES, '>', $g->{'file_networking_interfaces'})
        or throw Underground8::Exception::FileOpen($g->{'file_networking_interfaces'});
    
    while (my $line = shift(@interface_file))
    {
        print INTERFACES "$line";
    }
    
    close (INTERFACES);
}

1;

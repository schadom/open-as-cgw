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


package Underground8::Service::Iptables::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Error;
use Underground8::Utils;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Template;
use Data::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('iptables');
    return $self;
}

sub service_stop($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_iptables_stop'});
}

sub service_start($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_iptables_start'});
}

sub service_restart($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_iptables_stop'});
    $output = safe_system($g->{'cmd_iptables_start'});
}

sub write_config($$$$)
{
    my $self = instance(shift);
    my $if_name = shift;
    my $admin_range = shift;
	my $additional_ssh_port = shift;
	my $use_snmp = shift;

    my $template = Template->new (
	{
	    INCLUDE_PATH => $g->{'cfg_template_dir'},
	});  
    
    my $options = {
	admin_range => $admin_range,
        if_name => $if_name,
		additional_ssh_port => $additional_ssh_port,
		use_snmp => $use_snmp,
    };
    
    my $config_content;
    $template->process($g->{'template_firewall'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (FIREWALLCONF,'>',$g->{'file_firewall'})
        or throw Underground8::Exception::FileOpen($g->{'file_firewall'});

    print FIREWALLCONF $config_content;

    close (FIREWALLCONF);
}

sub revoke_crontab ($)
{
    my $self = instance(shift);
    my $flag = 0;
    my $temp = '';
    my $start_marker = "#--start-revoke-firewall-settings--\n";
    my $end_marker = "#--end-revoke-firewall-settings--\n";
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

sub create_crontab ($)
{
    my $self = instance(shift);
    my $minute = ((localtime)[1] + 10) % 60;
    my $flag = 0;
    my $found = 0;
    my $temp = '';
    my $start_marker = "#--start-revoke-firewall-settings--\n";
    my $end_marker = "#--end-revoke-firewall-settings--\n";
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
            $temp .= qq~$minute * * * * ~ . $g->{'cmd_revoke_firewall_settings'} . qq~ > /dev/null 2>&1\n~;
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
        $temp .= "\n" . $start_marker . qq~$minute * * * * ~ . $g->{'cmd_revoke_firewall_settings'} . qq~\n~ . $end_marker;
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


1;

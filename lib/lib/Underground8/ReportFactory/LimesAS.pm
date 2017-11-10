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


package Underground8::ReportFactory::LimesAS;
use base Underground8::ReportFactory;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Report::LimesAS::Sysinfo;
use Underground8::Report::LimesAS::Processes;
use Underground8::Report::LimesAS::Versions;
use Underground8::Report::LimesAS::Update;
use Underground8::Report::LimesAS::MailQueue;
use Underground8::ReportFactory::LimesAS::Mail;
use Underground8::ReportFactory::LimesAS::LDAP;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Misc::Net::Traceroute;
use DBI;
use XML::Dumper;
use Config::File qw(read_config_file);
use Sys::Statistics::Linux;
use Data::Dumper;
use RRDs;
use Time::HiRes qw(gettimeofday tv_interval);
use Net::Telnet;
#use Net::Traceroute;
use Net::DNS qw( mx );
use Socket qw(inet_aton AF_INET);
use DateTime;
use DateTime::Format::Strptime;

# Constructor
sub new ($$$)
{
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->{'_mail'} = new Underground8::ReportFactory::LimesAS::Mail;
    $self->{'_ldap'} = new Underground8::ReportFactory::LimesAS::LDAP;

    return $self;
}


# hier reports createn
# methode kann aufgerufen werden durch $appliance->report->sysinfo
sub sysinfo
{
    my $report = new Underground8::Report::LimesAS::Sysinfo;
    
    # Retrieve 1h cpu avg through RRD before getting stats through $lxs; if available,
    # we don't need to collect CpuStats and therefore no need to wait for Sys::Statistics::Linux 
    my $avg_1h =_get_1h_cpu_avg();

    my $lxs = new Sys::Statistics::Linux(
         sysinfo   => 1,
         cpustats  => (defined $avg_1h) ? 0 : 1,
         procstats => 0,
         memstats  => 1,
         pgswstats => 0,
         netstats  => 0,
         sockstats => 0,
         diskstats => 0,
         diskusage => 1,
         loadavg   => 1,
         filestats => 0,
         processes => 0,
     );
    
    # this is necessary to get useful stats, unless CPU avg isn't already calculated from RRD
    sleep(1) if !defined $avg_1h; # just sleep in 1h cpu avg wasn't available
	sleep(1);
    my $stats = $lxs->get;
    #print Dumper $stats;
    #print "<pre>";
    #print Dumper $stats;
    #print "</pre>";

    $report->{'cpu_total'} = $stats->{'cpustats'}->{'cpu'}->{'total'} if !defined $avg_1h;

    #if the 1h avg is not correct(rrd file probleme), then we take "cpu_total"
    $report->{'cpu_avg_1h'} = defined $avg_1h ? $avg_1h : $report->{'cpu_total'}; 

    #$report->{'fsusage_root'} = $fsusage_root;
    $report->{'mem_total'} = $stats->{'memstats'}->{'memtotal'};
    my $memused = $stats->{'memstats'}->{'memtotal'} - $stats->{'memstats'}->{'realfree'};
    $report->{'mem_used'} = $memused;
    $report->{'mem_free'} = $stats->{'memstats'}->{'realfree'};
    my $memusedper = 100 - $stats->{'memstats'}->{'realfreeper'};
    $report->{'mem_used_percentage'} = $memusedper;
    $report->{'swap_total'} = $stats->{'memstats'}->{'swaptotal'};
    $report->{'swap_used'} = $stats->{'memstats'}->{'swapused'};
    $report->{'swap_free'} = $stats->{'memstats'}->{'swapfree'};
    $report->{'swap_used_percentage'} = $stats->{'memstats'}->{'swapusedper'};
    $report->{'loadavg_1'} = $stats->{'loadavg'}->{'avg_1'};
    $report->{'loadavg_5'} = $stats->{'loadavg'}->{'avg_5'};
    $report->{'loadavg_15'} = $stats->{'loadavg'}->{'avg_15'};
    $report->{'uptime'} = $stats->{'sysinfo'}->{'uptime'};


    return $report;
}

sub process_running($@)
{
    my $class = shift;
    my $names = shift;
    my $processes = new Underground8::Report::LimesAS::Processes;
    
    my $lxs = new Sys::Statistics::Linux(
        sysinfo   => 0,
        cpustats  => 0,
        procstats => 0,
        memstats  => 0,
        pgswstats => 0,
        netstats  => 0,
        sockstats => 0,
        diskstats => 0,
        diskusage => 0,
        loadavg   => 0,
        filestats => 0,
        processes => 1,
    );

    # Although doc says that sleep is necessary here, we don't care for performance reasons
    # sleep(1);

    my $processlist = $lxs->get;

    foreach my $name (@{$names})
    {
        my $pids = $processlist->psfind({ cmd => qr/$name/ });
        $processes->{'no_total'}++;
        if (scalar @{ $pids } > 0)
        {
            $processes->{'processes'}->{$name}->{'running'} = 1;
            $processes->{'processes'}->{$name}->{'pids'} = $pids;
            $processes->{'no_running'}++;
        }
        else
        {
            $processes->{'processes'}->{$name}->{'running'} = 0;
        }
    }
    
    #print Dumper $processes;
    return $processes;
}

sub processlist($){
	my $self = shift;

	my $plist = ();
	#my @ps_output = `$g->{'cmd_ps_hierachical'}`;
	my @ps_output = `$g->{'cmd_ps'}`;

	foreach my $process (@ps_output) {
	  my $rec = {}; 

	  #USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
	  #root         2  0.0  0.0      0     0 ?        S<   06:54   0:00 [kthreadd]
	  #root         3  0.0  0.0      0     0 ?        S<   06:54   0:00  \_ [migration/0]
	  if( $process =~ /^(\w+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+)\s+(.+?)\s+(.+?)\s+(\d+:\d+|...\d+)\s+(\d+:\d+)\s+(.*)$/ ) {
		  $rec->{'user'} = $1; 
		  $rec->{'pid'} = $2; 
		  $rec->{'cpu'} = $3; 
		  $rec->{'mem'} = $4; 
		  $rec->{'tty'} = $7; 
		  $rec->{'status'} = $8; 
		  $rec->{'start'} = $9; 
		  $rec->{'time'} = $10;
		  $rec->{'cmd'} = $11;

		  push @$plist, $rec;
	  }
	}

	return $plist;
}

sub mailqueue_live($){
	my $self = shift;
	my @mailq_output = `$g->{'cmd_mailq'}`;

	my $mail_cnt = -1;
	my $mails = [];

	# test data only -- remove me
	# open SAMPLE, '<', "/tmp/lolq" or die $!;
	# @mailq_output = <SAMPLE>;
	# close SAMPLE;

	foreach my $line (@mailq_output) {
		# mailq header and empty lines
		next if($line =~ /Sender\/Recipient/);

		# empty line between mails
		next if($line =~ /^$/);

		# new mail
		if($line =~ /^([A-F0-9]{8,12}\*?)\s+(\d+)\s+\w{3} (\w{3} \d\d .{5}).{3}\s+(.*)$/){
			my %mail;
			$mail_cnt++;

			my $qnr = $1;
			$mail{'size'} = $2;
			$mail{'timestamp'} = $3;
			$mail{'sender'} = $4;

			if($qnr =~ /\*$/) {
				$mail{'active'} = "1";
			} else {
				$mail{'active'} = "0";
			}
			$qnr =~ s/\*//g;
			$mail{'queuenr'} = $qnr;


			$mails->[$mail_cnt] = \%mail;
		}

		# fail mail
		if($line =~ /^\s+\((.*)\)$/){
			$mails->[$mail_cnt]->{'fail'} = 1;
			$mails->[$mail_cnt]->{'fail_message'} = $1;
		}

		# list of recipients
		if($line =~ /^\s+(\S+@\S+\.\w{2,5})$/) {
			$mails->[$mail_cnt]->{'recipients'} .= $1 . " ";
		}
	}

	return $mails;
}


sub mailqueue($)
{
  my $past = 1; # How old the displayed records are, see /usr/local/bin/mqsize.pl
  my $self = shift;
  my $mqueue = new Underground8::Report::LimesAS::MailQueue;
  my $time = time;
  my %history;
  my $href;

  $time-=($time%300); # Calc backwards to the last %5 minute
  for(my $i = 0; $i <= ($past*24*12); $i++){
    $history{($time-$i*300)}=[0,0];
  }

  my $dbh = DBI->connect('DBI:mysql:database=mailq;host=localhost','mailq','mailq',{AutoCommit => 0}) or throw Underground8::Exception($!);
  my $sth = $dbh->prepare("SELECT * FROM mcount ORDER BY count_time DESC");
  $sth->execute() or throw Underground8::Exception($!);

  while($href=$sth->fetchrow_hashref()){
    $history{$href->{'count_time'}}=[$href->{'mail_count'},$href->{'size'}];
  }
  $mqueue->{'history'} = \%history;

  $dbh->disconnect;

  return $mqueue;
}

sub versions($)
{
    my $self = shift;
    my $versions = new Underground8::Report::LimesAS::Versions;
    my %readhash;    
    my $clamav_raw = safe_system( $g->{'cmd_clamav_version'} );
    
    open (SAV, '<', $g->{'file_spamassassin_version'})
        or throw Underground8::Exception::FileOpen($g->{'file_spamassassin_version'});
    my $spamassassin_raw = <SAV>;
    close(SAV);

    open (AVAILVER, '<', $g->{'cfg_system_version_available_file'})
        or throw Underground8::Exception::FileOpen($g->{'cfg_system_version_available_file'});
    my $avail_system_version = <AVAILVER>;
    close(AVAILVER);

    open (TIMESTAMP, '<', $g->{'cfg_update_last_timestamp'})
        or throw Underground8::Exception::FileOpen($g->{'cfg_update_last_timestamp'});
    my $last_update = <TIMESTAMP>;
    close(TIMESTAMP);

    my $dump =  new XML::Dumper;
    my $all_versions = $dump->xml2pl( $g->{'cfg_system_version_all_file'} )
        or throw Underground8::Exception::FileOpen($g->{'cfg_system_version_all_file'});
    
    my $update_conf = read_config_file( $g->{'file_usus_conf'} )
        or throw Underground8::Exception::FileOpen($g->{'file_usus_conf'}); 

    my $main_version = get_current_installed_main_version();
    my $system_type = $update_conf->{type};    
    
    if ( $clamav_raw =~ /^ClamAV (.*?)\/(\d+)\/(.*)$/ )
    {
        $versions->{'version_clamav'} = $2;

        #example Fri Jul 17 07:22:17 2009 
        
        my $strp = new DateTime::Format::Strptime(
                                    pattern => '%a %b %d %T %Y',
                                    locale => 'en',
                                        );
        $versions->{'time_clamav'} = $strp->parse_datetime($3);
    }
    else
    {
        # this is a fallback!
        $versions->{'version_clamav'} = "Interpretation of string failed: $clamav_raw";
    }

    if ( $spamassassin_raw =~ /^\# UPDATE version (.*)$/ )
    {
        $versions->{'version_spamassassin'} = $1;
    }
    else
    {
        # this is a fallback!
        $versions->{'version_spamassassin'} = "Interpretation of string failed: $spamassassin_raw";
    }


    $self->read_settings($g->{'cfg_system_version_file'}, \%readhash);
    $versions->{'version_system'} = (defined $readhash{'main'})?$readhash{'main'}:0;
    $versions->{'version_build'} = (defined $readhash{'build'} && $readhash{'build'} =~ /^(\d+)$/)?$1:0;
    $versions->{'version_revision'} = (defined $readhash{'revision'} && $readhash{'revision'} =~ /^(\d+)$/)?$1:0;    
    
    $versions->{'version_system_available'} = $avail_system_version;

    # calculate DateTime object for the timestamp
    if ($last_update =~ /(\d\d\d\d)\.(\d\d)\.(\d\d)_(\d\d)-(\d\d)-(\d\d)/)
    {
        $versions->{'last_update'} = new DateTime {
                                        year => $1,
                                        month => $2,
                                        day => $3,
                                        hour => $4,
                                        minute => $5,
                                        second => $6,
                                        };
    }
    else
    {
        # no timestamp -- fallback
        $versions->{'last_update'} = new DateTime {
                                        year => 2000,
                                        month => 1,
                                        day => 1,
                                        hour => 0,
                                        minute => 0,
                                        second => 0,
                                        };

    }

    $versions->{'version_system_all'} = $all_versions->{$system_type}->{$main_version}->{'avail'};

    return $versions;

}

sub mail
{
    my $self = shift;
    return $self->{'_mail'};
}

sub ldap
{
    my $self = shift;
    return $self->{'_ldap'};
}

sub license
{
    my $self = shift;
    return $self->{'_license'};
}

sub update
{
    my $self = shift;
    my $update = new Underground8::Report::LimesAS::Update;
    
    $update->{'update_running'} = $self->update_running();
    $update->{'update_file'} = $self->update_file();
    
    return $update;

}

sub read_settings
{
    my $self = shift;
    my $file = shift;
    my $hash = shift;
    my ($key, $val);
    open (SETS, $file)
    or throw Underground8::Exception::FileOpen($file);;
    while (<SETS>)
    {
        chop;
        ($key, $val) = split (/=/, $_, 2);
        if (defined $key && length $key)
        {
            $val =~ s/^\'//g;
            $val =~ s/\'$//g;
            $key =~ /([A-Z-a-z0-9_-]*)/;
            $key = $1;
            $val =~ /([\W\w]*)/;
            $val = $1;
            $hash->{$key} = $val;
        }
    }
    close SETS;
}

#-->The method to be used, if you want to have a more detailed system statistics report. 
#For now it only contains additionnal average of last 24h usage
sub advanced_sysinfo
{
    my $report = new Underground8::Report::LimesAS::Sysinfo;
    
    my $lxs = new Sys::Statistics::Linux(
         sysinfo   => 1,
         cpustats  => 1,
         procstats => 0,
         memstats  => 1,
         pgswstats => 0,
         netstats  => 0,
         sockstats => 0,
         diskstats => 0,
         diskusage => 1,
         loadavg   => 1,
         filestats => 0,
         processes => 0,
     );
    
    # this is necessary to get useful stats
    sleep(1);
    
    my $stats = $lxs->get;
    #print Dumper $stats;

    $report->{'cpu_total'} = $stats->{'CpuStats'}->{'cpu'}->{'total'}; 
    my $avg_24h =_get_24h_cpu_avg();
    $report->{'cpu_avg_24h'} = defined $avg_24h ?$avg_24h : $report->{'cpu_total'}; # in case of UNKNOWN entries in RDD file, we set it equal to "cpu_total"  
    #$report->{'fsusage_root'} = $fsusage_root;
    $report->{'mem_total'} = $stats->{'memstats'}->{'memtotal'};
    $report->{'mem_totalG'} = sprintf('%.1f', ($report->{'mem_total'}/1048576));
    my $memused = $stats->{'memstats'}->{'memtotal'} - $stats->{'memstats'}->{'realfree'};
    $report->{'mem_used'} = $memused;
    $report->{'mem_usedG'} = sprintf('%.1f', ($report->{'mem_used'}/1048576));
    $report->{'mem_free'} = $stats->{'memstats'}->{'realfree'};
    $report->{'mem_freeG'} = sprintf('%.1f', ($report->{'mem_free'}/1048576));
    my $memusedper = 100 - $stats->{'memstats'}->{'realfreeper'};
    $report->{'mem_used_percentage'} = sprintf('%.0f' , $memusedper);
    $report->{'swap_total'} = $stats->{'memstats'}->{'swaptotal'};
    $report->{'swap_totalG'} = sprintf('%.1f', ($report->{'swap_total'}/1048576));
    $report->{'swap_used'} = $stats->{'memstats'}->{'swapused'};
    $report->{'swap_usedG'} = sprintf('%.1f', ($report->{'swap_used'}/1048576));
    $report->{'swap_free'} = $stats->{'memstats'}->{'swapfree'};
    $report->{'swap_freeG'} = sprintf('%.1f', ($report->{'swap_free'}/1048576));
    $report->{'swap_used_percentage'} = sprintf('%.0f' , $stats->{'memstats'}->{'swapusedper'});
    $report->{'loadavg_1'} = $stats->{'loadavg'}->{'avg_1'};
    $report->{'loadavg_5'} = $stats->{'loadavg'}->{'avg_5'};
    $report->{'loadavg_15'} = $stats->{'loadavg'}->{'avg_15'};
    $report->{'uptime'} = $stats->{'sysinfo'}->{'uptime'};
    $report->{'cpu_count'} = $stats->{'sysinfo'}->{'countcpus'};
    
    foreach my $entity (keys %{$stats->{'diskusage'}})
    {
        if ($stats->{'diskusage'}->{$entity}->{'mountpoint'} =~ /^\/$/)
        {
            $report->{'disk_totalsize'} = $stats->{'diskusage'}->{$entity}->{'total'};
            $report->{'disk_usedsize'} = $stats->{'diskusage'}->{$entity}->{'usage'};
            $report->{'disk_freesize'} = $stats->{'diskusage'}->{$entity}->{'free'};
            $report->{'disk_totalsizeG'} = sprintf('%.1f', ($report->{'disk_totalsize'}/1048576));
            $report->{'disk_usedsizeG'} = sprintf('%.1f', ($report->{'disk_usedsize'}/1048576));
            $report->{'disk_freesizeG'} = sprintf('%.1f', ($report->{'disk_freesize'}/1048576));
            
            $report->{'disk_usedpercentage'} = $stats->{'diskusage'}->{$entity}->{'usageper'};
            last;
        }
    }

	$report->{'logs_used'} = `$g->{'cmd_logging_space'}`;
	$report->{'quarantine_used'} = `$g->{'cmd_quarantine_space'}`;

    return $report;
}

sub get_cpu_cores {
    my $cpu_cores = 0;

    open(CPUINFO, '<', "$g->{'file_cpuinfo'}")
        or throw Underground8::Exception::FileOpen($g->{'file_cpuinfo'});
    while(<CPUINFO>)
    {
      $cpu_cores++ if /^processor\s:\s\d$/;
    }
    close CPUINFO;

    return $cpu_cores;
}

# These two functions can return an "undef"ined value, if no data is collected in the rrd file.
sub _get_24h_cpu_avg { 
    my $cur_time = time();   # set current time
    my $end_time = int($cur_time/1800)*1800-1800  ;     #half an hour ago 
    my $start_time = $end_time -88200; # 

    #fetch average values from the RRD database between start and end time
    my ($start,$step,$ds_names,$data) = 
                          RRDs::fetch("/var/lib/munin/localdomain/localhost.localdomain-cpu-idle-d.rrd", "AVERAGE",
                            "-r", "1800", "-s", "$start_time", "-e", "$end_time");
  
    #Some Maths to calculate the Average, 
    #$data is a reference to an array of references.
    my $rows = 0;
    my $avg = undef;
    my $cpu_cores = get_cpu_cores() or 1;

    foreach my  $line (@$data)
    {
        my $val = $$line[0];
        if (defined $val)
        {
            $avg += (100 * $cpu_cores) - $val;
            $rows++;
        }
    }
    # calculate the average of the array
    $avg =sprintf("%.2f", $avg / $rows) if defined $avg;
    return $avg;
}

sub _get_1h_cpu_avg { 
    my $end_time =int(time()/300) * 300 ;    # 'round' current time to the last 5 minutes, eg. 10h37 becomes 10h35 , 00h01 becomes 00h00
    my $start_time = $end_time - 3600  ;     #one hour ago 

    #fetch average values from the RRD database between start and end time
    my ($start,$step,$ds_names,$data) = 
                          RRDs::fetch("/var/lib/munin/localdomain/localhost.localdomain-cpu-idle-d.rrd", "AVERAGE",
                            "-r", "300", "-s", "$start_time", "-e", "$end_time");
    #Some Maths to calculate the Average
    my $rows = 0;
    my $avg = undef;
    my $cpu_cores = get_cpu_cores() or 1;

    #$data is a reference to an array of references. 
    foreach my  $line (@$data)
    {
        my $val = $$line[0];
        if(defined $val)
        {
            $avg += (100 * $cpu_cores) - $val ;
            $rows++ ;
        }
    }

    # calculate the average of the array
    $avg = sprintf("%.2f", $avg / $rows) if defined $avg ;
    return $avg;
}

sub get_current_installed_main_version
{
    my $version = "0";
    open(DPKG, "$g->{'cmd_dpkg'} --list |")
        or throw Underground8::Exception::FileOpen($g->{'cmd_dpkg'});
    foreach my $line (<DPKG>)
    {
        if ( $line =~ m/^i[i|U]\s+?open-as-cgw\s+?(\d+?\.\d+?)\.\d+?[a|b|s]\d*?\-\d+?/ )
        {
            $version = $1;
        }
    }
    close(DPKG);
    return $version;    
}


sub get_current_installed_full_version
{
    my $version = "0";
    open(DPKG, "$g->{'cmd_dpkg'} --list open-as-cgw |")
        or throw Underground8::Exception::FileOpen($g->{'cmd_dpkg'});
    foreach my $line (<DPKG>)
    {
        if ( $line =~ m/^i[i|U]\s+?open-as-cgw\s+?(\d+?\.\d+?\.\d+?[a|b|s]\d*?)\-\d+?/ )
        {
            $version = $1;
        }
    }
    close(DPKG);
    return $version;    
}


sub update_running
{
    my $self = instance(shift);

    if (-f "/tmp/usus-running.lock")
    {
        return 1;
    } else {
        return 0;
    }
}

sub update_file
{
    my $self = instance(shift);

    my $update_file = "/tmp/usus-running";
    return $update_file;
}

sub new_sec_version_available
{
    my $self = instance(shift);
    my $current = get_current_installed_full_version();
    my $newest = 0;
    open(AVAIL_SECVERSION, "</etc/open-as-cgw/avail_secversion");
    while(<AVAIL_SECVERSION>)
    {
        $newest = $_;
    }
    close(AVAIL_SECVERSION);
    chomp $newest;

    if ( $newest gt $current )
    {
        return 1;
    } else {
        return 0;
    }
}


sub new_main_version_available
{
    my $self = instance(shift);
    my $current = get_current_installed_main_version();
    
    my $dump =  new XML::Dumper;
    my $all_versions = $dump->xml2pl( $g->{'cfg_system_version_all_file'} )
        or throw Underground8::Exception::FileOpen($g->{'cfg_system_version_all_file'});

    my $update_conf = read_config_file( $g->{'file_usus_conf'} )
        or throw Underground8::Exception::FileOpen($g->{'file_usus_conf'});

    my $system_type = $update_conf->{type};
    my $return = 0;

    foreach my $new ( keys %{$all_versions->{$system_type}->{$current}->{'avail'}} )
    {
        if ( $new gt $current )
        {
            $return = 1;
            last;
        }
    }
    return $return;
}

sub restart_required
{
    my $self = instance(shift);
    my $current_kernel;
    my $grub_default_kernel;
    my $grub_menu_lst = $g->{'file_grub_menu_list'};
    my $return = 0;

    $current_kernel = safe_system( $g->{'cmd_uname_r'} );
    chomp $current_kernel;
    
    open(MENU_LST, "< $grub_menu_lst");
    while(<MENU_LST>)
    {
        if ($_ =~ m/^kernel\s+?\/boot\/vmlinuz\-(\d+?\.\d+?\.\d+?\-\d+?\-)\s+?.*/)
        {
            $grub_default_kernel = $1;
            if ($grub_default_kernel ne $current_kernel)
            {
                $return = 1;
            }
            
            last;
        }
        
    }
    close(MENU_LST);

    #warn "Comparing current kernel currently installed \"$current_kernel\"\nwith first kernel in $grub_menu_lst     \"$grub_default_kernel\"\n";
    
    return $return;

}

sub ping_host ($)
{
    my $self = instance(shift);
    my $host = shift;

    my $exec_string = $g->{'cmd_ping'} . " -c 4 -i 0.2 $host ; echo \$?";
    my @ping_result = `$exec_string`;
    chomp(my $ping_exit_code = $ping_result[-1]);

    # If ping went OK, return rtt + percentual loss + ip
    if($ping_exit_code == 0) {
      $ping_result[-3] =~ /.*(\d)% packet loss.*/;
      my $loss = $1;

      $ping_result[-2] =~ /^rtt.*= .*\/(.*?)\/.*/;
      my $rtt_avg = $1;

      $ping_result[0] =~ /^PING .*? \(([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)\) .*/;
      my $ip = "$1.$2.$3.$4";


      return ($rtt_avg, $loss, $ip);
    # otherwise -1
    } else {
      return (-1);
    }
}

# Queries @dns_servers for A record of domain $domain_to_resolve
sub test_dns_server($;@)
{
  my $self = instance(shift);
  my $domain_to_resolve = shift;
  my @dns_servers = @_;
  my $cnt = 0;

  my $res = Net::DNS::Resolver->new( nameservers => [ @dns_servers ] );
  $res->udp_timeout(2);
  my $query = $res->query($domain_to_resolve, 'A') or return "err_lookup";
  foreach my $rr ( grep { $_->type eq 'A' } $query->answer){
    $cnt++;
  }

  return "found_single" if ($cnt == 1);
  return "found_multiple" if ($cnt > 1);
  return "err_lookup";
}

# (1) Lookup $host + (2) reverse-lookup IP of step (1)
sub test_reverse_lookup($;@){
  my $self = instance(shift);
  my $host = shift;
  my @dns_servers = @_;
  my $ip;

  my $res = Net::DNS::Resolver->new( nameservers => [ @dns_servers ] );
  $res->udp_timeout(2);

  # (1) Resolve IP of $host
  my $query = $res->search($host) or return "err_lookup";
  foreach my $rr ( grep { $_->type eq 'A' } $query->answer) {
    $ip = $rr->address;
  }

  # (2) Reverse lookup $ip
  my $reverse_hostname = join('.', reverse split(/\./, $ip)).".in-addr.arpa";
  $query = $res->query($reverse_hostname, "PTR") or return "err_rlookup";
  foreach my $rr ( grep { $_->type eq 'PTR' } $query->answer) {
    return "success" if $rr->rdatastr eq ($host . ".");
  }
  
  return "err_no_match";
}

# Retrieves MX record of $maildomain, connects to that mailserver and
# looks if SMTP banner really contains $maildomain (220 SMTP response only)
sub check_domain_mx_record($$;@)
{
    my $self = instance(shift);
    my $limesas_fqdn = shift;
    my $maildomain = shift;
		my @dns_servers = @_;

    my $smtpd_ready = 0;
    my $reverse_lookup = 0;
    my $cnt = 0;

    my $res = Net::DNS::Resolver->new( nameservers => [ @dns_servers ] );
    my @mx_list = mx($res, $maildomain);

    # Traverse ALL MX records; maybe we deal with a clustered AS appliance,
    # so only one MX entry will have to correctly point to us
    foreach my $mx (@mx_list) 
    {
      $cnt++;
      my $mailsrv =
        new Net::Telnet( Host => $mx->exchange, Port => 25, Timeout => 5, Errmode => "return")
        or next;

      my $banner = $mailsrv->get( Timeout => 2 );
      if( $banner =~ /220 $limesas_fqdn .*/)
      {
        $mailsrv->close;

        # MX is ok if at least 1 reply matches (e.g. multiple RR MX records; keyword clustering)
        $smtpd_ready |= 1;

        # SMTPd answeres correctly, now check reverse lookup to MX
        $reverse_lookup++ if (test_reverse_lookup( $self, $mx->exchange ) eq "success");
      }
      else
      {
        $mailsrv->close;
      }
    }

    return "mx_err" if ($smtpd_ready == 0);
    return "mx_ok_single" if ($cnt==1 and $reverse_lookup);
    return "mx_ok_multiple" if ($cnt>1 and $reverse_lookup);
    return "mx_ok_single_norevlookup" if ($cnt==1);
    return "mx_ok_multiple_norevlookup" if ($cnt>1);
}

# Connects to $host at $port and checks for SMTP 220 response
sub check_smtpsrv_availability ($;$)
{
    my $self = instance(shift);
    my $host = shift;
    my $port = shift || 25; 

    my $smtp_srv =
      new Net::Telnet( Host => $host, Port => $port, Timeout => 3, Errmode => "return")
      or return 0;

    # Grab smtpd banner for status code 220 (= service ready)
    my $banner = $smtp_srv->get( Timeout => 2 );
    if( $banner =~ /^220 .*/ )
    {
      $smtp_srv->close;
      return 1;
    }
    else
    {
      $smtp_srv->close;
      return 0;
    }
}

sub trace_host ($;$) 
{
    my $self = instance(shift);
    my $host = shift;
    my $ntoa = shift || 0;

    my $tr = Underground8::Misc::Net::Traceroute->new(host => $host);
    my $result = ();
    my ($router_ip, $router_hostname);

    if($tr->found)
    {
      my $hops = $tr->hops;
      if($hops >= 1)
      {
        for my $i (1..$hops)
        {
          $router_ip = $tr->hop_query_host($i, 0);
          if($ntoa)
          {
            $router_hostname = gethostbyaddr(inet_aton($router_ip) , AF_INET) || $router_ip;
          }

          $result->[$i-1]->{'count'} = $i;

          # If reverse lookup is enabled, return hostname instead of IP.
          # If traceroute didn't catch an IP address, return "*" marker
          $result->[$i-1]->{'host'} = ($router_ip) 
            ? ( ($ntoa)
              ? ($router_hostname) 
              : ($router_ip ) )
            : "*";  
          $result->[$i-1]->{'time'} = $tr->hop_query_time($i, 0) || "*";  
        }

        return $result;
      }
    }

    return 0;
}

sub simple_maillog_stats {
	my $self = instance(shift);
	my $log = $g->{'mailsimple_log'};

	my %info;
	push @{$info{files}}, $_ foreach (<$log*>);

	for (@{$info{files}}){
		$info{$_}{lines} = safe_system((/\.gz$/ ? "/bin/zcat" : "/bin/cat") . " $_ | wc -l | cut -d' ' -f1");
		$info{$_}{firstline} = safe_system((/\.gz$/ ? "/bin/zcat" : "/bin/cat") . " $_ 2>/dev/null | head -n 1 | cut -d' ' -f1");
		$info{$_}{firstline} =~ /^(....)-(..)-(..)T(..):(..).*/;
		$info{$_}{"first_date_y"} = $1;
		$info{$_}{"first_date_m"} = $2;
		$info{$_}{"first_date_d"} = $3;
		$info{$_}{"first_time_h"} = $4;
		$info{$_}{"first_time_m"} = $5;

		$info{$_}{lastline}  = safe_system((/\.gz$/ ? "/bin/zcat" : "/bin/cat") . " $_ | tail -n 1 | cut -d' ' -f1");
		$info{$_}{lastline} =~ /^(....)-(..)-(..)T(..):(..).*/;
		$info{$_}{"last_date_y"} = $1;
		$info{$_}{"last_date_m"} = $2;
		$info{$_}{"last_date_d"} = $3;
		$info{$_}{"last_time_h"} = $4;
		$info{$_}{"last_time_m"} = $5;
	}

	return %info;
}


1;

#!/usr/bin/perl -w
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
use File::Temp qw(tempfile);

#
# GLOBALS
#

my %REVS = ();
$REVS{'Acrosser_MINI.1'} = ["PT-2200","3","1","","400","512MiB","5"];
$REVS{'Acrosser_MIDI.1'} = ["PT-2200","4","1","","1000","512MiB","5"];
$REVS{'MSI.1'} = ["MS-9129","","1","","","","2"];
$REVS{'MSI.2'} = ["MS-9149","","1","","","","2"];
$REVS{'Portwell_NAD2073.1'} = ["CN700-8237","","1","","1500","","3"];
$REVS{'Portwell_NAD2073.2'} = ["CN700-8237","","1","","1000","","3"];
$REVS{'Portwell_NAR4040.1'} = ["i845GV-83628HF","4","1","Intel(R) Celeron(R)","2.00GHz","1GB","6"];
$REVS{'Portwell_NAR5060.1'} = ["i845GV-83628HF","6","1","Intel(R) Pentium(R) 4","2.80GHz","2GB","6"];
$REVS{'Portwell_NAR5060.2'} = ["i845GV-83628HF","6","1","Intel(R) Pentium(R) 4","2.80GHz","3GB","6"];
$REVS{'Portwell_NAD5612.1'} = ["LakePort","4","2","Intel(R) Pentium(R) 4","3.40GHz","2GB","5"];
$REVS{'Portwell_NAD5612.2'} = ["LakePort","4","2","Intel(R) Pentium(R) 4","3.40GHz","3GB","5"];
$REVS{'Portwell_NAD5612.3'} = ["LakePort","4","2","Intel(R) Pentium(R) 4","3.40GHz","4GB","5"];
$REVS{'Portwell_NAR7080.1'} = ["","","4","Intel(R) Xeon(TM)","3.20GHz","4GB","4"];
$REVS{'Portwell_NAR7080.2'} = ["","","4","Intel(R) Xeon(TM)","3.20GHz","8GB","4"];

my ($tmpfh,$tmpfile) = tempfile();

#
# FUNCTIONS
#

sub read_baseboard_name
{
    open (LSHW, "<$tmpfile");
    while (<LSHW>)
    {
        if($_ =~ /^\/0\s+bus\s+(.+)$/)
        {
            close(LSHW);
            return $1;
        }
    }
    close(LSHW);
}

sub read_cpu_info
{
    my ($cpucount, $cpuname, $cpuspeed);

    open (LSHW, "<$tmpfile");
    $cpucount = 0;    
    while (<LSHW>)
    {
        if($_ =~ /^.+processor\s+(.+)\s.+\s(.+)$/)
        {
            $cpucount++;
            $cpuname=$1;
            $cpuspeed=$2;
        }
    }
    close(LSHW);

    return ($cpucount, $cpuname, $cpuspeed);
}

sub read_mem_size
{
    open (LSHW, "<$tmpfile");
    while (<LSHW>)
    {
        if($_ =~ /^.+memory\s+(.+)\sSystem Memory$/)
        {
            close(LSHW);
            return $1;
        }
    }
    close(LSHW);
}

sub read_nics
{
    open (LSHW, "<$tmpfile");
    my $nic_count = 0;
    while (<LSHW>)
    {
        if($_ =~ /^.+network\s+(.+)$/)
        {
            $nic_count++;
        }
    }
    close(LSHW);

    return $nic_count;
}

sub find_model
{
    my $data = $_[0];

    foreach my $model (keys %REVS)
    {
        my $equal_values = 0;
        for (my $i = 0; $i < (scalar @{$REVS{$model}}-1); $i++)
        {
            if ($REVS{$model}->[$i] && $data->[$i])
            {
                if ($REVS{$model}->[$i] eq $data->[$i])
                {
                    $equal_values++;
                }
            }
            if ($REVS{$model}->[-1] == $equal_values)
            {
                return $model;
            }
        }
    }
}

#
# MAIN
#

my ($baseboard_name, $cpuname, $cpucount, $cpuspeed, $nic_count, $mem_size);

# create temp file
open(TEMP, "lshw -short |");
while (<TEMP>)
{
    print $tmpfh $_;
}
close(TEMP);
close($tmpfh);

#$baseboard_name=read_baseboard_name();
#($cpucount, $cpuname, $cpuspeed)=read_cpu_info();
#$nic_count=read_nics();
#$mem_size=read_mem_size();
#print "Baseboard_Name: '" . $baseboard_name . "'\n";
#print "CPU_Name: '" . $cpuname . "'\n";
#print "CPU_Count: '" . $cpucount . "'\n";
#print "CPU_Speed: '" . $cpuspeed . "'\n";
#print "NIC_Count: '" . $nic_count . "'\n";
#print "Mem_Size: '" . $mem_size . "'\n";

# search for model
my @data = ();
$data[0] = read_baseboard_name();
$data[1] = read_nics();
($data[2], $data[3], $data[4]) = read_cpu_info();
$data[5] = read_mem_size();
my $model = find_model(\@data);
print $model . "\n";

# unlink temp file
unlink($tmpfile);

exit 0;


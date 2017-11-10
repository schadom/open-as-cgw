#!/usr/bin/perl

my $etc = "";                                                                                                                                            
my $bin = "";                                                                                                                                            
my $var = "";                                                                                                                                            
my $user = (getpwuid($<))[0];                                                                                                                            
                                                                                                                                                         
BEGIN {                                                                                                                                                  
                                                                                                                                                         
if ($ENV{'LIMESLIB'})                                                                                                                                    
{                                                                                                                                                        
    my $libpath = $ENV{'LIMESLIB'};                                                                                                                      
    print "Found LIMESLIB=$libpath\n";                                                                                                                   
    $etc = "$libpath/etc";                                                                                                                               
    $bin = "$libpath/bin";                                                                                                                               
    $var = "$libpath/etc/";                                                                                                                              
    unshift(@INC,"$libpath/lib/");                                                                                                                       
}                                                                                                                                                        
else                                                                                                                                                     
{                                                                                                                                                        
    $etc = "/etc/open-as-cgw";                                                                                                                                 
    $bin = "/usr/local/bin";                                                                                                                             
    $var = "/var/open-as-cgw";                                                                                                                                 
}                                                                                                                                                        
                                                                                                                                                         
}

#
use strict;
use warnings;
use Underground8::ReportFactory::LimesAS::Mail;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

my $rf = new Underground8::ReportFactory::LimesAS::Mail;


my $t0 = [ gettimeofday ];

#my $report = $rf->current_stats;
my $report = $rf->mail_last24h;
#my $report = $rf->mail_lastmonth;
#my $report = $rf->from_domains_last24h(5);
#my $report = $rf->domains_lastmonth(5);
#my $report = $rf->domains_lastyear(5);
#my $report = $rf->livelog(18);

my $elapsed = tv_interval($t0);

#print Dumper $report;

print "Took $elapsed\n";


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


package Underground8::Log;
use Underground8::Exception::Execution;
use Sys::Syslog;
use Error;

BEGIN {
    use Exporter ();
    @Underground8::Log::ISA         = qw(Exporter);
    @Underground8::Log::EXPORT      = qw(aslog);
    @Underground8::Log::EXPORT_OK   = qw();
}

my $user = (getpwuid($<))[0];
my $libpath = $ENV{'LIMESLIB'};
my $guipath = $ENV{'LIMESGUI'};

my ($etc,$bin,$var) = ($libpath)
	? ("$libpath/etc", "$libpath/bin", "$libpath/etc")
	: ("/etc/open-as-cgw", "/usr/local/bin", "/var/open-as-cgw");
my $www_static = ($guipath) ? "$guipath/root/static" : "/var/www/LimesGUI/root/static";



###
sub aslog($$){
	my ($level, $msg) = @_;
	my ($package, $filename, $line) = caller;
	$filename =~ s/^.*\/(.*)$/$1/;

	$level =~ s/^debug$/dbg/;
	$level =~ s/^info$/inf/;
	$level =~ s/^warn$/wrn/;
	$level =~ s/^error$/err/;

	my %levelmap = ( "dbg"  => LOG_DEBUG, "inf"  => LOG_INFO, "wrn"  => LOG_WARNING, "err"  => LOG_ERR,);

	$level = "dbg" if !$levelmap{$level} or !defined($levelmap{$level});

	openlog "ascgw", "ndelay", "local7";
	# syslog $levelmap{$level}, uc($level). " $package [$filename:$line] $msg\n";
	syslog $levelmap{$level}, uc($level). " package [$filename:$line] $msg\n";
	closelog;
}


1;

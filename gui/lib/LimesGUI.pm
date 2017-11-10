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


package LimesGUI;

use strict;
use warnings;

use Catalyst::Runtime;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

# dangerouse! if you add to the url '?dump_info=1' then you get a dump of all perl objects involved in displaying that page
use Data::Dumper;

use Catalyst qw/
	-Debug
	ConfigLoader 
	Static::Simple
		
	StackTrace

	Authentication
	Authentication::Store::Htpasswd
	Authentication::Credential::Password

	Authorization::Roles
	Authorization::ACL	

	Session
	Session::Store::File
	Session::State::Cookie

	I18N::Underground8
        Unicode
    
        FormValidator
        FillInForm

        Prototype::Underground8

        Email
/;

use Catalyst::Request::Upload;
use File::Temp qw/ tempfile /;
use File::Path;
use Underground8::Utils;
use FindBin qw($Bin);

# find out environment
my $guipath;
my $libpath;
my $etc;
my $limesgui;

if ($ENV{'LIMESGUI'})
{
    $limesgui = $ENV{'LIMESGUI'};
}
else
{
    $limesgui = "/var/www/LimesGUI";

}


if ($ENV{'LIMESLIB'})
{
    $libpath = $ENV{'LIMESLIB'};
    $etc = "$libpath/etc/";
}
else
{
    $etc = "/etc/open-as-cgw";
}

system("rm -rf $limesgui/session_store/*");

# a session is invalidated after 1 hour of idle
__PACKAGE__->config->{session} = {
    expires => 3600,
    storage => "$limesgui/session_store",

};

# here are stored the access credentials
__PACKAGE__->config->{authentication}{htpasswd} = "$etc/guipasswd";

our $VERSION = '1.00';

__PACKAGE__->config( name => 'LimesGUI' );

# So uri_for knows we use https and not http...
__PACKAGE__->config( using_frontend_proxy => 1);

# Add the appliance to the global context
use Underground8::Appliance::LimesAS;
my $appliance = new Underground8::Appliance::LimesAS ();
$appliance->load_config();

# The following line will be uncommented during svn export in the build system
# So DO NOT REMOVE
$appliance->commit();

 
# Configuration for Plugin Email ( use the system's sendmail program )
__PACKAGE__->config->{email} = ['Sendmail'];

# put the appliance in the config
__PACKAGE__->config( appliance => $appliance );

# Search for new versions
__PACKAGE__->config( new_sec_version => $appliance->report->new_sec_version_available );
__PACKAGE__->config( new_main_version => $appliance->report->new_main_version_available );
__PACKAGE__->config( restart_required => $appliance->report->restart_required );

print Dumper __PACKAGE__->config;

# Start the application - loads the .yml file #
__PACKAGE__->setup;

# !!!! PLEASE KEEP THIS LINE _AFTER_ __PACKAGE__->setup !!!!
# !!!! IT MODIFIES VARIABLES THAT ARE PRESENT ONLY _AFTER_ setup !!!!
# relocate backup folder so that can be used on the development server
__PACKAGE__->config->{backup}{absolutepath} = "$limesgui" . __PACKAGE__->config->{backup}{absolutepath};



=head1 NAME

LimesGUI - Catalyst based application

=head1 SYNOPSIS

    script/limesgui_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<LimesGUI::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Open AS Team

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

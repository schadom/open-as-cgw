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


package Underground8::Service::Proxy::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Underground8::Exception::Execution;

sub new ($) {
	my $class = shift;
	my $self = $class->SUPER::new('proxy');
}

sub service_start ($) {
	# nothing to do here 
}

sub service_stop ($) {
	# nothing to do here
}

sub service_restart ($) {
	my $self = instance(shift);
	safe_system($g->{'cmd_clamav_freshclam_restart'});
}

sub write_config ($$$$$$) {
	my $self = instance(shift);
	my ($proxy_server, $proxy_port, $proxy_username, $proxy_password, $proxy_enabled) = @_;
	my $use_proxy = "yes";

	if ($proxy_server eq "") {
		$use_proxy = "no";
	}

	if ($proxy_enabled == 1) {
		$self->write_environment_config($proxy_server, $proxy_port, $proxy_username, $proxy_password);
		$self->write_freshclam_config($proxy_server, $proxy_port, $proxy_username, $proxy_password);
	} else {
		$self->write_environment_config("", "", "", "");
		$self->write_freshclam_config("", "", "", "");
	}
}

sub write_environment_config($$$$$) {
	my $self = instance(shift);
	my ($proxy_server, $proxy_port, $proxy_username, $proxy_password) = @_;
	my ($authInfo, $portInfo) = ("", "");

	if ($proxy_username ne "" && $proxy_password ne "") {
		$authInfo = $proxy_username . ":" . $proxy_password . "@";
	}

	if ($proxy_port ne "") {
		$portInfo = ":" . $proxy_port;
	}

	my $template = Template->new ({ INCLUDE_PATH => $g->{'cfg_template_dir'}, });

	my $options = {
					http_proxy => $proxy_server ne "" ? "http_proxy=" . $authInfo . $proxy_server . $portInfo : "",
					https_proxy => $proxy_server ne "" ? "https_proxy=" . $authInfo . $proxy_server . $portInfo : "",
					ftp_proxy => $proxy_server ne "" ? "ftp_proxy=" . $authInfo . $proxy_server . $portInfo : "",
	};

	my $config_content;
	$template->process($g->{'template_etc_environment'},$options,\$config_content)
		or throw Underground8::Exception($template->error);

	open (ENVIRONMENT,'>',$g->{'file_etc_environment'})
		or throw Underground8::Exception::FileOpen($g->{'file_etc_environment'});

	print ENVIRONMENT $config_content;

	close (ENVIRONMENT);
}

sub write_freshclam_config($$$$$) {
	my $self = shift;
	my ($proxy_server, $proxy_port, $proxy_username, $proxy_password) = @_;

	my $template = Template->new ({ INCLUDE_PATH => $g->{'cfg_template_dir'}, });

	my $options = {
					proxy_server => $proxy_server ne "" ? "HTTPProxyServer " . $proxy_server : $proxy_server,
					proxy_port => $proxy_port ne "" ? "HTTPProxyPort " . $proxy_port : $proxy_port,
					proxy_username => $proxy_username ne "" ? "HTTPProxyUsername " . $proxy_username : $proxy_username,
					proxy_password => $proxy_password ne "" ? "HTTPProxyPassword " . $proxy_password : $proxy_password,
	};

	my $config_content;
	$template->process($g->{'template_clamav_freshclamconf'},$options,\$config_content)
		or throw Underground8::Exception($template->error);

	open (FRESHCLAM,'>',$g->{'file_clamav_freshclamconf'})
		or throw Underground8::Exception::FileOpen($g->{'file_clamav_freshclamconf'});

	print FRESHCLAM $config_content;

	close (FRESHCLAM);
}

1;

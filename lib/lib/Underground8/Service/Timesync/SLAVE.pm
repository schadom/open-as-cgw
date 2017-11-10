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


package Underground8::Service::Timesync::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;
use Underground8::Utils;
use Error;
use Underground8::Exception::FileOpen;
use Data::Dumper;

sub new ($)
{
    my $class = shift;
    my $self = $class->SUPER::new('timesync');
}

sub service_start ($)
{
    # none 
}

sub service_stop ($)
{
    # none
}

sub service_restart ($$)
{
    my $self = instance(shift);
    my $output = safe_system($g->{'cmd_ntpd_restart'},0,1);
}

sub write_config ($@)
{
    my $self = instance(shift); 
    
    $self->write_ntpd_conf(@_);
    $self->service_restart();
}

sub write_ntpd_conf($$)
{
    my $self = instance(shift);
    my $server = shift;
    my $template = Template->new({
                                  INCLUDE_PATH => $g->{'cfg_template_dir'},
                   });
    my $ntpd_conf_content;
    
    my $options = {
                   server => $server,
                  };
    $template->process($g->{'template_ntpd_conf'},$options,\$ntpd_conf_content)
        or throw Underground8::Exception($template->error);

    open (NTPD_CONF,'>',$g->{'file_ntpd_conf'})
        or throw Underground8::Exception::FileOpen($g->{'file_postfix_ntpd_conf'});
        print NTPD_CONF $ntpd_conf_content;
    close (NTPD_CONF);
    
}

1;

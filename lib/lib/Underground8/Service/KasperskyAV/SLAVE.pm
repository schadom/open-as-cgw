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


package Underground8::Service::KasperskyAV::SLAVE;
use base Underground8::Service::SLAVE;
use Template;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Utils;

use strict;
use warnings;


sub write_config
{
    my $self = instance(shift);

    my $archive_recursion = shift;

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 

    my $options = { archive_recursion => $archive_recursion,
    };
    
    my $config_content;
    $template->process($g->{'template_kaspersky_kavserverconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (KAV_LIMES,'>',$g->{'file_kaspersky_kavserverconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_kaspersky_kavserverconf'});

    print KAV_LIMES $config_content;

    close (KAV_LIMES); 

    $config_content = "";
    $options = {};
    $template->process($g->{'template_kaspersky_kavupdaterconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (KAV_LIMES,'>',$g->{'file_kaspersky_kavupdaterconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_kaspersky_kavupdaterconf'});

    print KAV_LIMES $config_content;

    close (KAV_LIMES); 

}

sub service_restart ($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_kaspersky_kavserver_restart'});
}
 

1;


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


package Underground8::Service::UpdateService::SLAVE;
use base Underground8::Service::SLAVE;
use Template;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
use Underground8::Utils;
use Data::Dumper;

use strict;
use warnings;


sub write_config
{
    my $self = instance(shift);

    my $parameters = shift;

    # TO BE REMOVED
    # License enforcement
#    my $auto_newest_license = $self->report->license->meta_lic_featureupdate();
    my $auto_newest_license = 1;
    if (!$auto_newest_license) { $parameters->{'auto_newest'} = 0; }

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 

    my $options = {  parameters=> $parameters,
    };
   
    my $config_content;
    $template->process($g->{'template_usus_conf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (USUS_CONF,'>',$g->{'file_usus_conf'})
        or throw Underground8::Exception::FileOpen($g->{'file_usus_conf'});

    print USUS_CONF $config_content;

    close (USUS_CONF); 

    $config_content = "";
    $options = {};
}

sub initiate_usus
{
    my $self = instance(shift);
    my $options = shift;
    system("$g->{'cmd_usus'} $options &");
}

1;


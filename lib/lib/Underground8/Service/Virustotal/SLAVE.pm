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


package Underground8::Service::Virustotal::SLAVE;
use base Underground8::Service::SLAVE;
use Template;
use Underground8::Exception;
use Underground8::Exception::FileOpen;
#use Underground8::Misc::VT::API;
use Underground8::Utils;

use strict;
use warnings;

=begin comment
sub write_config
{
    my $self = instance(shift);

    my $archive_recursion = shift;
    my $archive_maxfiles = shift;
    my $archive_maxfilesize = shift;

    my $template = Template->new ({
                           INCLUDE_PATH => $g->{'cfg_template_dir'},
                      }); 

    my $options = { archive_recursion => $archive_recursion,
                    archive_maxfiles => $archive_maxfiles,
                    archive_maxfilesize => $archive_maxfilesize
    };
    
    my $config_content;
    $template->process($g->{'template_clamav_clamdconf'},$options,\$config_content) 
        or throw Underground8::Exception($template->error);

    open (CLAMD_LIMES,'>',$g->{'file_virustotal_virustotalconf'})
        or throw Underground8::Exception::FileOpen($g->{'file_virustotal_virustotalconf'});

    print CLAMD_LIMES $config_content;

    close (CLAMD_LIMES); 

}

sub service_restart ($)
{
    my $self = instance(shift);
    
    my $output = safe_system($g->{'cmd_virustotal_restart'});
}
=cut 

1;


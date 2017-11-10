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


package LimesGUI::Controller::Admin;


# moose only works, if Error isn't needed.
use Moose;
use namespace::autoclean;
use File::stat;
use File::Slurp;

BEGIN
{
    extends 'Catalyst::Controller';
};



sub default : Private
{
    my ($self, $c) = @_;
    $c->res->redirect($c->uri_for('/admin/dashboard/dashboard'));
}


#sub index : Private {
#    my ( $self, $c ) = @_;
#
#    # get the current statistics
#    my $appliance = $c->config->{'appliance'};
#    my $antispam = $appliance->antispam;
#
#    my $current_stats = $appliance->report->mail->current_stats->current_stats;
#
#    $c->stash->{'current_stats'} = $current_stats;    
#    $c->stash->{'antispam'} = $antispam;
#
#    $c->stash->{template} = 'admin/dashboard/index.tt2';
#}


sub update_currentstats : Local
{
    my ( $self, $c ) = @_;

    # get the current statistics
    my $appliance = $c->config->{'appliance'};
    my $antispam = $appliance->antispam;

    my $current_stats = $appliance->report->mail->current_stats->current_stats;

    $c->stash->{'current_stats'} = $current_stats;    
    $c->stash->{'antispam'} = $antispam;
    $c->stash->{'nav'} = 'without_subnav';
    $c->stash->{template} = 'admin/index.currentstats.inc.tt2'; 
}

sub sysinfo : Local {
    my $self = shift;
    my $c = shift;

    my $appliance = $c->config->{'appliance'};
 
    my $sysinfo = $appliance->report->sysinfo(); 
    $c->config->{'new_sec_version'} = $appliance->report->new_sec_version_available();
    $c->config->{'new_main_version'}  = $appliance->report->new_main_version_available();
    $c->config->{'renew_licence_warning'}  = $appliance->report->license->renew_licence_warning();

    
    $c->stash->{'sn'} = $appliance->sn;
    # Formatting:
    $sysinfo->{'mem_used_percentage'} = sprintf "%.02f", $sysinfo->{'mem_used_percentage'};
    $sysinfo->{'mem_used_percentage'} =~ s/\./,/;
    $sysinfo->{'cpu_avg_1h'} = sprintf "%.02f", $sysinfo->{'cpu_avg_1h'};
    $sysinfo->{'cpu_avg_1h'} =~ s/\./,/;
	$sysinfo->{'loadavg_15'} = sprintf "%.02f", $sysinfo->{'loadavg_15'};
    $sysinfo->{'loadavg_15'} =~ s/\./,/;

    $c->stash->{'sysinfo'} = $sysinfo;    
    $c->stash->{template} = 'admin/index.sysinfo.inc.tt2';
}

sub services : Local {
    my $self = shift;
    my $c = shift;
    
    my $appliance = $c->config->{'appliance'};

    my @processarr = (
                      'amavisd',
                      'clamd',
                      'master',
                      'mysqld',
                      'rtlogd',
                      'saslauthd',
                     );
    my $processes = $appliance->report->process_running(\@processarr);
    
    $c->stash->{'processes'} = $processes; 
    $c->stash->{'antispam'} = $appliance->antispam;
    $c->stash->{template} = 'admin/index.services.inc.tt2';
}

sub export_graph : Local {
    my $self = shift;
    my $c = shift;
    my $appliance = $c->config->{'appliance'};
    
    use GD;
    use File::Temp qw(tempfile tempdir);
    
    my $width  = $c->request->params->{'width'};
    my $height  = $c->request->params->{'height'};
    my $imgtype = "png";
    my $image = new GD::Image($width,$height,1);

    for (my $y = 0; $y <= $height; $y++)
    {   
        my $x = 0;
        foreach (split(',', $c->request->params->{"r".$y}))
        {
            my ($hex, $repeat) = split(':', $_);
            $hex = hex($hex);
            $image->setPixel($x,$y,$hex);
            if (defined $repeat)
            {
                my $i = 1;
                while ($i < $repeat)
                {
                    $x++;
                    $image->setPixel($x,$y,$hex);
                    $i++;
                }
            }
            $x++;
        }
    }

   (my $temp_graph_fh, my $temp_graph_name) = tempfile(DIR => "/tmp",
                                                   TEMPLATE => "tmp_graph_XXXXXX",
                                                   SUFFIX => ".png",
                                                   );

    print $temp_graph_fh $image->$imgtype;
    close($temp_graph_fh);


    $c->stash->{'template'} = undef;
   
    my $stat = stat($temp_graph_name);
    my $content = read_file($temp_graph_name);

    $c->res->headers->remove_content_headers;
    $c->res->headers->content_type("image/$imgtype");
    #$c->res->headers->content_type("application/octet-stream");
    $c->res->headers->content_length( $stat->size );
    $c->res->headers->last_modified( $stat->mtime );
    $c->res->header( 'Content-Disposition', qq[attachment; filename=stats.png] );
    $c->res->output($content);
    
    
}



=head1 AUTHOR

Matthias Pfoetscher, underground_8

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

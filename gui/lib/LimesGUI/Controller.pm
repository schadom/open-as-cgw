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


package LimesGUI::Controller;

use Moose;
use namespace::autoclean;
use Underground8::Utils;

BEGIN
{
    extends 'Catalyst::Controller';
}


use Data::FormValidator::Constraints qw(:closures :regexp_common);
# dangerouse! if you add to the url '?dump_info=1' then you get a dump of all perl objects involved in displaying that page
use Data::Dumper;

# obsolete
sub set_status_msg : Private {
    my $self = shift;
    my $c = shift;
    my $status_msg = shift;

    $c->stash->{'box_status'}->{'success'} = $status_msg;
}



sub process_form : Private {
    my $self = shift;
    my $c = shift; 
    my $form_profile = shift;

    my $key;
 
    # Defaults for form profile
    my $form_profile_default = {
        msgs => {
            prefix => '',
            missing => 'err_missing',
            invalid => 'err_invalid',
            invalid_separator => ' ',
            format => '%s',
        }
    };

    # merge defaults and provided profile
    my $msg_constraints = $form_profile->{'msgs'}->{'constraints'};
    $form_profile_default->{'msgs'}->{'constraints'} = $msg_constraints;
    $form_profile->{'msgs'} = $form_profile_default->{'msgs'};


    my $status = {
        fields => undef,
        success => undef,
    };

    my $result = $c->form($form_profile); 

    if (!$result->success())
    {
        $status->{'fields'} = $result->msgs();
        $status->{'success'} = 'status_failed';
    }

#    $c->log->debug(Dumper $result->msgs());
    $c->{'stash'}->{'box_status'} = $status;

    return $result;
}

=head2 FV_domain
Used by form validators (accept even a space!)
=cut
sub FV_domain {
    return sub {
        my $dfv = shift;
        my $domain = shift;
        $dfv->name_this('domain_valid');

        my $letter      =  "[A-Za-z]";
        my $let_dig     =  "[A-Za-z0-9]";
        my $let_dig_hyp = "[-A-Za-z0-9]";

        my $regex = "(?:$let_dig(?:(?:$let_dig_hyp){0,61}$let_dig)?" .
                    "(?:\\.$letter(?:(?:$let_dig_hyp){0,61}$let_dig)?)*)";
        my $valid = $domain =~ /^$regex$/g;
        return $valid;
    }
    
}    

=head2 FV_domain_or_net_IPv4
Used by form validators (accept even a space!)
=cut
sub FV_domain_or_net_IPv4 {
    return sub {
	my $test = FV_domain();
	if( $test->( @_ ) )
	{
	    return 1;
	}
	$test = FV_net_IPv4();
        return $test->( @_ );
    }
    
}    

=head2 email_addr_or_domain
Used by form validators
=cut
sub email_addr_or_domain
{
    return sub {
        my $dfv = shift;
        my $string = shift;
        $dfv->name_this('mail_addr_or_domain');

        my $valid = $string =~ qr/[a-zA-Z0-9._%+-]*\@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,4}/;
        return $valid;
    }
}



############# CONSTRAINTS

sub gateway_in_subnet 
{
    return sub 
    {
        my $dfv = shift;
        my $ip_address = shift;
        my $subnet_mask = shift;
        my $default_gateway = shift;

        $dfv->name_this('gateway_in_subnet');
        my $ip = new NetAddr::IP($ip_address, $subnet_mask);
        my $gateway = new NetAddr::IP($default_gateway, $subnet_mask);
        if ($ip && $gateway)
        {   
            return $ip->contains($gateway);
        }
        else
        {   
            # return 1 (which means ok(!))
            # very dirty, but ip_addr and mask get checked in other constraints.
            return 1;
        }
    }
}

sub write_statistics_xml
{
    my $self = shift;
    my $c = shift;
    my $type = shift;
    my $stat_data = shift;
    my $mail_types = $g->{'available_mail_types'};
    
        my $template = Template->new ({
            INCLUDE_PATH => $g->{'cfg_template_dir'},
        });

        my $vars = { 
            current_stats => $stat_data,
            mail_types => $mail_types,
            Catalyst => $c, 
        };

        my $config_content;
        my $template_name;
        if ($type =~ m/^entire_traffic/)
        {
            $template_name = "entire_traffic_data.tt2";
        } else {
            $template_name = $type."_data.tt2";
        }
        my $file_name = $type."_data.xml";
        
        my $template_full = $g->{'template_amcharts_data_path'} . $template_name;
        my $file_full = $g->{'file_amcharts_data_path'} . $file_name;

        $template->process($template_full,$vars,\$config_content)
            or throw Underground8::Exception($template->error);
        open (AMCHARTS_XML,'>',$file_full)
            or throw Underground8::Exception::FileOpen($file_full);
        print AMCHARTS_XML $config_content;
        close (AMCHARTS_XML);

}




=head1 AUTHOR

Matthias Pfoetscher, underground_8

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

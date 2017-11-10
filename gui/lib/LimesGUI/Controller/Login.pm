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


package LimesGUI::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

LimesGUI::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut


sub generate_notifications
{
    my ($self, $c, $username) = @_;
    my $appliance = $c->config->{'appliance'};


    # admin password is still default, notification necessary
    my $current_hash = $appliance->system->authentication->users->{$username}->{'passwd'};
    if($appliance->system->authentication->encrypt_md5("password", substr($current_hash,0,14)) eq $current_hash)
    {
        push(@{$c->session->{'notifications'}}, 'notify_password');
    }


    # firewall rules (admin-ranges) have been changed and need confirm
    if ($appliance->system->firewall_notify)
    {
        push(@{$c->session->{'notifications'}}, 'notify_firewall');
    }
   

    # ip has been changed and needs to be confirmed
    if ($appliance->check_alert_notify_nic_change)
    {
        push(@{$c->session->{'notifications'}}, 'notify_ip');
    }
}





sub index : Private {
    my ( $self, $c ) = @_;


    # Get the username and password from form
    my $username = $c->request->params->{username} || "";
    my $password = $c->request->params->{password} || "";

    # If the username and password values were found in form
    if ($username && $password) {
        # Attempt to log the user in
        if ($c->login($username, $password)) {
            # If successful, then let them use the application
            $c->reset_session_expires();
            $c->session->{'username'} = $username;

            $self->generate_notifications($c, $username);

            # pending notifications?
            if ($c->session->{'notifications'})
            {
                # at least one notification is in the list?
                if (@{$c->session->{'notifications'}} > 0)
                {
                    $c->res->redirect($c->uri_for('/admin/dashboard/notification'));
                }
            }
            # otherwise redirect to /admin
            else
            {
                my $path = $c->session->{'unauth_path'} || 'admin';
                delete $c->session->{'unauth_path'};
                $c->response->redirect($c->uri_for("/admin"));
            }
            return;
        } else {
            # Set an error message
            $c->stash->{'error_msg'} = "error_bad_login";
        }
    } else {
        # Set an error message ???
        #$c->stash->{'error_msg'} = "error_no_usr_or_pwd";
    }

    # those parameters are needed for infos in the login-template    
    my $appliance = $c->config->{'appliance'};
    my $hostname = $appliance->system->hostname();
    my $domainname = $appliance->system->domainname();
    my $ip_address = $appliance->system->ip_address();
    $c->stash->{'hostname'} = $hostname;
    $c->stash->{'domainname'} = $domainname;
    $c->stash->{'ip_address'} = $ip_address;
    
    # If either of above don't work out, send to the login page
    $c->stash->{'template'} = 'login.tt2';
}


=head1 AUTHOR

Matthias,L0LR00M,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

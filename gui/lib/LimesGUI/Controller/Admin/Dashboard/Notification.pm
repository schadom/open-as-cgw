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


package LimesGUI::Controller::Admin::Dashboard::Notification;

use namespace::autoclean;
use base 'LimesGUI::Controller';
use Error qw(:try);
use Data::Dumper;

sub index : Private
{
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    $c->response->redirect($c->uri_for("/admin/dashboard/notification/fetch"));
}


sub fetch : Local
{
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};
    my $err_str = '';

    # if there are pending notifications
    # the notification-button should call a *_confirm method, which does 
    # the thing and redirects to fetch again. if there is no notification to 
    # fetch the overlay should disappear and display the dashboard 
    if (defined($c->session->{'notifications'}) && 
        @{$c->session->{'notifications'}} > 0)
    {
        # the current "notification" is always the last element
        # in the array. confirming an element means, deleting it from the 
        # array -- this is at least done by the simple_confirm routine.
        $err_str = @{$c->session->{'notifications'}}[@{$c->session->{'notifications'}}-1];


        # TODO error handling if err_str is shit

        $c->stash->{'class'} = 'success';
        $c->stash->{'heading'} = 'dashboard_notification_' . $err_str. '_heading';
        $c->stash->{'text'} = 'dashboard_notification_' . $err_str;
        $c->stash->{'link_text'} = 'proceed';
        $c->stash->{'proceed_only'} = 'yes';
        $c->stash->{'link_url'} = '/admin/dashboard/notification/simple_confirm';

        # some custom adeptions to the notification field
        # depending on the error
        if ($err_str eq 'notify_password')
        {
            $c->stash->{'class'} = 'warning';
        }

        elsif ($err_str eq 'notify_firewall')
        {
            $c->stash->{'link_url'} = '/admin/dashboard/notification/firewall_confirm';
        }

        elsif ($err_str eq 'notify_ip')
        {
            $c->stash->{'link_url'} = '/admin/dashboard/notification/ip_confirm';
        }
        $c->stash->{'template'} = 'admin/dashboard/notification.tt2';
    }
    else
    {
        $c->response->redirect($c->uri_for("/admin/dashboard/dashboard"));
    }
}

sub simple_confirm : Local
{
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};

    pop(@{$c->session->{'notifications'}});

    $c->response->redirect($c->uri_for("/admin/dashboard/notification/fetch"));
}


sub ip_confirm : Local
{
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};
    pop(@{$c->session->{'notifications'}});

    try 
    {
        $appliance->unset_alert_notify_nic_change();
        $appliance->system->net_notify('0');
        $appliance->system->set_net_user_change(2);
        $appliance->system->commit;
    }
    catch Underground8::Exception with
    {   
        my $E = shift;
        $c->session->{'exception'} = $E;
        $c->res->redirect($c->uri_for('/error'));
    };

    $c->response->redirect($c->uri_for("/admin/dashboard/notification/fetch"));
}



sub firewall_confirm : Local
{
    my ( $self, $c ) = @_;
    my $appliance = $c->config->{'appliance'};
    pop(@{$c->session->{'notifications'}});

    # do some stuff to keep it real

    $c->response->redirect($c->uri_for("/admin/dashboard/notification/fetch"));
}

1;

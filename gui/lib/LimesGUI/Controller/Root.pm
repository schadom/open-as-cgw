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


package LimesGUI::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

LimesGUI::Controller::Root - Root Controller for LimesGUI

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->res->redirect($c->uri_for('/admin'));
}

sub index : Local {
    my ($self, $c) = @_;
    
    $c->response->redirect($c->uri_for('/admin'));
}

=head2 auto

=cut 

sub auto : Private {
    my ($self, $c) = @_;
    
    # Allow unauthenticated users to reach the login page.  This
    # allows anauthenticated users to reach any action in the Login
    # controller.  To lock it down to a single action, we could use:
    #   if ($c->action eq $c->controller('Login')->action_for('index'))
    # to only allow unauthenticated access to the C<index> action we
    # added above.
    if ($c->controller eq $c->controller('Login')) {
        return 1;
    }
  
    # If a user doesn't exist, force login
    if (!$c->user_exists) {
        # Dump a log message to the development server debug output
        $c->log->debug('***Root::auto User not found, forwarding to /login');

        my $path = $c->req->path;

        $c->session->{'unauth_path'} = $path;

        # Redirect the user to the login page
        $c->response->redirect($c->uri_for('/login'));
        # Return 0 to cancel 'post-auto' processing and prevent use of application
        return 0;
    }
  
    # User found, so return 1 to continue with processing after this 'auto'
    return 1;
}

=head2 end

Attempt to render a view, if needed.

=cut 

=head1
Catalyst::Plugin::FillInForm does not play well with Catalyst's ActionClass('RenderView') so you may want to change your end method:
http://search.cpan.org/~mramberg/Catalyst-Plugin-FillInForm-0.09/lib/Catalyst/Plugin/FillInForm.pm (Note)
=cut

sub end : ActionClass('RenderView') {
    my $self = shift;
    my $c = shift;
    
    if (defined($c->stash->{'template'}))
    {
        if (defined($c->stash->{'no_wrapper'}))
        {
            $c->forward( 'LimesGUI::View::TTplain' );
        }
        else
        {
            $c->forward( 'LimesGUI::View::TT' );
        }
    }
}

=head1 AUTHOR

Matthias Pfoetscher, underground_8
Iulian Radu, underground_8

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

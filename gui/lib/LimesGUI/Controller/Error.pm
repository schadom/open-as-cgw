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


package LimesGUI::Controller::Error;

use strict;
use warnings;
use base 'LimesGUI::Controller';

use Data::FormValidator::Constraints qw(:closures :regexp_common);
use Data::Dumper;
=head1 NAME

LimesGUI::Controller::Exception - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

my $u8_support = 'team@openas.org';

sub index : Private {
    my ( $self, $c ) = @_;

    my $exception = $c->session->{'exception'};
    
    if ($c->session->{'exception'})
    {
        $c->log->debug(Dumper $exception);
        $c->stash->{'exception'} = $exception;
        $c->stash->{'nav'} = 'without_subnav';
        $c->stash->{'template'} = 'error.tt2';
    }
    else
    {
        $c->res->redirect($c->uri_for('/admin'));
    }
}   

sub send_error_report : Local
{
    my ($self,$c) = @_;

    if ($c->session->{'exception'})
    {
        my $exception = $c->session->{'exception'};
        $c->stash->{'exception'} = $exception;
        $c->stash->{'nav'} = 'without_subnav';
        $c->stash->{'template'} = 'error/send_report.tt2';
    }
    else
    {
        $c->res->redirect($c->uri_for('/admin'));
    }
}

sub commit_error_report : Local
{
    my ($self, $c) = @_;

    if ($c->session->{'exception'})
    {
        my $form_profile = {
            required => [qw(
                admin_name
                email_address

            )],
            optional => [qw(
                phone_nr
                want_contact
                comment
            )],
            constraint_methods => {
                email_address => email(),
            }
        };

        my $result = $self->process_form($c,$form_profile);

        if ($result->success)
        {
            my $admin_name = $c->request->params->{'admin_name'};
            my $email_address = $c->request->params->{'email_address'};
            my $phone_number = $c->request->params->{'phone_nr'};
            my $want_contact = $c->request->params->{'want_contact'};
            my $comment = $c->request->params->{'comment'};

            my $exception = $c->session->{'exception'};
            delete $c->session->{'exception'};

            $c->stash->{'admin_name'} = $admin_name;
            $c->stash->{'email_address'} = $email_address;
            $c->stash->{'phone_number'} = $phone_number;
            $c->stash->{'want_contact'} = $want_contact;
            $c->stash->{'comment'} = $comment;
            $c->stash->{'exception'} = $exception;

            # render email template
            my $mail_body = $c->view('TT')->render($c,'email/error_report.tt2');

            $c->email(
                header => [
                    From => "$admin_name <$email_address>",
                    To => $u8_support,
                    Subject => "Limes AS Error Report from $admin_name",
                ],
                body => $mail_body
            );
            $c->stash->{'template'} = 'error/error_report_sent.inc.tt2';
        }
        else
        {
            $c->stash->{'template'} = 'error/send_report_form.inc.tt2';
        }
        $c->stash->{'nav'} = 'without_subnav';
    }
    else
    {
        $c->res->redirect($c->uri_for('/admin'));
    }
}


=head1 AUTHOR

Matthias Pfoetscher, underground_8

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

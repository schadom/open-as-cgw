package Catalyst::Plugin::Email;

use strict;
use Email::Sender;
use Email::MIME;
use Email::MIME::Creator;
use Carp qw/croak/;

#
# Switched to the new Email::Sender
# because the Email::Send was deprecated 
# [ds, 14.08.2016]
#

our $VERSION = '1.300021-1';

sub email {
    my $c = shift;
    my $email = $_[1] ? {@_} : $_[0];
    $email = Email::MIME->create(%$email);
    my $args = $c->config->{email} || [];
    my @args = @{$args};
    my $class;
    unless ( $class = shift @args ) {
        $class = 'SMTP';
        unshift @args, 'localhost';
    }
    send $class => $email, @args;
}

1;

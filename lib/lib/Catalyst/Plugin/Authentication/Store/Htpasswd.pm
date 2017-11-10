#!/usr/bin/perl

package Catalyst::Plugin::Authentication::Store::Htpasswd;

use strict;
use warnings;

our $VERSION = '0.02';

use Catalyst::Plugin::Authentication::Store::Htpasswd::Backend;

sub setup {
    my $c = shift;

    $c->default_auth_store(
        Catalyst::Plugin::Authentication::Store::Htpasswd::Backend->new(
            $c->config->{authentication}{htpasswd}
        )
    );

	$c->NEXT::setup(@_);
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::Htpasswd - Authentication
database in C<< $c->config >>.

=head1 SYNOPSIS

    use Catalyst qw/
      Authentication
      Authentication::Store::Htpasswd
      Authentication::Credential::Password
      /;

    __PACKAGE__->config->{authentication}{htpasswd} = "passwdfile";

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->login( $c->req->param("login"), $c->req->param("password"), );
    }

=head1 DESCRIPTION

This plugin uses C<Authen::Htpasswd> to let your application use C<.htpasswd>
files for it's authentication storage.

=head1 METHODS

=head2 setup

This method will popultate C<< $c->config->{authentication}{store} >> so that
L<Catalyst::Plugin::Authentication/default_auth_store> can use it.

=head1 CONFIGURATION

=head2 $c->config->{authentication}{htpasswd}

The path to the htpasswd file.

=head1 AUTHORS

Yuval Kogman C<nothingmuch@woobling.org>

David Kamholz C<dkamholz@cpan.org>

=head1 SEE ALSO

L<Authen::Htpasswd>.

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut



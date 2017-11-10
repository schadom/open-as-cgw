#!/usr/bin/perl

package Catalyst::Plugin::Authentication::Store::Htpasswd::Backend;
use base qw/Class::Accessor::Fast/;

use strict;
use warnings;

use Authen::Htpasswd;
use Catalyst::Plugin::Authentication::Store::Htpasswd::User;

BEGIN { __PACKAGE__->mk_accessors(qw/file/) }

sub new {
    my ( $class, $file, %extra ) = @_;

    bless { file => ( ref $file ? $file : Authen::Htpasswd->new($file, \%extra) ) }, $class;
}

sub get_user {
    my ( $self, $id ) = @_;
    Catalyst::Plugin::Authentication::Store::Htpasswd::User->new( $self, $self->file->lookup_user($id) );
}

sub user_supports {
    my $self = shift;

    # this can work as a class method
    Catalyst::Plugin::Authentication::Store::Htpasswd::User->supports(@_);
}

sub from_session {
	my ( $self, $c, $id ) = @_;
	$self->get_user( $id );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::Htpasswd::Backend - Htpasswd
authentication storage backend.

=head1 SYNOPSIS

    # you probably just want Store::Htpasswd under most cases,
    # but if you insist you can instantiate your own store:

    use Catalyst::Plugin::Authentication::Store::Htpasswd::Backend;

    use Catalyst qw/
        Authentication
        Authentication::Credential::Password
    /;

    my %users = (
        user => { password => "s3cr3t" },
    );
    
    our $users = Catalyst::Plugin::Authentication::Store::Htpasswd::Backend->new(\%users);

    sub action : Local {
        my ( $self, $c ) = @_;

        $c->login( $users->get_user( $c->req->param("login") ),
            $c->req->param("password") );
    }

=head1 DESCRIPTION

You probably want L<Catalyst::Plugin::Authentication::Store::Htpasswd>, unless
you are mixing several stores in a single app and one of them is Htpasswd.

Otherwise, this lets you create a store manually.

=head1 METHODS

=head2 new $hash_ref

Constructs a new store object, which uses the supplied hash ref as it's backing
structure.

=head2 get_user $id

Keys the hash by $id and returns the value.

If the return value is unblessed it will be blessed as
L<Catalyst::Plugin::Authentication::User::Hash>.

=head2 user_supports

Chooses a random user from the hash and delegates to it.

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut



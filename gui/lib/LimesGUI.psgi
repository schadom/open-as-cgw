#!/usr/bin/env perl
use strict;
use warnings;
 
use Plack::Builder;
use LimesGUI;
 
#my $app = sub { LimesGUI->run(@_) };
 
my $app = LimesGUI->apply_default_middlewares(LimesGUI->psgi_app(@_));

#builder {
# enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
#        "Plack::Middleware::ReverseProxy";
# $app;
#};

#!/usr/bin/env perl
use warnings;
use strict;
use Daemon::Control;

my $app_home = '/var/www/LimesGUI';
my $program  = '/usr/bin/starman';
my $name     = 'LimesGUI';
my $workers  = 1;
my $pid_file = '/var/run/LimesGUI.pid';
my $socket   = '/tmp/LimesGUI.socket';

Daemon::Control->new({
    name        => $name,
    lsb_start   => '$nginx',
    lsb_stop    => '$nginx',
    lsb_sdesc   => $name,
    lsb_desc    => $name,
    path        => $app_home . '/LimesGUI.start.pl',

    user        => 'www-data',
    group       => 'limes',
    directory   => $app_home,
    program     => "$program -Ilib LimesGUI.psgi --workers $workers --listen $socket",

    pid_file    => $pid_file,
    stderr_file => '/var/log/open-as-cgw/LimesGUI.log',
    stdout_file => '/var/log/open-as-cgw/LimesGUI.log',

    fork        => 2,
})->run;

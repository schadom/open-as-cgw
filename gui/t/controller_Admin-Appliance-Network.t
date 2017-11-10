use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Appliance::Network' }

ok( request('/admin/appliance/network')->is_success, 'Request should succeed' );



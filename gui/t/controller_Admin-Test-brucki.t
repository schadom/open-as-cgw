use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Test::brucki' }

ok( request('/admin/test/brucki')->is_success, 'Request should succeed' );



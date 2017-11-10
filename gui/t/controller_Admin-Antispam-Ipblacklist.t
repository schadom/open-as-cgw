use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Antispam::Ipblacklist' }

ok( request('/admin/antispam/ipblacklist')->is_success, 'Request should succeed' );



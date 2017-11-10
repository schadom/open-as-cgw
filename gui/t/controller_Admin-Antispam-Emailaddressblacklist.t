use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Antispam::Emailaddressblacklist' }

ok( request('/admin/antispam/emailaddressblacklist')->is_success, 'Request should succeed' );



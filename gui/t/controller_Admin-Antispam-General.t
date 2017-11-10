use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Antispam::General' }

ok( request('/admin/antispam/general')->is_success, 'Request should succeed' );



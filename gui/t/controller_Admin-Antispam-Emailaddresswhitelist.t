use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Antispam::Emailaddresswhitelist' }

ok( request('/admin/antispam/emailaddresswhitelist')->is_success, 'Request should succeed' );



use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Notification::Alarm' }

ok( request('/admin/notification/alarm')->is_success, 'Request should succeed' );



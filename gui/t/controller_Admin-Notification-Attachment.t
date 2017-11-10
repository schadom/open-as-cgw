use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Notification::Attachment' }

ok( request('/admin/notification/attachment')->is_success, 'Request should succeed' );



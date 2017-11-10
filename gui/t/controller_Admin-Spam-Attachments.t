use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Spam::Attachments' }

ok( request('/admin/spam/attachments')->is_success, 'Request should succeed' );



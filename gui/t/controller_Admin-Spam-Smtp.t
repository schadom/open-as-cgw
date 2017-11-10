use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LimesGUI' }
BEGIN { use_ok 'LimesGUI::Controller::Admin::Spam::Smtp' }

ok( request('/admin/spam/smtp')->is_success, 'Request should succeed' );



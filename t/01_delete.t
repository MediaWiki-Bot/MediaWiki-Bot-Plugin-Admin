# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 7;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;
my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};

SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 4;
    }

    my $bot = MediaWiki::Bot->new({
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)',
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
        login_data => { username => $username, password => $password },
    });

    $bot->delete("User:$username/01_delete.t");
    my $text = $bot->get_text("User:$username/01_delete.t");
    is($text, undef, 'Page does not exist yet');

    my $rand = rand();
    $bot->edit({
        page    => "User:$username/01_delete.t",
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)',
    });
    $text = $bot->get_text("User:$username/01_delete.t");
    is($text, $rand, 'Page created successfully');

    $bot->delete("User:$username/01_delete.t", 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)');
    $text = $bot->get_text("User:$username/01_delete.t");
    isnt($text, $rand, 'Page does not contain $rand');
    is($text,   undef, 'Page was deleted');

    $bot->undelete("User:$username/01_delete.t", 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)');
    $text = $bot->get_text("User:$username/01_delete.t");
    is($text, $rand, 'Page does contain $rand');

    $bot->delete("User:$username/01_delete.t", 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)');
    $text = $bot->get_text("User:$username/01_delete.t");
    isnt($text, $rand, 'Page does not contain $rand');
    is($text,   undef, 'Page was deleted');
}

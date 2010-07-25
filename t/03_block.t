# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 8;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;
my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};

SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 8;
    }

    my $summary  = 'MediaWiki::Bot::Plugin::Admin tests (03_block.t)';
    my $bot = MediaWiki::Bot->new({
        agent   => $summary,
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
        login_data => { username => $username, password => $password },
    });

    $bot->unblock($username, $summary);
    my $is_blocked = $bot->is_blocked($username);
    is($is_blocked, 0, "[[User:$username]] is unblocked");

    my $duration = '1 minute';
    $bot->block({
        user        => $username,
        length      => $duration,
        summary     => $summary,
        autoblock   => 0,
    });
    my $block = $bot->get_log({
        type    => 'block',
        user    => $username,
        title   => "User:$username",
    });
    is($block->[0]->{'comment'},    $summary,           'Block summary is correct');
    is($block->[0]->{'user'},       $username,          'Block made by right user');
    is($block->[0]->{'action'},     'block',            'Block is registered as a block');
    like($block->[0]->{'title'},    qr/\Q$username\E/,  'Block was set on the right user');
    is($block->[0]->{'type'},       'block',            'Block is registered as a block');
    is($block->[0]->{'block'}->{'duration'}, $duration, 'Block was set for the right duration');

    $bot->unblock($username, $summary);
    $is_blocked = $bot->is_blocked($username);
    is($is_blocked, 0, "[[User:$username]] is unblocked");
}

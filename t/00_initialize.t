# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    push @INC, "./lib";
    use_ok('MediaWiki::Bot');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $bot = MediaWiki::Bot->new({
    agent   => 'MediaWiki::Bot::Plugin::Admin test (00_initialize.t)',
});

ok(defined $bot,                        'new() works');
isa_ok($bot, 'MediaWiki::Bot',          'Right class');
my @methods = @MediaWiki::Bot::Plugin::Admin::EXPORT;
can_ok($bot, @methods);


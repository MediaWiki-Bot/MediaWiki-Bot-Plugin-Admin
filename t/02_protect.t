# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 13;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;

my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};
my $page     = "User:$username/02 protect.t";
my $cascade_page = "User:$username/02 protect.t (2)";

SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 13;
    }

    # Create bot objects to play with
    my $bot = MediaWiki::Bot->new({
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
        login_data => { username => $username, password => $password },
    });
    my $anon = MediaWiki::Bot->new({
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
    });

    # Ensure test pages aren't protected
    $bot->unprotect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
    my $protected = $bot->get_protection($page);
    is($protected, undef, "[[$page]] isn't protected");
    $bot->protect($cascade_page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
    $protected = $bot->get_protection($page);
    is($protected, undef, "[[$cascade_page]] isn't protected");

    # Create a page to test with
    my $rand = rand();
    $bot->edit({
        page    => $page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    my $text = $bot->get_text($page);
    is($text, $rand, 'Successfully edited page');

    # Protect the page, and fail to edit it anonymously
    $bot->protect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)', 'sysop', '', 'infinite', 0);
    my $cmp_protection = [
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'type' => 'edit'
          }
        ];
    my $protection = $bot->get_protection($page);
    is_deeply($protection, $cmp_protection, 'Protection applied correctly');

    $rand = rand();
    $anon->edit({
        page    => $page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $text = $bot->get_text($page);
    isnt($text, $rand, q{Shouldn't be able to edit anon});

    # Successfully edit the page with a sysop account
    $rand = rand();
    $bot->edit({
        page    => $page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $text = $bot->get_text($page);
    is($text, $rand, "Should be able to edit [[$page]] with sysop account");

    # Fail to edit through protection
    $rand = rand();
    $anon->edit({
        page    => $cascade_page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $text = $bot->get_text($cascade_page);
    isnt($text, $rand, "Shouldn't be able to edit [[$cascade_page]] anonymously");

    # Cascade-protect a test page, then transclude it into another
    $bot->protect(
        $cascade_page,
        'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        'sysop', 'sysop', undef, 1 # edit, move, expiry, cascading
    );
    $cmp_protection = [
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'cascade' => '',
            'type' => 'edit'
          },
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'type' => 'move'
          }
        ];
    $protection = $bot->get_protection($cascade_page);
    is_deeply($protection, $cmp_protection, "[[$cascade_page]] protected properly");

    $rand = rand();
    $bot->edit({
        page    => $page,
        text    => $rand . "{{$cascade_page}}",
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $text = $bot->get_text($page);
    like($text, qr/\Q{{$cascade_page}}\E/, 'Set cascading');

    # 6: Fail to edit a page transcluding a cascade-protected page anonymously
    $rand = rand();
    $anon->edit({
        page    => $page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $text = $bot->get_text($page);
    isnt($text, $rand, q{Shouldn't be able to edit anon after setting cascading});

    # Remove cascading protection and edit anonymously
    $bot->unprotect($cascade_page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
    $protection = $bot->get_protection($cascade_page);
    is($protection, undef, "[[$cascade_page]] no longer protected");

    $bot->unprotect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
    $protection = $bot->get_protection($page);
    is($protection, undef, "[[$page]] no longer protected");

    $rand = rand();
    $anon->edit({
        page    => $page,
        text    => $rand,
        summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
    });
    $bot->purge_page($page);
    $text = $bot->get_text($page);
    is($text, $rand, 'Should be able to edit anon');
}

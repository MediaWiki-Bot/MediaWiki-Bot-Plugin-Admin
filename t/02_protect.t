# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 15;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;

my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};

SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 15;
    }
    my $page         = "User:$username/02 protect.t";
    my $cascade_page = "User:$username/02 protect.t (2)";

    # Create bot objects to play with
    my $admin = MediaWiki::Bot->new({
        # debug   => 2,
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
        login_data => { username => $username, password => $password },
    });
    my $anon = MediaWiki::Bot->new({
        # debug   => 2,
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        host    => $ENV{'PWPAdminHost'},
        path    => $ENV{'PWPAdminPath'},
    });

    {   # Ensure test pages aren't protected
        $admin->unprotect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
        my $protected = $admin->get_protection($page);
        is($protected, undef, "[[$page]] isn't protected");
    }

    {   # Ensure test pages aren't protected
        $admin->unprotect($cascade_page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
        my $protected = $admin->get_protection($page);
        is($protected, undef, "[[$cascade_page]] isn't protected");
    }

    {   # Make sure we can edit
        my $rand = rand();
        $admin->edit({
            page    => $page,
            text    => $rand,
            summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        });
        my $text = $admin->get_text($page);
        is($text, $rand, 'Successfully edited page');
    }

    {   # Protect the page
        $admin->protect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)', 'sysop', '', 'infinite');
        my $cmp_protection = [
              {
                'expiry' => 'infinity',
                'level' => 'sysop',
                'cascade' => '',
                'type' => 'edit'
              }
            ];
        my $protection = $admin->get_protection($page);
        is_deeply($protection, $cmp_protection, 'Protection applied correctly');

        {   # Fail to edit it anonymously
            my $rand = rand();
            $anon->edit({
                page    => $page,
                text    => $rand,
                summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
            });
            my $text = $admin->get_text($page);
            isnt($text, $rand, q{Shouldn't be able to edit anon});
        }

        {   # Successfully edit the page with a sysop account
            my $rand = rand();
            $admin->edit({
                page    => $page,
                text    => $rand,
                summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
            });
            my $text = $admin->get_text($page);
            is($text, $rand, "Should be able to edit [[$page]] with sysop account");
        }
    }

    {   # Cascade-protect a test page
        $admin->protect(
            $cascade_page,
            'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
            'sysop', 'sysop', undef, 1 # edit, move, expiry, cascading
        );
        my $cmp_protection = [
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
        my $protection = $admin->get_protection($cascade_page);
        is_deeply($protection, $cmp_protection, "[[$cascade_page]] protected properly");

        {   # Transclude it into another
            my $rand = rand();
            $admin->edit({
                page    => $page,
                text    => $rand . "{{$cascade_page}}",
                summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
            });
            my $text = $admin->get_text($page);
            like($text, qr/\Q{{$cascade_page}}\E/, 'Set cascading');
        }

        {   # Fail to edit a page transcluding a cascade-protected page anonymously
            my $rand = rand();
            $anon->edit({
                page    => $page,
                text    => $rand,
                summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
            });
            my $text = $admin->get_text($page);
            isnt($text, $rand, q{Shouldn't be able to edit anon after setting cascading});
            is($text, $text,   q{Should be the same as before});
        }
    }

    {   # Remove protection and edit anonymously
        {
            $admin->unprotect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
            my $protection = $admin->get_protection($page);
            is($protection, undef, "[[$page]] no longer protected");
        }

        {
            $admin->unprotect($cascade_page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
            my $protection = $admin->get_protection($cascade_page);
            is($protection, undef, "[[$cascade_page]] no longer protected");
        }

        my $rand = rand();
        $anon->edit({
            page    => $page,
            text    => $rand,
            summary => 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)',
        });
        $admin->purge_page($page);
        my $text = $admin->get_text($page);
        is($text, $rand, 'Should be able to edit anon');
    }

    {   # Cleanup
        {
            $admin->unprotect($page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
            my $protection = $admin->get_protection($page);
            is($protection, undef, "[[$page]] no longer protected");
        }

        {
            $admin->unprotect($cascade_page, 'MediaWiki::Bot::Plugin::Admin tests (02 protect.t)');
            my $protection = $admin->get_protection($cascade_page);
            is($protection, undef, "[[$cascade_page]] no longer protected");
        }
    }

}

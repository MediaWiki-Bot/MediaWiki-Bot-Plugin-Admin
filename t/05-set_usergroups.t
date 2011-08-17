use strict;
use warnings;
use Test::More tests => 1;
use MediaWiki::Bot;
my $t = __FILE__;

my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};
SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 1;
    }
    my $bot = MediaWiki::Bot->new({
        agent   => "MediaWiki::Bot tests ($t)",
        host    => $ENV{'PWPAdminHost'} || 'test.wikipedia.org',
        path    => $ENV{'PWPAdminPath'} || 'w',
        login_data => { username => $username, password => $password },
    });

    my @set_groups = qw(editor);
    my @new_usergroups = $bot->set_usergroups('Set userrights-testing', \@set_groups, $t);
    my %new_usergroups = map { $_ => 1 } @new_usergroups;
    delete $new_usergroups{ $_ } for qw(* user autoconfirmed);
    is_deeply [ sort keys %new_usergroups ], [ sort @set_groups ], q{Rights set to what we wanted};
}

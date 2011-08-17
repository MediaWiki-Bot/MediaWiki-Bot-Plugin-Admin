use strict;
use warnings;
use Test::More tests => 2;
use MediaWiki::Bot;
my $t = __FILE__;

my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};
SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 2;
    }
    my $bot = MediaWiki::Bot->new({
        agent   => "MediaWiki::Bot tests ($t)",
        host    => $ENV{'PWPAdminHost'} || 'test.wikipedia.org',
        path    => $ENV{'PWPAdminPath'} || 'w',
        login_data => { username => $username, password => $password },
    });

    my @groups = qw(editor);
    my @added_usergroups = $bot->add_usergroups('Set userrights-testing', \@groups, $t);
    is_deeply \@added_usergroups, \@groups, 'Added what we asked for';
    
    my @removed_usergroups = $bot->remove_usergroups('Set userrights-testing', \@groups, $t);
    is_deeply \@removed_usergroups, \@groups, 'Removed what we asked for';
}

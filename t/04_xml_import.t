use strict;
use warnings;
use Test::More tests => 1;
use MediaWiki::Bot;

my $username = $ENV{'PWPAdminUsername'};
my $password = $ENV{'PWPAdminPassword'};

SKIP: {
    unless (defined($username) and defined($password)) {
        skip 'Set PWPAdminUsername and PWPAdminPassword in your environment to run tests for this plugin', 1;
    }

    my $bot = MediaWiki::Bot->new({
        agent   => 'MediaWiki::Bot::Plugin::Admin tests (01_delete.t)',
        host    => $ENV{'PWPAdminHost'} || 'test.wikipedia.org',
        path    => $ENV{'PWPAdminPath'} || 'w',
        login_data => { username => $username, password => $password },
    });

    my $res = $bot->xml_import('t/testfile.xml');
    skip 'Need importupload permission', 1 if ($bot->{error}->{details} =~ m/^cantimport-upload/);
    ok $res, 'XML upload import OK' or diag explain $res;
}

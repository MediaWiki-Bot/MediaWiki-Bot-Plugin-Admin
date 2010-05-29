# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;

$wikipedia=MediaWiki::Bot->new;

if(defined($ENV{'PWPMakeTestSetWikiHost'})) {
	$wikipedia->set_wiki($ENV{'PWPMakeTestSetWikiHost'}, $ENV{'PWPMakeTestSetWikiDir'});
}

SKIP: {
if(defined($ENV{'PWPSkipAdminTests'}) and $ENV{'PWPSkipAdminTests'} eq 'true' or !defined($ENV{'PWPAdmin'})) {
	skip 'Skipping admin tests per $ENV',4;
}

sleep 2;

$wikipedia->login($ENV{'PWPAdmin'}, $ENV{'PWPAdminPW'});

$text = $wikipedia->get_text("User:ST47/deletetest");
ok(!defined($text),"Page does not exist yet");

$rand = rand();
$wikipedia->edit("User:ST47/deletetest", $rand);
$text = $wikipedia->get_text("User:ST47/deletetest");
is($text,$rand,"Page created successfully");
my $status = $wikipedia->delete("User:ST47/deletetest","MediaWiki::Bot tests");
#eval { use Data::Dumper; print STDERR Dumper($status); };
#if ($@) {print "#Couldn't load Data::Dumper\n"}
#ok( $status->isa("HTTP::Response") );
$text = $wikipedia->get_text("User:ST47/deletetest");
isnt($text,$rand,"Page does not contain \$rand");
ok(!defined($text),"Page was deleted");
}

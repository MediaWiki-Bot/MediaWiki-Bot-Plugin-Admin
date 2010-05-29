# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MediaWiki::Bot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use MediaWiki::Bot;

$wikipedia=MediaWiki::Bot->new("PWP tests");

if(defined($ENV{'PWPMakeTestSetWikiHost'})) {
	$wikipedia->set_wiki($ENV{'PWPMakeTestSetWikiHost'}, $ENV{'PWPMakeTestSetWikiDir'});
}

SKIP: {
if(defined($ENV{'PWPSkipAdminTests'}) and $ENV{'PWPSkipAdminTests'} eq 'true' or !defined($ENV{'PWPAdmin'})) {
	skip 'Skipping admin tests per $ENV',8;
}

$wikipedia->login($ENV{'PWPAdmin'}, $ENV{'PWPAdminPW'});

$anon=MediaWiki::Bot->new("PWP tests");

$rand = rand();
$wikipedia->edit("User:ST47/protecttest", $rand);
sleep 1;
$text = $wikipedia->get_text("User:ST47/protecttest");
$text =~ s/\n//;
is($text,$rand,"Successfully edited page");

$status = $wikipedia->protect("User:ST47/protecttest","MediaWiki::Bot tests","sysop");
$rand = rand();
sleep 1;
$anon->edit("User:ST47/protecttest", $rand);
sleep 1;
$text = $anon->get_text("User:ST47/protecttest");
$text =~ s/\n//;
isnt($text,$rand,"Shouldn't be able to edit anon");
$rand = rand();
$wikipedia->edit("User:ST47/protecttest", $rand);
sleep 1;
$text = $wikipedia->get_text("User:ST47/protecttest");
$text =~ s/\n//;
is($text,$rand,"Should be able to edit sysop");
$rand = rand();
$anon->edit("User:ST47/cascadetest", $rand);
sleep 1;
$text = $anon->get_text("User:ST47/cascadetest");
$text =~ s/\n//;
is($text,$rand,"Should be able to edit cascadetarget anon after setting not cascading");

$status = $wikipedia->protect("User:ST47/protecttest","MediaWiki::Bot tests","sysop","sysop",undef,1);
$rand = rand();
$wikipedia->edit("User:ST47/protecttest", $rand.'{{User:ST47/cascadetest}}');
sleep 1;
$text = $wikipedia->get_text("User:ST47/protecttest");
$text =~ s/\n//;
like($text,qr/cascadetest/,"Set cascading");
$rand = rand();
$anon->edit("User:ST47/protecttest", $rand);
sleep 1;
$text = $anon->get_text("User:ST47/protecttest");
$text =~ s/\n//;
isnt($text,$rand,"Shouldn't be able to edit anon after setting cascading");
$rand = rand();
$anon->edit("User:ST47/cascadetest", $rand);
sleep 1;
$text = $anon->get_text("User:ST47/cascadetest");
$text =~ s/\n//;
isnt($text,$rand,"Shouldn't be able to edit cascadetarget anon after setting cascading");

$status = $wikipedia->protect("User:ST47/protecttest","MediaWiki::Bot tests","");
$rand = rand();
sleep 1;
$anon->edit("User:ST47/protecttest", $rand);
sleep 1;
$text = $anon->get_text("User:ST47/protecttest");
$text =~ s/\n//;
is($text,$rand,"Should be able to edit anon");
}

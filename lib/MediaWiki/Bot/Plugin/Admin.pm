package MediaWiki::Bot::Plugin::Admin;
use strict;
use warnings;
#use diagnostics;
use locale;
use POSIX qw(locale_h);
setlocale(LC_ALL, "en_US.UTF-8");

our $VERSION = '0.0.1';

=head1 NAME

MediaWiki::Bot::Plugin::Admin

=head1 SYNOPSIS

use MediaWiki::Bot;

my $editor = MediaWiki::Bot->new('Account');
$editor->login('Account', 'password');

=head1 DESCRIPTION

MediaWiki::Bot is a framework that can be used to write Wikipedia bots.

=head1 AUTHOR

The Perlwikipedia team

=head1 METHODS

=over 4

=item import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with MediaWiki/Bot.pm.

=cut

sub import {
    no strict 'refs';
    my @methods = qw(rollback);
    foreach my $method (@methods) {
        *{caller() . "::$method"} = \&{$method};
    }
}


=item rollback($pagename, $username, $summary, $markbot)

Uses rollback to revert to the last revision of $pagename not edited by the latest editor of that page. If $username is not the last editor of $pagename, you will get an error, however it is a good idea to set this. If you do not, the latest edit(s) will be rolled back, and you could end up rolling back something you didn't intend to. Therefore, $username should be considered required. The remaining parameters are optional: $summary (to set a custom rollback edit summary), and $markbot (which marks both the rollback and the edits that were rolled back as bot edits).

    $bot->rollback("Linux", "Some Vandal");
    # OR
    $bot->rollback("Wikibooks:Sandbox", "Mike.lifeguard", "test", 1);

=cut

sub rollback {
    my $self      = shift;
    my $page      = shift;
    my $user      = shift;
    my $summary   = shift;
    my $markbot   = shift;

    my $hash = {
        action  => 'rollback',
        title   => $page,
        user    => $user,
        summary => $summary,
        markbot => $markbot,
    };
    my $res = $self->{api}->edit($hash);
    if (!$res) {
        carp 'Error code: ' . $self->{api}->{error}->{code};
        carp $self->{api}->{error}->{details};
        $self->{error} = $self->{api}->{error};
        return $self->{error}->{code};
    }
    else {
        return $res;
    }
}

1;


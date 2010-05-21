package MediaWiki::Bot::Plugin::Admin;
use strict;
use warnings;
#use diagnostics;
use Carp;
use locale;
use POSIX qw(locale_h);
setlocale(LC_ALL, "en_US.UTF-8");

our $VERSION = '0.0.1';

=head1 NAME

MediaWiki::Bot::Plugin::Admin

=head1 SYNOPSIS

    use MediaWiki::Bot;

    my $bot = MediaWiki::Bot->new('Account');
    $bot->login('Account', 'password');
    my @pages = ('one', 'two', 'three');
    foreach my $page (@pages) {
        $bot->delete($page, 'Deleting [[:Category:Pages to delete]] en masse');
    }

=head1 DESCRIPTION

A plugin to the MediaWiki::Bot framework to provide administrative functions to a bot.

=head1 AUTHOR

The Perlwikipedia team

=head1 METHODS

=head2 import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with MediaWiki::Bot. Typically, you will C<use MediaWiki::Bot> and nothing else. Just use the methods, MediaWiki::Bot automatically imports plugins if found.

=cut

use Exporter qw(import);
our @EXPORT = qw(rollback delete undelete delete_old_image block unblock protect unprotect);

=head2 rollback($pagename, $username[,$summary[,$markbot]])

Uses rollback to revert to the last revision of $pagename not edited by the latest editor of that page. If $username is not the last editor of $pagename, you will get an error; that's why it is a I<very good idea> to set this. If you do not, the latest edit(s) will be rolled back, and you could end up rolling back something you didn't intend to. Therefore, $username should be considered B<required>. The remaining parameters are optional: $summary (to set a custom rollback edit summary), and $markbot (which marks both the rollback and the edits that were rolled back as bot edits).

    $bot->rollback("Linux", "Some Vandal");
    # OR
    $bot->rollback("Wikibooks:Sandbox", "Mike.lifeguard", "rvv", 1);

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
        return $self->_handle_api_error();
    }
    else {
        return $res;
    }
}

=head2 delete($page[,$summary])

Deletes the page with the specified summary. If you omit $summary, a generic one will be used.

    my @pages = ('Junk page 1', 'Junk page 2', 'Junk page 3');
    foreach my $page (@pages) {
        $bot->delete($page, 'Deleting junk pages');
    }

=cut

sub delete {
    my $self    = shift;
    my $page    = shift;
    my $summary = shift || 'BOT: deleted page by command';

    my $res = $self->{api}->api(
        {
            action  => 'query',
            titles  => $page,
            prop    => 'info|revisions',
            intoken => 'delete'
        }
    );
    my ($id, $data) = %{ $res->{query}->{pages} };
    my $edittoken = $data->{deletetoken};
    $res = $self->{api}->api(
        {
            action => 'delete',
            title  => $page,
            token  => $edittoken,
            reason => $summary
        }
    );
    if (!$res) {
        return $self->_handle_api_error();
    }
    return $res;
}

=head2 undelete($page[,$summary])

Undeletes $page with $summary. If you omit $summary, a generic one will be used.

    $bot->undelete($page);

=cut

sub undelete {
    my $self    = shift;
    my $page    = shift;
    my $summary = shift || 'BOT: undeleting page by command';

    # http://meta.wikimedia.org/w/api.php?action=query&list=deletedrevs&titles=User:Mike.lifeguard/sandbox&drprop=token&drlimit=1
    my $tokenhash = {
        action  => 'query',
        list    => 'deletedrevs',
        titles  => $page,
        drlimit => 1,
        drprop  => 'token',
    };
    my $token_results = $self->{api}->api($tokenhash);
    my $token = $token_results->{'query'}->{'deletedrevs'}->[0]->{'token'};

    my $hash = {
        action  => 'undelete',
        title   => $page,
        reason  => $summary,
        token   => $token,
    };
    my $res = $self->{api}->api($hash);
    if (!$res) {
        return $self->_handle_api_error();
    }
    else {
        return $res;
    }
}

=head2 delete_old_image($page, $revision[,$summary])

Deletes the specified revision of the image with the specified summary. A generic summary will be used if you omit $summary.

# Get the revision number somehow
$bot->delete_old_image('Image

=cut

sub delete_old_image { # Needs to use the API
    my $self    = shift;
    my $page    = shift;
    my $id      = shift;
    my $summary = shift || 'BOT: deleting old version of image by command';
    my $image   = $page;

    $image =~ s/\s/_/g; # Why?
    $image =~ s/\%20/_/g; # Why? Just url-un-encode if we really need this.
    $image =~ s/^(Image:|File:)//gi;

    my $res = $self->_get($page, 'delete', "&oldimage=$id%21$image");
    unless ($res) { return; }
    my $options = {
        fields => {
            wpReason => $summary,
        },
    };
    $res = $self->{mech}->submit_form(%{$options});

    if (!$res) {
        return $self->_handle_api_error();
    }

    #use Data::Dumper;print Dumper($res);
    #print $res->decoded_content."\n";
    return $res;
}

=head2 block($user, $length,[$summary[,$anononly[,$autoblock[,$blockaccountcreation,[$blockemail,[$blocktalk]]]]]])

Blocks the user with the specified options. All options optional except $user and $length. Last four are true/false. Defaults to a generic summary, with all options disabled.

    my $user = 'Vandal account 2';
    $bot->block($user, 'infinite', 'Vandalism-only account', 1, 1, 1, 0, 1);

=cut

sub block {
    my $self       = shift;
    my $user       = shift;
    my $length     = shift;
    my $summary    = shift || 'BOT: blocked for abuse';
    my $anononly   = shift;
    my $autoblock  = shift;
    my $blockac    = shift;
    my $blockemail = shift;
    my $blocktalk  = shift;
    my $res;
    my $edittoken;

    if ($self->{'blocktoken'}) {
        $edittoken = $self->{'blocktoken'};
    }
    else {
        $res = $self->{api}->api(
            {
                action  => 'query',
                titles  => 'Main_Page',
                prop    => 'info|revisions',
                intoken => 'block'
            }
        );
        my ($id, $data) = %{ $res->{query}->{pages} };
        $edittoken = $data->{blocktoken};
        $self->{'blocktoken'} = $edittoken;
    }
    my $hash = {
        action => 'block',
        user   => $user,
        token  => $edittoken,
        expiry => $length,
        reason => $summary
    };
    $hash->{anononly}      = $anononly   if ($anononly);
    $hash->{autoblock}     = $autoblock  if ($autoblock);
    $hash->{nocreate}      = $blockac    if ($blockac);
    $hash->{noemail}       = $blockemail if ($blockemail);
    $hash->{allowusertalk} = 1           if (!$blocktalk);

    $res = $self->{api}->api($hash);
    if (!$res) {
        return $self->_handle_api_error();
    }

    return $res;
}

=head2 unblock($user[,$summary])

Unblocks the user with the specified summary.

    $bot->unblock('Jimbo Wales', 'Blocked in error');

=cut

sub unblock {
    my $self    = shift;
    my $user    = shift;
    my $summary = shift;

    my $res;
    my $edittoken;
    if ($self->{'unblocktoken'}) {
        $edittoken = $self->{'unblocktoken'};
    }
    else {
        $res = $self->{api}->api(
            {
                action  => 'query',
                titles  => 'Main_Page',
                prop    => 'info|revisions',
                intoken => 'unblock'
            }
        );
        my ($id, $data) = %{ $res->{query}->{pages} };
        $edittoken = $data->{unblocktoken};
        $self->{'unblocktoken'} = $edittoken;
    }

    my $hash = {
        action => 'unblock',
        user   => $user,
        token  => $edittoken
    };
    $res = $self->{api}->api($hash);
    if (!$res) {
        return $self->_handle_api_error();
    }

    return $res;
}

=head2 unprotect($page, $reason)

Unprotects a page. You can also set parameters for protect() such that the page is unprotected.

my @obsolete_protections = ('Main Page', 'Project:Community Portal', 'Template:Tlx');
foreach my $page (@obsolete_protections) {
    $bot->unprotect($page, 'Removing old obsolete page protection');
}

=cut

sub unprotect { # A convenience function
    my $self   = shift;
    my $page   = shift;
    my $reason = shift;

    return $self->protect($page, $reason, '', '');
}

=head2 protect($page, $reason, $editlvl, $movelvl, $time, $cascade)

Protects (or unprotects) the page. $editlvl and $movelvl may be '', 'autoconfirmed', or 'sysop'. $cascade is true/false.

=cut

sub protect {
    my $self    = shift;
    my $page    = shift;
    my $reason  = shift;
    my $editlvl = shift || 'all'; # 'all'? Or 'sysop'
    my $movelvl = shift || 'all';
    my $time    = shift || 'infinite';
    my $cascade = shift;

    if ($cascade and ($editlvl ne 'sysop' or $movelvl ne 'sysop')) {
        carp "Can't set cascading unless both editlvl and movelvl are sysop.";
    }
    my $res = $self->{api}->api(
        {
            action  => 'query',
            titles  => $page,
            prop    => 'info|revisions',
            intoken => 'protect'
        }
    );

    #use Data::Dumper;print STDERR Dumper($res);
    my ($id, $data) = %{ $res->{query}->{pages} };
    my $edittoken = $data->{protecttoken};
    my $hash      = {
        action      => 'protect',
        title       => $page,
        token       => $edittoken,
        reason      => $reason,
        protections => "edit=$editlvl|move=$movelvl",
        expiry      => $time
    };
    $hash->{'cascade'} = $cascade if ($cascade);
    $res = $self->{api}->api($hash);
    if (!$res) {
        return $self->_handle_api_error();
    }

    return $res;
}

1;

__END__

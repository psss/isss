#!/usr/bin/perl

use strict qw(subs vars);
use lib '../lib';

use Aid;
use Person;

# do it throught browse -- because of redirections
#header "Lidi";

QUEST: while (quest) {
	unless ($user->can("browse_persons")) {
		header "Lidičky";
		error "tak to vypadá, že tady v lidičkách se asi nemáš co brouzdat...";
		next QUEST;
	}

	my $birth;

	if (browse Person { header => "Lidi", checkboxform => "lidi.pl", navigform => "./" } ) { # something was found
		# make buttons
		print submit "action", "náhled";
		print submit "action", "upravit" if $user->can("edit_persons");
		print submit "action", "smazat" if $user->can("edit_persons");
		print submit "action", "registrace" if $user->can("view_registrations");
		print submit "action", "platby" if $user->can("view_payments");
		print submit "action", "karty" if $user->can("view_cards");
		print submit "action", "rozvrh";
		print submit "action", "tisk" if $user->can("prrrint");
		print submit "action", "zprávy" if $user->can("send_messages");
		print " anebo " if $user->can("edit_persons");
		$birth = " či ". submit("action", "porodit");
	}

	# creating new persons
	print submit("action", "přidat"), $birth, " nového človíčka?"
		if $user->can("edit_persons");

	footer;
}

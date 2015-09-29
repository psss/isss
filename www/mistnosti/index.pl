#!/usr/bin/perl

use strict qw(subs vars);
use lib '../lib';

use Aid;
use Room;

QUEST: while (quest) {
	unless ($user->can("browse_rooms")) {
		header "Místnosti";
		error "tak to vypadá, že tady v místnostech se asi nemáš co brouzdat...";
		next QUEST;
	}

	# if something was found
	if (browse Room { header => "Místnosti", checkboxform => "mistnosti.pl", navigform => "./"} ) {
		# make buttons
		print submit "action", "náhled" if $user->can("view_rooms");
		print submit "action", "upravit" if $user->can("edit_rooms");
		print submit "action", "rozvrh" if $user->can("view_schedule");
		print submit "action", "tisk" if $user->can("prrrint");
		print submit "action", "smazat" if $user->can("edit_rooms");

		print " anebo " if $user->can("edit_rooms");
	}

	print submit("action", "přidat"), " místnost?" if $user->can("edit_rooms");

	footer;
}

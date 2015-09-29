#!/usr/bin/perl

use strict qw(subs vars);
use lib '../lib';

use Aid;
use Activity;

QUEST: while (quest) {
	unless ($user->can("browse_activities")) {
		header "Aktivity";
		error "tak to vypadá, že tady v aktivitách asi nemáš co brouzdat...";
		next QUEST;
	}

	# if something was found
	if (browse Activity { header => "Aktivity", checkboxform => "aktivity.pl", navigform => "./" } ) {
		# make buttons
		print submit "action", "náhled";
		print submit "action", "upravit" if $user->can("edit_activities");
		print submit "action", "kopírovat" if $user->can("edit_activities");
		print submit "action", "smazat" if $user->can("edit_activities");
		print submit "action", "registrace" if $user->can("view_registrations");
		print submit "action", "členové" if $user->can("view_payments");
		print submit "action", "tisk" if $user->can("prrrint");
		print " anebo " if $user->can("edit_activities");
	}

	print submit("action", "přidat"), " novou aktivitu?" if $user->can("edit_activities");

	footer;
}

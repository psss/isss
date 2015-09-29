#!/usr/bin/perl

use strict qw(subs vars);
use lib '../lib';

use Aid;
use User;


while (quest) {
	header "Uživatelé systému", { javascript => "yes" };

		form "index.pl", "navig";

			# if something was found
			if (browse User { checkboxform => "uzivatele.pl"} ) {
				# make buttons
				for (qw(náhled upravit smazat)) {
					print submit "action", $_;
				}
				print " vybrané uživatele anebo ", submit(qw(action přidat)), " nového?";
			}
		formm

	footer;
}

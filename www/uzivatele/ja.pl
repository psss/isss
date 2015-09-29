#!/usr/bin/perl

use lib '../lib';
use strict;

use Aid;
use User;

while (quest) {
	header "Uživatelské nastavení";

		form "ja.pl";

			$user->update if $qp::action;
			$user->edit;
			print submit "action", "uložit";

		formm;

	footer;
}

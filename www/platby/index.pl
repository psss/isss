#!/usr/bin/perl

use lib '../lib';

use Aid;
use Payment;

while (quest) {
	header "Přehled plateb";

	if ($qp::action eq 'zruš') {
		cancel Payment ids "p";
	}

	form "index.pl";
	browse Payment;

	print submit("action", "zruš"), " vybrané platby" if $user->can("cancel_payments");

	footer;
}

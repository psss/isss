#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Card;
use Ider;

while (quest) {
	header "Tisk kartiček", { javascript => "yes" };

	my @cids = ids "c";

	if ($qp::action eq "vytiskni všechny čekající s fotkami") {
		prrrint_pending Card;
	}
	elsif ($qp::action eq "tiskni provizorní") {
		prrrint Card [ @cids ], "provizorní" if @cids;
	}
	elsif ($qp::action eq "tiskni") {
		prrrint Card [ @cids ] if @cids;
	}
	elsif ($qp::action eq "tiskni zadky") {
		prrrint_back Card;
	}
	elsif ($qp::action eq "zruš") {
		cancel Card @cids;
	}

	form "karty.pl";

	if (browse Card) {
		print submit "action", "tiskni" if $user->can('prrrint_cards');
		print submit "action", "tiskni provizorní" if $user->can('prrrint_tmp_cards');
		print submit "action", "tiskni zadky" if $user->can('prrrint');
		print submit "action", "zruš" if $user->can('cancel_cards');
		print " označené kartičky" if $user->can('prrrint_tmp_cards');
		print " anebo ". submit "action", "vytiskni všechny čekající s fotkami"
			if $user->can('prrrint_cards');
	}

	footer;
}

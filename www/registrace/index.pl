#!/usr/bin/perl

use lib '../lib';

use Aid;
use Conf;
use Register;

while (quest) {
	# if something was found
	if (browse Register { header => "Přehled registrací", navigform => "./", checkboxform => $Conf::UrlPersons }) {
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
	};

	footer;
}

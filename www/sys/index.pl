#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Conf;
use Setup;
use Activity;
use Register;
use Inquisitor;

while (quest) {
	header "Systémová správa";

		error("do systémových nastavení bohužel nemáš přístup"), next unless $user->can('do_system_stuff');

		my $setup = take Setup;

		form "index.pl";

			# make setup formular
			$setup->edit;

			# update free activities if asked
			if ($qp::free) {
				if (list Activity) {
					message "seznam byl úspěšně vytvořen";
				}
				else {
					message "seznam se nepodařilo zapsat";
				}
			}

			# sweep old registrations if asked
			if ($qp::sweep) {
				my $swept = sweep Register;
				message "$swept ". infl($swept,
					"registrace byla smazána", "registrace byly smazány", "registrací bylo smazáno");
			}

			# other actions formular
			print tab(
				row(td(
					div("Akce", 'class="heading"')
				)). row(td(tab(
					row(td(label(checkbox("free"). ' vygeneruj volné aktivity'))).
					row(td(label(checkbox("sweep"). ' zruš staré nepotvrzené registrace')))
				)))
			, 'class="card"');

			# submit
			print br, submit "action", "staniž se";

		formm;

	footer;
}

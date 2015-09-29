#!/usr/bin/perl

use lib '../lib';
use strict;

use Aid;
use Person;

QUEST: while (quest) {
	my %do;				# what are we to do
	my @pids = ids "p";		# with what shall we do it
	my $action = $qp::action || $qp::defaultaction || 'náhled';
	my $reserve;


	SWITCH: {
		if ($action =~ /upravit|edit/ && $user->can("edit_persons")) {
			header infl scalar @pids,  "Upravit človíčka", "Upravit lidičky";
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /smazat|delete/ && $user->can("edit_persons")) {
			header infl scalar @pids,  "Smazání človíčka", "Smazání lidiček";
			$do{delete} = 1;
			last SWITCH;
		}
		if ($action =~ /vytvořit|create|přidat/ && $user->can("edit_persons")) {
			header "Nový človíček";
			# let's create it
			@pids = ((create Person)->id);

			# and rest is the same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /porodit/ && $user->can("edit_persons")) {
			header infl scalar @pids,  "Narozený človíček", "Narození človíčkové";
			# let's give them birth
			for my $pid (@pids) {
				$pid = (birth Person $pid)->id;
			}

			# and rest is the same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /registrace|registruj|rezervuj|register/ && $user->can("view_registrations")) {
			header infl(scalar @pids,  "Registrace človíčka", "Registrace lidiček"), { javascript => "yes" };
			$do{register} = 1;
			$reserve = $action =~ /rezervuj/;
			last SWITCH;
		}
		if ($action =~ /platby|payments/ && $user->can("view_payments")) {
			header infl scalar @pids,  "Platby človíčka", "Platby lidiček";
			$do{payments} = 1;
			last SWITCH;
		}
		if ($action =~ /karty|cards/ && $user->can("view_cards")) {
			header infl scalar @pids,  "Kartičky človíčka", "Kartičky lidiček";
			$do{cards} = 1;
			last SWITCH;
		}
		if ($action =~ /rozvrh|schedule/ && $user->can("view_schedule")) {
			header infl scalar @pids,  "Rozvrh človíčka", "Rozvrhy lidiček";
			$do{schedule} = 1;
			last SWITCH;
		}
		if ($action =~ /tisk|prrrint/ && $user->can("prrrint")) {
			header infl scalar @pids, "Tisk človíčka", "Tisk lidiček";
			$do{prrrint} = 1;
			last SWITCH;
		}
		if ($action =~ /zprávy|messages/ && $user->can("send_messages")) {
			header infl scalar @pids, "Poslat zprávu človíčkovi", "Zasílání zpráv lidičkám";
			$do{messages} = 1;
			last SWITCH;
		}
		#if ($action =~ /náhled|show/ && $user->can("view_persons")) {
		if ($user->can("view_persons")) {
			header infl scalar @pids,  "Náhled človíčka", "Náhledy lidiček";
			$do{show} = 1;
			last SWITCH;
		}

		header "Lidičky";
		error "tak to vypadá, že tady v lidičkách asi nemáš co dělat...";
		next QUEST;
	}


	# for registering (contain last user's details, and problems with unsufficient data)
	my ($age, $sex, $problems, @messagepars);

	# for avoiding message duplicates
	my @sent_emails = ();
	my @sent_sms = ();

	unless (@pids) {
		error "chtělo by to vybrat aspoň jednoho človíčka (použij zaškrtávátka)...";
	}
	else {
		form "lidi.pl";

		prrrint_start Person if $do{prrrint};
		@messagepars = messages_start Person if $do{messages};

		for my $pid (@pids) {
			my $person = take Person $pid;

			# unless we can find the person jump to the next one
			$pid = undef, next unless $person;

			SWITCH: {
				if ($do{show}) {
					$person->show;
					last SWITCH;
				}
				if ($do{edit}) {
					# (can change when editing duplicate)
					$pid = $person->edit;
					last SWITCH;
				}
				if ($do{delete}) {
					if ($person->delete) {
						$pid = undef;
					}
					else {
						$person->show;
					}
					last SWITCH;
				}
				if ($do{register}) {
					$problems += $person->register($reserve);
					$age = $person->age("yearsonly");
					$sex = $person->sex;
					last SWITCH;
				}
				if ($do{payments}) {
					$person->payments;
					last SWITCH;
				}
				if ($do{cards}) {
					$person->cards;
					last SWITCH;
				}
				if ($do{schedule}) {
					$person->schedule;
					last SWITCH;
				}
				if ($do{prrrint}) {
					$person->prrrint;
					last SWITCH;
				}
				if ($do{messages}) {
					$person->messages(\@sent_sms, \@sent_emails, @messagepars);
					last SWITCH;
				}
			}
		}

		prrrint_finish Person if $do{prrrint};
		messages_finish Person \@sent_sms, \@sent_emails, @messagepars if $do{messages};

	}

	# filter out deleted persons
	@pids = grep {defined $_} @pids;


	# what next?
	if (@pids) {
		# always hide pids and default action
		print hide "pids", join '.', @pids;
		print hide "defaultaction", (keys %do)[0];

		# first default save button
		print submit "default", "staniž se!", 'class="save"'
			if ($do{edit} && $user->can("edit_persons")) ||
				($do{register} && $user->can("edit_registrations")) ||
				($do{messages} && $user->can("send_messages"));

		# and the rest
		print submit "action", "náhled";
		print submit "action", "upravit" if $user->can("edit_persons");
		print submit "action", "smazat" if $user->can("edit_persons");
		print submit "action", "registrace" if $user->can("view_registrations");
		print submit "action", "platby" if $user->can("view_payments");
		print submit "action", "karty" if $user->can("view_cards");
		print submit "action", "rozvrh" if $user->can("view_schedule");
		print submit "action", "tisk" if $user->can("prrrint");
		print submit "action", "zprávy" if $user->can("send_messages");
		print " anebo ", submit("action", "přidat"), " či ", submit("action", "porodit"), " človíčka?"
			if $user->can("edit_persons");

		# if registering, add activity browser
		if ($do{register} && $user->can("edit_registrations") && !$problems) {
			#print div 'Zaregistrovat novou aktivitu', 'class="section"';
			browse Activity {
				prefix  => 'register',
				glimpse => '{[#][name][<nobr>placementshort</nobr>][price][free][age][lead][condition]}',
				headers => [ ("", qw(název detaily cena míst věk vede podmínka)) ],
				age     => $age,
				sex	=> $sex
			};
			print submit "action", "registruj";
			print submit "action", "rezervuj" if $user->can("make_reservations");
		}

		# in print section show union of all persons (for getting back to choice)
		if ($do{prrrint} && @pids > 1) {
			my @persons = uniq @pids;
			if (@pids > $Conf::MaxUrlIdsCount) {
				formm;

				print br.tab(row(td("výběr "). td(
					"<form action=\"$Conf::UrlPersonsIndex\" method=\"post\"><input type=\"hidden\" name=\"search\" value=\"".
					(join ', ', map { "id:$_" } @persons) ."\"/><input type=\"submit\" name=\"nic\" value=\"".
					"všech ". @persons ." človíčků\"/></form>"
				)));
			}
			else {
				print "<p>výběr <a href=\"$Conf::UrlPersonsIndex?search=".
					(join ', ', map { "id:$_" } @persons) .'">'.
					(@persons == 2 ? "obou" : "všech ". @persons)." človíčků</a></p>"
			}
		}
	}

	footer;
}

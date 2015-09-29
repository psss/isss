#!/usr/bin/perl

use lib '../lib';
use strict;

use Aid;
use Room;
use Person;

QUEST: while (quest) {
	my %do;				# what are we to do
	my @rids = ids "r";		# with what shall we do it
	my $action = $qp::action || $qp::defaultaction || 'náhled';

	SWITCH: {
		if ($action =~ /přidat|create/ && $user->can("edit_rooms")) {
			# let's create it
			@rids = ((create Room)->id);
			header infl scalar @rids, "Nová místnost", "Nové místnosti";
			# and rest is the same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /upravit|edit/ && $user->can("edit_rooms")) {
			header infl scalar @rids, "Upravit místnost", "Upravit místnosti";
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /smazat|delete/ && $user->can("edit_rooms")) {
			header infl scalar @rids, "Smazání místnosti", "Smazání místností";
			$do{delete} = 1;
			last SWITCH;
		}
		if ($action =~ /rozvrh|schedule/ && $user->can("view_schedule")) {
			header infl scalar @rids, "Rozvrh místnosti", "Rozvrhy místností";
			$do{schedule} = 1;
			last SWITCH;
		}
		if ($action =~ /tisk|prrrint/ && $user->can("prrrint")) {
			header infl scalar @rids, "Tisk rozvrhu místnosti", "Tisk rozvrhů místností";
			$do{prrrint} = 1;
			last SWITCH;
		}
		#if ($action =~ /náhled|show/) {
		if ($user->can("view_rooms")) {
			header infl scalar @rids, "Náhled místnosti", "Náhledy místností";
			$do{show} = 1;
			last SWITCH;
		}

		header "Místnosti";
		error "tak to vypadá, že tady asi nemáš co dělat...";
		next QUEST;
	}


	unless (@rids) {
		error "chtělo by to vybrat aspoň jednu místnost..." unless @rids;
	}
	else {
		form "mistnosti.pl";

		if ($do{prrrint}) {
			prrrint_start Room;
		}

		for my $rid (@rids) {
			my $room = take Room $rid;

			SWITCH: {
				if ($do{edit}) {
					$room->edit;
					last SWITCH;
				}
				if ($do{delete}) {
					if ($room->delete) {
						$rid = undef;
					}
					last SWITCH;
				}
				if ($do{schedule}) {
					$room->schedule;
					last SWITCH;
				}
				if ($do{prrrint}) {
					$room->prrrint;
					last SWITCH;
				}
				if ($do{show}) {
					$room->show;
					last SWITCH;
				}
			}
		}

		if ($do{prrrint}) {
			prrrint_finish Room;
		}

		# filter out deleted rooms
		@rids = grep {defined $_} @rids;
	}


	# what next?
	if (@rids) {
		print hide "rids", join '.', @rids;
		print hide "defaultaction", (keys %do)[0];

		# first default save button
		print submit "default", "staniž se!", 'class="save"'
			if $do{edit} && $user->can("edit_rooms")
			|| $do{prrrint} && $user->can("prrrint");

		# and the rest
		print submit "action", "náhled" if $user->can("view_rooms");
		print submit "action", "upravit" if $user->can("edit_rooms");
		print submit "action", "rozvrh" if $user->can("view_schedule");
		print submit "action", "tisk" if $user->can("prrrint");
		print submit "action", "smazat" if $user->can("edit_rooms");
		print " anebo ", submit("action", "přidat"), " novou místnost?"
			if $user->can("edit_rooms");
	}

	footer;
}

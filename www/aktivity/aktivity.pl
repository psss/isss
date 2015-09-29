#!/usr/bin/perl

use lib '../lib';
use strict;

use Aid;
use Activity;

QUEST: while (quest) {
	my %do;				# what are we to do
	my @aids = ids "a";		# with what shall we do it (activities id list)
	my $action = $qp::action || $qp::defaultaction || 'náhled';
	my (@members, @leaders);	# used for unioning members & leaders of more activities

	SWITCH: {
		if ($action =~ /přidat|create/ && $user->can("edit_activities")) {
			# let's create it
			@aids = ((create Activity)->id);
			header infl scalar @aids, "Nová aktivita", "Nové aktivity";
			# and rest is the same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /upravit|edit/ && $user->can("edit_activities")) {
			header infl scalar @aids, "Upravit aktivitu", "Upravit aktivity";
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /registrace|register/ && $user->can("view_registrations")) {
			header infl scalar @aids, "Registrace aktivity", "Registrace aktivit";
			$do{registrations} = 1;
			last SWITCH;
		}
		if ($action =~ /členové|members/ && $user->can("view_person_details")) {
			header infl scalar @aids, "Členové aktivity", "Členové aktivit";
			$do{members} = 1;
			last SWITCH;
		}
		if ($action =~ /tisk|prrrint/ && $user->can("prrrint")) {
			header infl scalar @aids, "Tisk aktivity", "Tisk aktivit";
			$do{prrrint} = 1;
			last SWITCH;
		}
		if ($action =~ /smazat|delete/ && $user->can("edit_activities")) {
			header infl scalar @aids, "Smazání aktivity", "Smazání aktivit";
			$do{delete} = 1;
			last SWITCH;
		}
		if ($action =~ /kopírovat|copy/ && $user->can("edit_activities")) {
			header infl scalar @aids, "Zkopírovaná aktivita", "Zkopírované aktivity";
			for my $aid (@aids) {
				$aid = (take Activity $aid)->copy->id;
			}
			# rest same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		#if ($action =~ /náhled|show/)
		if ($user->can("view_activities")) {
			header infl scalar @aids, "Náhled aktivity", "Náhledy aktivit";
			$do{preview} = 1;
			last SWITCH;
		}

		header "Aktivity";
		error "tak to vypadá, že tady v aktivitách asi nemáš co dělat...";
		next QUEST;
	}


	unless (@aids) {
		error "chtělo by to vybrat aspoň jednu aktivitu (použij zaškrtávátka)...";
	}
	else {
		form "aktivity.pl";

		# start print form if printing
		if ($do{prrrint}) {
			prrrint_start Activity;
		}

		for my $aid (@aids) {
			my $activity = take Activity $aid;

			# unless we can find the activity jump to the next one
			$aid = undef, next unless $activity;

			SWITCH: {
				if ($do{edit}) {
					$activity->edit;
					last SWITCH;
				}
				if ($do{delete}) {
					if ($activity->delete) {
						$aid = undef;
					}
					last SWITCH;
				}
				if ($do{registrations}) {
					$activity->registrations;
					last SWITCH;
				}
				if ($do{members}) {
					$activity->members;
					last SWITCH;
				}
				if ($do{prrrint}) {
					$activity->prrrint(\@members, \@leaders);
					last SWITCH;
				}
				if ($do{preview}) {
					$activity->show;
					last SWITCH;
				}
			}
		}

		# finish print form if printing
		if ($do{prrrint}) {
			prrrint_finish Activity;
		}

		# filter out deleted activities
		@aids = grep {defined $_} @aids;
	}

	# what next?
	if (@aids) {
		# always hide aids
		print hide "aids", join '.', @aids;
		print hide "defaultaction", (keys %do)[0];

		# default save button
		print submit "default", "staniž se!", 'class="save"'
			if $do{edit} && $user->can("edit_activities")
			|| $do{prrrint} && $user->can("prrrint");

		# and the rest
		print submit "action", "náhled";
		print submit "action", "upravit" if $user->can("edit_activities");
		print submit "action", "kopírovat" if $user->can("edit_activities");
		print submit "action", "smazat" if $user->can("edit_activities");
		print submit "action", "registrace" if $user->can("view_registrations");
		print submit "action", "členové" if $user->can("view_person_details");
		print submit "action", "tisk" if $user->can("prrrint");
		print " anebo ", submit("action", "přidat"), " novou aktivitu?"
			if $user->can("edit_activities");

		formm;

		# if there are some members or leaders show union of all
		if (@members + @leaders > 1) {
			# get rid of duplicates and count
			@members = uniq @members;
			@leaders = uniq @leaders;
			my @together = uniq @members, @leaders;
			my ($buttons, $prefix, $infix, $postfix);

			# should the url be too large, use buttons & post instead of a link
			if ($buttons = @members > $Conf::MaxUrlIdsCount
					|| @leaders > $Conf::MaxUrlIdsCount
					|| @together > $Conf::MaxUrlIdsCount) {
				$prefix = "<form action=\"$Conf::UrlPersonsIndex\" method=\"post\"><input type=\"hidden\" name=\"search\" value=\"";
				$infix = "\"/><input type=\"submit\" name=\"nic\" value=\"";
				$postfix = "\"/></form>";
			} else { # otherwise use simple link
				$prefix = "<a href=\"$Conf::UrlPersonsIndex?search=";
				$infix = '">';
				$postfix = "</a>";
			}

			my $members = @members > 1 &&
				$prefix . (join ', ', map { "id:$_" } @members) . $infix .
				(@members == 2 ? "obou" : "všech ". @members) . " členů". $postfix;
			my $leaders = @leaders > 1 &&
				$prefix . (join ', ', map { "id:$_" } @leaders) . $infix .
				(@leaders == 2 ? "obou" : "všech ". @leaders) . " vedoucích" . $postfix;
			my $together = @together > 1 &&
				$prefix . (join ', ', map { "id:$_" } @together) . $infix .
				(@together == 2 ? "obou" : "všech ". @together) . " společně" . $postfix;

			if ($buttons) {
				print br.tab(row(td("výběr "). join '', map {td($_)} grep {$_} $members, $leaders, $together));
			}
			elsif ($members || $leaders || $together) {
				print "<p>výběr ", (join ', ', grep {$_} $members, $leaders, $together), "</p>";
			}

			# clean out
			@members = @leaders = ();
		}

	}

	footer;
}

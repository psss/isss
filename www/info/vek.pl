#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Season;
use Activity;

while (quest) {
	header "Věkové rozložení pro období ". (take Season $user->season)->name, { javascript => "yes" };

		form "vek.pl";

			my $activities;
			my $pub;
			my @aids =  ids "a";

			if ($qp::action =~ /statistika/) {
				if (@aids && $qp::action =~ /vybrané/) {
					$activities = "and (". (join ' or ', map { " a.id = $_ " } @aids) .")";
					print "Statistika pro: ", join ', ', map { (take Activity $_)->name } @aids;
					$pub = '';
				}
				else {
					print "Statistika pro všechny aktivity";
					$pub = 'and a.pub';
				}

				$db->exe("
						select age, count(distinct p.id)
						from persons_age p
						join registrations r
							on r.person = p.id
						join activities a
							on r.activity = a.id
						where a.season = ". $user->season ."
						      $pub
						      $activities
						group by age
						order by age;
					");

				my $rows;

				while (my ($age, $persons) = $db->row) {
					$rows .= row(
						td("<a href=\"$Conf::UrlPersonsIndex?youngest=$age&oldest=$age\">$age</a>").
						td($persons).
						td("<div class=\"bar\" style=\"width: ".($persons*3)."px\">&nbsp;</div>")
					);
				}

				# věkový průměr
				$db->exe("
						select avg(age)
						from persons_age p
						join registrations r
							on r.person = p.id
						join activities a
							on r.activity = a.id
						where a.season = ". $user->season ."
							$pub
							$activities
					");
				my $avgage = $db->val;


				print tab(row(td(
					tab(
						row(tt("věk").tt("lidí").td("průměr: ". sprintf "%.2f", $avgage)).
						$rows
					)
				)), 'class="card"');
			}

			browse Activity {
				glimpse => "{[#][name][placementshort][category][age][lead]}",
				headers => ["", qw(jméno rozvrh kategorie věk vede)] };

			print submit "action", "statistika pro vybrané";
			print submit "action", "statistika pro úplně všechny aktivity";

		formm;
	footer;
}

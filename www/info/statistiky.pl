#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Season;

while (quest) {
	header "Statistiky pro období ". (take Season $user->season)->name;

	form "statistiky.pl";

		my ($name, $activities, $distinct_activities, $persons, $distinct_persons,
			$youngers, $distinct_youngers,
			$persons06, $distinct_persons06,
			$persons18, $distinct_persons18,
			$persons99, $distinct_persons99,
			$girls, $distinct_girls);

		my $season = $user->season eq "season" ? "" : "and a.season = ". $user->season ."";

		print tab(undef, 'class="card"'), row, td;

			# celkem

			$db->exe("select
						count(distinct a.id), -- počet aktivit
						count(distinct a.name), -- počet různých aktivit
						count(r.person), -- počet členů
						count(distinct r.person), -- neopakující se počet členů

						-- mladší 06 let
						sum(case when p.age < 06 then 1 else 0 end),
						count(distinct(case when p.age < 06 then p.id else null end)), -- bez opakování

						-- 06-18 let
						sum(case when p.age >= 06 and p.age <= 18 then 1 else 0 end),
						count(distinct(case when p.age >= 06 and p.age <= 18 then p.id else null end)), -- bez opakování

						-- nad 18 let
						sum(case when p.age > 18 then 1 else 0 end),
						count(distinct(case when p.age > 18 then p.id else null end)), -- mladší 18 bez opakování

						-- holky
						sum(case when p.sex = 'f' then 1 else 0 end),
						count(distinct(case when p.sex = 'f' then p.id else null end)) -- holky bez opakování

					from activities a
					left outer join registrations_really_active r
						on r.activity = a.id
					left outer join persons_age p
						on r.person = p.id
					where a.pub
						$season
				");

			($activities, $distinct_activities, $persons, $distinct_persons,
					$persons06, $distinct_persons06,
					$persons18, $distinct_persons18,
					$persons99, $distinct_persons99,
					$girls, $distinct_girls) = $db->row;

			print div("Celkem", 'class="heading"').
				tab(
					row(td.tt("aktivit").tt("členů").tt("dívek").tt("pod 6").tt("6-18").tt("nad 18 let")).
					row(
						td("dohromady").
						td("$activities <span class=\"distinct\" title=\"počet vzájemně různých aktivit (podle názvů)\"\">($distinct_activities)</span>").
						td("$persons <span class=\"distinct\" title=\"počet skutečných lidí (bez opakování)\">($distinct_persons)</span>").
						td("$girls <span class=\"distinct\">($distinct_girls)</span>").
						td("$persons06 <span class=\"distinct\">($distinct_persons06)</span>").
						td("$persons18 <span class=\"distinct\">($distinct_persons18)</span>").
						td("$persons99 <span class=\"distinct\">($distinct_persons99)</span>")
					)
				);


			print "<p>Čísla v závorkách udávají počty bez opakování.</p>";

		print tdd, roww, row, td;

			# typy

			print div "Typy", 'class="heading"';
			$db->exe("
					select t.name,
						count(distinct a.id), -- počet aktivit
						count(distinct a.name), -- počet různých aktivit
						count(r.person), -- počet členů
						count(distinct r.person), -- neopakující se počet členů

						-- mladší 06 let
						sum(case when p.age < 06 then 1 else 0 end),
						count(distinct(case when p.age < 06 then p.id else null end)), -- bez opakování

						-- 06-18 let
						sum(case when p.age >= 06 and p.age <= 18 then 1 else 0 end),
						count(distinct(case when p.age >= 06 and p.age <= 18 then p.id else null end)), -- bez opakování

						-- nad 18 let
						sum(case when p.age > 18 then 1 else 0 end),
						count(distinct(case when p.age > 18 then p.id else null end)), -- mladší 18 bez opakování

						-- holky
						sum(case when p.sex = 'f' then 1 else 0 end),
						count(distinct(case when p.sex = 'f' then p.id else null end)) -- holky bez opakování

					from types t
					left outer join activities a
						on a.type = t.id
					left outer join registrations_really_active r
						on r.activity = a.id
					left outer join persons_age p
						on r.person = p.id
					where a.pub
						$season
					group by t.id, t.name
				");

			print tab;
				print row(tt.tt("aktivit").tt("členů").tt("dívek").tt("pod 6").tt("6-18").tt("nad 18 let"));
				while (($name, $activities, $distinct_activities, $persons, $distinct_persons,
						$persons06, $distinct_persons06,
						$persons18, $distinct_persons18,
						$persons99, $distinct_persons99,
						$girls, $distinct_girls) = $db->row) {
					print row(td($name).
						td("$activities <span class=\"distinct\">($distinct_activities)</span>").
						td("$persons <span class=\"distinct\">($distinct_persons)</span>").
						td("$girls <span class=\"distinct\">($distinct_girls)</span>").
						td("$persons06 <span class=\"distinct\">($distinct_persons06)</span>").
						td("$persons18 <span class=\"distinct\">($distinct_persons18)</span>").
						td("$persons99 <span class=\"distinct\">($distinct_persons99)</span>")
					);
				}
			print tabb;


		print tdd, roww, row, td;

			# kategorie

			print div "Kategorie", 'class="heading"';
			$db->exe("
					select c.name,
						count(distinct a.id), count(distinct a.name), count(r.person), count(distinct r.person)
					from categories c
					left outer join activities a
						on a.category = c.id
					left outer join registrations_really_active r
						on r.activity = a.id
					where a.pub
						$season
					group by c.id, c.name
				");

			print tab;
				print row(tt().tt("aktivit").tt("členů"));
				while (($name, $activities, $distinct_activities, $persons, $distinct_persons) = $db->row) {
					print row(td($name).
						td("$activities <span class=\"distinct\">($distinct_activities)</span>").
						td("$persons <span class=\"distinct\">($distinct_persons)</span>")
					);
				}
			print tabb;
			#print "<p>Ostatní statistiky zahrnují i aktivity bez členů. Jsou tu např. započteny i ty, které se neregistrují.</p>";

		print tdd, roww, row, td;

			# obory

			print div "Obory", 'class="heading"';
			$db->exe("
					select f.id || ' - ' || f.name,
						count(distinct a.id), count(distinct a.name), count(r.person), count(distinct r.person)
					from fields f
					left outer join activities a
						on a.field = f.id
					left outer join registrations_really_active r
						on r.activity = a.id
					where a.pub
						$season
					group by f.id, f.name
				");

			print tab;
				print row(tt().tt("aktivit").tt("členů"));
				while (($name, $activities, $distinct_activities, $persons, $distinct_persons) = $db->row) {
					print row(td($name).
						td("$activities <span class=\"distinct\">($distinct_activities)</span>").
						td("$persons <span class=\"distinct\">($distinct_persons)</span>")
					);
				}
			print tabb;

		print tdd, roww, tabb;

		print submit "action", "obnovit";

	formm;
	footer;
}

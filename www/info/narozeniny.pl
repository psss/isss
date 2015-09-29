#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Person;
use Inquisitor;

my $outlooker = new Inquisitor ('0', 'dnes', 1, 'dnes a zítra', '2', '3 dny', '7', 'týden', 28, 'měsíc');

while (quest) {
	header "Narozeniny";

		my $days = defined (ck $qp::days) ? ck $qp::days : 2;
		my @pids;

		form "narozeniny.pl";
			print "zobrazit ". $outlooker->select('days', $days, undef, 'onchange="submit();"');
		formm;

		# main searching
		for my $outlook (0 .. $days) {
			# find the date
			$db->exe("select
					extract (day from date '". $now->db_date ."' + interval '$outlook days'),
					extract (month from date '". $now->db_date ."' + interval '$outlook days'),
					extract (year from date '". $now->db_date ."' + interval '$outlook days')
				");
			my ($day, $month, $year) = $db->vals;

			# find people
			$db->exe("select id, $year - extract (years from birthdate), name, surname from persons where
					extract (day from birthdate) = $day
					and
					extract (month from birthdate) = $month
					order by surname, name
				");

			# start outlook table
			print div(
					($outlook < 3
						  ? (qw(dnes zítra pozítří))[$outlook]
						  : "za $outlook " .  infl($outlook, qw(den dny dnů))
					), 'class="section"'
				),
				(tab undef, 'class="scraps"'),
				row(th("foto").th("detaily").th("aktivity").th("vede"));

			# show people
			while (my ($id, $age) = $db->row) {
				push @pids, $id;

				print ((take Person $id)->glimpse(
					'{[miniphoto]
					 [<div class="section">name</div>
					 birthdate<br/>
					 '."$age ". infl($age, qw(rok roky roků)) .']
					 [activities][leads]}'));
			}

			# finish outlook table
			print tabb;

		}

		# link to all showed people
		print tabb, "<a href=\"$Conf::Url/lidi/lidi.pl?pids=".
			(join '.', @pids) ."\">náhledy</a> uvedených osob";

	footer;
}

#!/usr/bin/perl

use strict;
use lib 'lib';
use Aid;
use Person;
use Activity;

my $i;

while (quest) {

	header "Vítej v isssu!";

		print tab(
			row(
				td( # free activities
					div("volné aktivity", 'class="heading"').
					'<a href="aktivity/?type=1">jednorázové</a>'.br.
					'<a href="aktivity/?type=2">pravidelné</a>'.br.
					'<a href="aktivity/?type=3">ostatní</a>'.br
				). td( # short stats
					div("celkem", 'class="heading"').
					tab(
						row td stats Person  .
						row td stats Activity  .
						row td stats Lead
					)
				)
			). row(
				td( # links
						div("odkazy", 'class="heading"').
						'<a href="/aktivity/volne.html" target="_top">volné aktivity na webu</a>'.br.
						'<a href="http://brno.sdb.cz/" target="_top">brno.sdb.cz</a>'.br.
						'<a href="/email/" target="_top">email</a>'
				). td( # detailed statistics
					$user->can("view_stats") &&
						div("informace", 'class="heading"').
						'<a href="info/narozeniny.pl">narozeniny</a>'.br.
						'<a href="info/vek.pl?action=statistika&open=0&free=0">věkové rozložení</a>'.br.
						'<a href="info/statistiky.pl">typy, kategorie, obory</a>'
				)

			)
		, 'class="card"');

		print tab(row(td(div("novinky", 'class="heading"').
			"
			<ul>
				<li class=\"novinka\">2007-06-01: třídění nevyrovnaných registrací podle dluhu</li>

				<li>2007-03-13: vyhledání zájemců o zasílání informačních mejlů</li>

				<li>2007-03-12: vylepšené zasílání zpráv (podle věku, kontrola duplikátů, generování seznamů)</li>

				<li>2007-03-12: možnost vyhledání pouze aktivních členů</li>

				<li>2007-03-12: opraveny statistiky (nesprávné počítání prázdných aktivit)</li>

				<li>2006-10-27: upraveny statistiky členů dle věku na tři kategorie (do 15, 15-18 a nad 18 let)</li>

				<li>2006-10-19: na stránce tisku človíčků přidána možnost zobrazení informací o rodičích</li>

				<li>2006-04-13: přehledné grafické zobrazení obsazenosti aktivit</li>

				<li>2006-04-13: opraveny a vylepšeny statistky aktivit a jejich členů</li>

				<li>2006-04-13: dočasnou kartičku už nejde bez zaplacení/potvrzení registrace vytisknout</li>

				<li>2006-04-13: opraveny počty členů u hafo-aktivit</li>

				<li>2006-04-13: členský příspěvek na příjmových dokladech volné oratoře a klubu maminek</li>

				<li>2006-04-07: aktivity teď mohou mít svého koordinátora (užitečné hlavně pro tábory)</li>

			</ul>
			"
		)), 'class="card"');

	footer;
}

#				<li>2005-10-14: vylepšený výběr všech zaškrtávátek</li>
#
#				<li>2005-10-14: změna období a tiskárny už nemaže hledací chlívky</li>
#
#				<li>2005-10-07: barevné odlišení aktivit v rozvrzích</li>
#
#				<li>2005-10-07: výběr členů a vedoucích společně na stránce tisku</li>
#
#				<li>2005-10-07: rozdělení interních a veřejných aktivit v náhledu</li>
#
#				<li>2005-10-07: přidržením myšítka nad rozvrhem se dozvíš vedoucí a detail rozvrhu</li>
#
#				<li>2005-09-30: poslední písmeno jména človíčka = upravit, poslední z příjmení = rozvrh</li>
#
#				<li>2005-09-20: nová zkratka alt-i alias jdi na úvodní stránku</li>
#
#				<li>2005-06-10: upřesnění statistik na hlavní stránce</li>
#
#				<li>2005-06-10: vyhledávání prázdných a nenaplněných aktivit</li>
#
#				<li>2005-06-10: částečné zálohy (možnost individuální změny)</li>
#
#				<li class=\"novinka\">2005-03-11: výběr všech členů a vedoucích na stránce tisku</li>
#
#				<li>2005-03-10: nevratné zálohy u aktivit</li>
#
#				<li>2005-02-04: oprava tisku kartiček, rušení plateb</li>
#
#				<li>2005-01-11: mobily a emaily na rodiče jsou pro přehlednost označeny malým erkem</li>
#
#				<li>2004-11-26: informace o tom kdo a kdy zrušil registraci (myška nad \"zrušeno k\")</li>
#
#				<li>2004-11-26: odesílání mejlů z vlastní adresy</li>
#
#				<li>2004-10-22: rychlý skok do zápisu = klik na příjmení</li>
#
#				<li>2004-10-22: vyhledávání maminek, tatínků a ratolestí</li>
#
#				<li>2004-10-21: isss už umí i porodit nového človíčka (zkopírovat data od rodiče)</li>
#
#				<li>2004-09-16: detaily rozvrhu u registrací</li>
#
#				<li>2004-09-15: lepší stránkování kartiček</li>
#
#				<li>2004-09-09: rezervace kroužků</li>
#
#				<li>2004-07-30: možnost procházet všechna období</li>
#
#				<li>2004-07-27: nový údaj: poznámka u aktivit</li>
#
#				<li>2004-06-11: zlepšený výběr lidí a hledání v přehledu registrací</li>
#
#				<li>2004-05-21: částečné registrace (např. maminka jenom do vánoc) zobrazují
#				členy jako aktivní až do osudného data</li>
#
#				<li>2004-05-17: výběr lidí v přehledu registrací</li>
#
#				<li>2004-05-14: háčky a čárky v předmětech emailů</li>
#
#				<li>2004-02-27: možnost tisknout jednoduše provizorní kartičky (človíček->karty)</li>
#
#				<li>2004-02-27: opravena chyba v narozeninách</li>
#
#				<li>2004-02-27: doladěno hlídání konfliktů</li>
#
#				<li>2004-01-11: zasílání zpráv (emaily a smsky) -- tlačítko zprávy</li>
#
#				<li>2004-01-11: přesnější hledání adres v mapě</li>
#
#				<li>2003-11-18: v seznamu registrací lze snadno vyhledávat
#					nepotvrzené a nevyrovnané registrace</li>
#
#				<li>2003-10-31: informátoři mají k dispozici seznam členů i s kontakty</li>
#
#				<li>2003-10-31: POZÓÓÓR: maminky i tatínky prosím zadávejme jménem i příjmením,
#					aby se nám lépe vyhledávali</li>
#
#				<li>2003-10-31: podrobnosti o členech v tisku aktivit</li>
#
#				<li>2003-10-31: v náhledu aktivit a človíčků nový odkaz <b>výběr</b> (ze všech
#					členů/aktivit si lze vybírat)</li>
#
#				<li>2003-10-24: vyhledávání maminek a tatínků (v náhledu človíčka)</li>
#
#				<li>2003-10-24: nedovolí přidat stejného človíčka dvakrát (po zadání
#				rodného čísla/narození vždy uložit -- stačí Entrem)</li>
#

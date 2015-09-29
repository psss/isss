package Activity;

  #######################################################
 ####  Activity -- handling activities  ################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new activity
#  > copy		create new activity as a copy of existing one
#  > take		constructor (takes aid)
#
#  > browse		browsing the activities
#  > stats		print short activity statistics
#
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > name
#  > type
#  > category
#  > field
#  > description
#  > min
#  > max
#  > free		free places
#  > count		number of members
#  > youngest		minimal age
#  > oldest		maximal age
#  > sex
#  > condition
#  > note
#  > start		start date
#  > finish		finish date
#  > price
#  > deposit
#  > fixed		fixed price
#  > pub		public
#  > open
#  > card
#  > season
#
#  > created
#  > updated
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#  > name		get the name
#  > start		get activity start date
#  > finish		get activity finish date
#  > free		count free places
#
#  > glimpse		one <tr> info 'bout the activity
#
#  > edit		make formular for editing
#  > show		show activity info
#  > register		show registrations
#
#  > save		save data into database
#  > delete		delete the activity

use locale;
use strict qw(subs vars);

use Aid;
use Ider;
use Lead;
use Time;
use Place;
use Setup;
use Season;
use Printer;
use Cleaver;
use Register;
use Inquisitor;

my $categorier = category Inquisitor;
my $fielder = field Inquisitor;
my $sexer  = sex2 Inquisitor;
my $typer  = type Inquisitor;
my $fixer  = fixed Inquisitor;
my $puber  = pub Inquisitor;
my $opener = opened Inquisitor;
my $carder = card Inquisitor;
my $dayer  = day Inquisitor;
my $activitier = activity Inquisitor;
my $personier = person Inquisitor;



my @attr = qw(id name type category field description min max youngest oldest sex
		condition note start finish price deposit fixed pub open card season created updated);


# create new activity (empty)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
	my ($pack, $noplace) = @_;
	my $id;

	# insert into db
	$dbi->beg;
		$dbi->exe("insert into activities (season, created, fixed, pub, open, card, deposit, category, field) values
				(". $user->season .", now(), 'f', 't', 'f', 't', 0, $Conf::DefaultCategory, $Conf::DefaultField)");
		$dbi->exe("select currval('activities_id_seq')");
		$id = $dbi->val;
	$dbi->end;

	# create an empty placement
	create Place $id unless $noplace;

	# and return complete activity
	take Activity $id;
}



# constructor for existing activities
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  aid
sub take {
	my ($pack, $aid) = @_;
	return undef unless $aid;

	my $this = {};

	# read data from db
	$dbi->exe("select ". (join ", ", @attr) ." from activities where id = '". uq($aid) ."'")
		or error("taková aktivita neexistuje (". $aid .")"), return undef;
	@$this{@attr} = $dbi->row;

	# convert times
	$this->{start} = db_date Time $this->{start};
	$this->{finish} = db_date Time $this->{finish};
	$this->{created} = db_stamp Time $this->{created};
	$this->{updated} = db_stamp Time $this->{updated};

	# set member counts
	$dbi->exe("select free, count from activities_free where id = $this->{id}");
	($this->{free}, $this->{count}) = $dbi->row;

	bless $this;
}



# copying existing activities
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub copy {
	my $this = shift;

	my $new = create Activity "noplace";

	# get leaders & placement
	my @coordinator = leaders Lead $this->{id}, $Conf::Ranks{coordinator};
	my @leaders = leaders Lead $this->{id}, $Conf::Ranks{leader};
	my @placements = activity Place $this->{id};

	# switch to the new id and correct some values...
	$this->{id} = $new->{id};
	$this->{created} = $new->{created};
	$this->{updated} = $new->{updated};
	$this->{season} = $new->{season};

	# well, we'll copy dates too
	#$this->{start} = db_time Time "nothing";
	#$this->{finish} = db_time Time "nothing";

	# save values into db as new id
	$this->save;

	# copy coordinator & leaders
	for my $lid (@coordinator) {
		create Lead $lid, $Conf::Ranks{coordinator}, $this->{id};
	}
	for my $lid (@leaders) {
		create Lead $lid, $Conf::Ranks{leader}, $this->{id};
	}

	# copy placement
	for my $pid (@placements) {
		(take Place $pid)->copy($this->{id});
	}

	$this;
}




# deleting an activity
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat aktivity"), return undef unless $user->can("edit_activities");

	# ok, deleted
	if ($dbi->exe("delete from activities where id = $this->{id}", "try")) {
		message("aktivita (". $this->name .") byla úspěšně smazána");
		return "ok";
	}
	# cannot be deleted anymore
	else {
		error ($this->name ." už nelze smazat");
		$this->show;
		return undef;
	}
}


# get activity id
# ~~~~~~~~~~~~~~~~
sub id {
	my $this = shift;

	$this->{id};
}


# get name of the activity
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub name {
	my $this = shift;

	$this->{name};
}


# get season of the activity
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub season {
	my $this = shift;

	$this->{season};
}


sub max {
	my $this = shift;

	$this->{max};
}

sub min {
	my $this = shift;

	$this->{min};
}

sub type {
	my $this = shift;

	$this->{type};
}

sub pub {
	my $this = shift;

	$this->{pub} eq 't';
}

sub open {
	my $this = shift;

	$this->{open} eq 't';
}


# true if the activity is card activity
# if called as class method returns number
# of card activities for specified person
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub card {
	my ($this, $person, $payedonly) = @_;

	if ($this eq 'Activity') {
		return undef unless defined $person;

		$dbi->exe("select count(*) from registrations_view
				where person = $person
				  and card
				  and season = ". $user->season.
				  ($payedonly && " and (payed > 0 or pay = payed)")
			);
		$dbi->val;
	}
	else {
		$this->{card} eq 't';
	}
}


# get when the activity starts
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub start {
	my $this = shift;
	#todo: filter overlaps?

	$this->{start}->user_date ? $this->{start} : (take Season $this->{season})->start;
}


# get when the activity finishes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub finish {
	my $this = shift;
	#todo: filter overlaps?

	$this->{finish}->user_date ? $this->{finish} : (take Season $this->{season})->finish;
}


# count free places / return free activities
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub free {
	my ($this, $type) = @_;

	if ($this eq 'Activity') {
		$dbi->exe("select id from activities_free
				where pub
				  and open
				  and type = $type
				  and season = ". $user->season ."
				  and (free > 0 or free is null)
				order by category, name");
		$dbi->vals;
	}
	else { # deprecated... use this->{free}
		$dbi->exe("select free from activities_free where id = $this->{id}");
		$dbi->val;
	}
}


# check if the person can be member of this activity
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub check {
	my ($this, $pid) = @_;

	my $err;
	my $person = take Person $pid;
	my $age = $person->age("yearsonly", $this->start);
	my $sex = $person->sex;

	$err .= err $this->start->user_date_long("year"). " má ". $person->firstname.
		" $age ". infl($age, "rok", "roky", "roků").
		" ($this->{name} je ale až od $this->{youngest} ". infl($this->{youngest}, "roku", "let"). ")", "věk"
		if defined $this->{youngest} && $age < $this->{youngest};

	$err .= err $this->start->user_date_long("year") . " má ". $person->firstname.
		" $age ". infl($age, "rok", "roky", "roků").
		" ($this->{name} je ale jen do $this->{oldest} ". infl($this->{oldest}, "roku", "let"). ")", "věk"
		if defined $this->{oldest} && $age > $this->{oldest};

	$err .= err "pohlaví neodpovídá: ". $person->firstname.
			" není ". (sex Inquisitor)->name($this->{sex}). "!", "pohlaví"
		if $this->{sex} and $this->{sex} ne $sex;

	$err;
}


# get (maybe) commented price (maybe for specified count of days)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub price {
	my ($this, $days, $alldays, $price, $pay) = @_;

	# if simply calling for standard activity price -- return it!
	return $this->{price} unless defined $pay;

	# paying just deposit
	if ($this->{deposit} > 0 && $pay <= $this->{deposit} && $pay > 0) {
		sprintf "<span title=\"nevratná záloha $pay,-\">$pay</span>";
	}
	# otherwise proportional price
	else {
		# return commented fixed price if it's fixed
		if ($this->{fixed} eq 't') {
			return "<span title=\"fixní částka Kč $pay,-\">$pay</span>"
		}

		my $percent = $days / $alldays * 100;
		my $exact = $price * $percent / 100;

		sprintf "<span title=\"$days/$alldays dnů tj. ".
			"%.1f%% z $price,- tedy %.0f,- zaokrouhleno $pay,-\">$pay</span>", $percent, $exact;
	}
}


# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit this activity
        error("nemáš právo upravovat aktivitu"), $this->show, return unless $user->can("edit_activities");
	my %err;

	if (defined ${"qp::a$this->{id}name"}) {
		# get new values
		for my $val (qw(name type category field condition note description
				min max youngest oldest sex start finish
				price deposit fixed pub open card leader coordinator)) {
			$this->{$val} = ${"qp::a$this->{id}$val"};
		}

		$this->{category} = undef unless ck $this->{category};
		$this->{field} = undef unless ck $this->{field};
		$this->{sex} = undef unless $this->{sex};

		# check dates -- if got some and they're bad -- then cry out!
		for my $date (qw(start finish)) {
			$this->{$date} = user_date Time $this->{$date};
			if (${"qp::a$this->{id}$date"} ne "" and not $this->{$date}->user_date) {
				$err{$date} = err "nesprávné datum"
			}
		}
		# set automatically finish date same as start when not set in one-time activity
		$this->{finish} = $this->{start} if !$this->{finish}->user_date
			&& $this->{start}->user_date && $this->{type} == $Conf::ActivityTypeOneTime;

		for my $number (qw(min max youngest oldest)) {
			$err{$number} = err "neplatné číslo"
				if !defined ($this->{$number} = ck $this->{$number}) && ${"qp::a$this->{id}$number"} ne "";
		}
		$this->{min} = $this->{max} if defined($this->{min}) && $this->{min} > $this->{max};

		$this->{price} = ck $this->{price};
		unless (defined $this->{price}) {
			$this->{price} = 0;
			$err{price} = err "neplatná cena -- dávám 0,-";
		}

		$this->{deposit} = ck $this->{deposit};
		unless (defined $this->{deposit}) {
			$this->{deposit} = 0;
			$err{deposit} = err "neplatná záloha -- dávám 0,-";
		}


		# maybe place the activity?
		if (${"qp::a$this->{id}place"}) {
			create Place $this->{id};
		}

		# maybe add some leaders
		create Lead $this->{coordinator}, $Conf::Ranks{coordinator}, $this->{id} if $this->{coordinator};
		create Lead $this->{leader}, $Conf::Ranks{leader}, $this->{id} if $this->{leader};

		$this->save;
		message "uloženo";
	};

	# look up the schedule
	# first save all values -- ineffective -- but removes dealyed errors (overlaps with old values)
	#!map {(take Place $_)->edit} activity Place $this->{id};
	# now do the same -- prepare the formular
	my $placement = join '', map {(take Place $_)->edit} activity Place $this->{id};

	# and prepare edit list of leaders
	my $coordinator = join ', ', grep { $_ } map {(take Lead $_, $this->{id})->edit} leaders Lead $this->{id}, $Conf::Ranks{coordinator};
	my $leaders     = join ', ', grep { $_ } map {(take Lead $_, $this->{id})->edit} leaders Lead $this->{id}, $Conf::Ranks{leader};

	# this is really not very nice, but animators can change and
	# when we use fcgi, they don't
	my $animatorer = animator Inquisitor;

	print tab(
	row(td(div($this->glimpse("name") || "Nová aktivita", 'class="heading"'), 'colspan="3"')
	). row(
		td(tab(
			row(
				th("<u>n</u>ázev:").
				td(input("a$this->{id}name", uqq($this->{name}), @Conf::InputName, 'accesskey="n"'))
			). row(
				th("typ:").
				td($typer->radio("a$this->{id}type", br, $this->{type}))
			). row(
				th("<u>k</u>ategorie:").
				td($categorier->select("a$this->{id}category", $this->{category}, undef, 'accesskey="k"'))
			). row(
				th("obor:").
				td($fielder->select("a$this->{id}field", $this->{field}))
			). row(
				th("<u>p</u>opis:").
				td(area("a$this->{id}description", uqq($this->{description}), 30, 5, 'accesskey="p"'))
			). row(
				th("podmínka:").
				td(input("a$this->{id}condition", uqq($this->{condition}), @Conf::InputCondition))
			). row(
				th("poznámka:").
				td(input("a$this->{id}note", uqq($this->{note}), @Conf::InputNote))
			)
		), 'rowspan="3"'). td(tab(
			row(
				td.tt("<u>v</u>ěk")
			). row(
				th("min:").
				td(input("a$this->{id}youngest", uqq(defined $this->{youngest} ?
					$this->{youngest} : ${"qp::a$this->{id}youngest"}), 3, 3,
						'accesskey="v"').$err{youngest})
			). row(
				th("max:").
				td(input("a$this->{id}oldest", uqq(defined $this->{oldest} ?
					$this->{oldest} : ${"qp::a$this->{id}oldest"}), 3, 3).$err{oldest})
		)). td(tab(
			row(
				td.tt("poč<u>e</u>t")
			). row(
				th("min:").
				td(input("a$this->{id}min", uqq(defined $this->{min} ?
					$this->{min} : ${"qp::a$this->{id}min"}), 3, 3,
						'accesskey="e"').$err{min})
			). row(
				th("max:").
				td(input("a$this->{id}max", uqq(defined $this->{max} ?
					$this->{max} : ${"qp::a$this->{id}max"}), 3, 3).$err{max})
			)
		)))
	). row(td(tab(
			row(
				th("pro koho:").
				td($sexer->radio("a$this->{id}sex", br, $this->{sex}))
			)
		), 'colspan="2"')
	). row(td(tab(
			row(
				td.tt("<u>d</u>atum")
			). row(
				th("zahájení:").
				td(input("a$this->{id}start",
					uqq($this->{start}->user_date || ${"qp::a$this->{id}start"}),
					$Conf::DateSize, $Conf::DateMax, 'accesskey="d"').$err{start},
					'title="pokud nezadáno, předpokládá se začátek období"')
			). row(
				th("ukončení:").
				td(input("a$this->{id}finish",
					uqq($this->{finish}->user_date || ${"qp::a$this->{id}finish"}),
					$Conf::DateSize, $Conf::DateMax).$err{finish},
					'title="pokud nezadáno, předpokládá se konec období"')
			)
		), 'colspan="2"')
	). row(
		td(tab(
			row(
				th("<u>c</u>ena:").
				td(input("a$this->{id}price", uqq(defined $this->{price} ?
					$this->{price} : ${"qp::a$this->{id}price"}),
						$Conf::PriceSize, $Conf::PriceMax, 'accesskey="c"')." Kč$err{price}")
			).
			row(
				th("<u>z</u>áloha:").
				td(input("a$this->{id}deposit", uqq(defined $this->{deposit} ?
					$this->{deposit} : ${"qp::a$this->{id}deposit"}),
						$Conf::PriceSize, $Conf::PriceMax, 'accesskey="c"')." Kč$err{deposit}")
			).
			row(
				th("typ ceny:").
				td($fixer->radio("a$this->{id}fixed", " ", $this->{fixed}))
			)
		)). td(tab(
			row(
				th("stav:").
				td($opener->radio("a$this->{id}open", " ", $this->{open}))
			). row(
				th("kartičky:").
				td($carder->radio("a$this->{id}card", " ", $this->{card}))
			). row(
				th("zveřejnění:").
				td($puber->radio("a$this->{id}pub", " ", $this->{pub}))
			)
		), 'colspan="2"')
	). row(td(tab(row(
			th("koordinátor:").
			td($coordinator.' <span title="změnit koordinátora"> '.  $animatorer->select("a$this->{id}coordinator", 0, " ").'</span>')
		). row(
			th("vedoucí:").
			td($leaders.' <span title="přidat vedoucího"> '.  $animatorer->select("a$this->{id}leader", 0, " ").'</span>')
		)), 'colspan="3"')
	). row(td(tab(
		$placement
			? row(th("rozvrh:").(td("den").td("od").td("do").
				td("místnost").td("upřesnění").td("smazat"))).
				$placement.
				row(td.td(label(checkbox("a$this->{id}place")." přidat nový řádek"), 'colspan="3"'))

			: row(th("rozvrh:").td(checkbox("a$this->{id}place")." přidat nový řádek"))

	), 'colspan="3"'))
	, 'class="card"');
}


# show activity info
# ~~~~~~~~~~~~~~~~~~~
sub show {
	my $this = shift;

	# make sure we can view activities
        error("nemáš právo koukat na aktivitu"), return unless $user->can("view_activities");

	# find members
	my @members = members Register $this->{id};
	my $members;

	if (@members && $user->can("view_members")) {
		if ($user->can("view_person_details")) {
			$members = tt("narození").tt("věk").tt("telefén").tt("mobil").tt("adresa").roww.
				join '', map {(take Person $_)->glimpse(
				"{[][name][birthdate][years][tel][onemobil][address]}")} @members;
		}
		else {
			$members = tt("telefén").tt("mobil").tt("email").roww.
				join '', map {(take Person $_)->glimpse(
				"{[][name][tel][onemobil][email]}")} @members;
		}
	}

	$members .= row(td().td("<b>
		<a href=\"$Conf::UrlPersons?pids=". (join '.', @members) ."\">náhled</a> /
		". ($user->can('prrrint') && "<a href=\"$Conf::UrlPersons?action=prrrint&pids=". (join '.', @members) ."\">tisk</a> /") ."
		". ($user->can('send_messages') && "<a href=\"$Conf::UrlPersons?action=messages&pids=". (join '.', @members) ."\">zprávy</a> /") ."
		<a href=\"$Conf::UrlPersonsIndex?search=". (join ', ', map { "id:$_" } @members) ."\">výběr</a></b> ".
		(@members == 2 ? "obou" : "všech ". @members) ." členů", 'colspan="7"'))
			if @members > 1;

	my $coordinator = $this->glimpse("coordinator", { break => ", " });
	my $leaders     = $this->glimpse("leader", { break => ", " });

	print tab(
	row(td(div($this->glimpse("name"), 'class="heading"'), 'colspan="3"')
	). row(
		td(tab(
			row(
				th("název:").
				td(uqq($this->{name}))
			). row(
				th("typ:").
				td($typer->name($this->{type}))
			). row(
				th("kategorie:").
				td($categorier->name($this->{category}))
			). row(
				th("obor:").
				td($fielder->name($this->{field}))
			). row(
				th("popis:").
				td(uqq($this->{description}))
			). row(
				th("podmínka:").
				td(uqq($this->{condition}))
			). row(
				th("poznámka:").
				td(uqq($this->{note}))
			)
		), 'rowspan="3"'). td(tab(
			row(
				td.tt("věk")
			). row(
				th("min:").
				td(uqq($this->{youngest}))
			). row(
				th("max:").
				td(uqq($this->{oldest}))
		)). td(tab(
			row(
				td.tt("počet")
			). row(
				th("min:").
				td(uqq($this->{min}))
			). row(
				th("max:").
				td(uqq($this->{max}))
			)
		)))
	). row(td(tab(
			row(
				th("pro koho:").
				td($sexer->name($this->{sex}))
			)
		), 'colspan="2"')
	). row(td(tab(
			row(
				td.tt("datum")
			). row(
				th("zahájení:").
				td($this->{start}->user_date)
			). row(
				th("ukončení:").
				td($this->{finish}->user_date)
			)
		), 'colspan="2"')
	). row(
		td(tab(
			row(
				th("cena:").
				td(defined $this->{price} ? "$this->{price} Kč" : "")
			).
			row(
				th("záloha:").
				td(defined $this->{deposit} ? "$this->{deposit} Kč" : "")
			).
			row(
				th("typ ceny:").
				td($fixer->name($this->{fixed}))
			)
		)). td(tab(
			row(
				th("stav:").
				td($opener->name($this->{open}))
			).
			row(
				th("kartičky:").
				td($carder->name($this->{card}))
			).
			row(
				th("zveřejnění:").
				td($puber->name($this->{pub}))
			)
		), 'colspan="2"')
	). row(td(tab(
			($coordinator && row(th("koordinátor:").td($coordinator))).
			row(th("vedoucí:").td($leaders))
		), 'colspan="3"')
	). row(td(tab(row(th("rozvrh:").td($this->glimpse("placement")))), 'colspan="3"')
	). ($user->can("view_members") && row(td(tab(row.td.tt("členové:").$members), 'colspan="3"')))
	, 'class="card"');
}


# show members` cards
# ~~~~~~~~~~~~~~~~~~~~
sub members {
	my $this = shift;

	my @members = members Register $this->{id};
	my $members = join '', map {(take Person $_)->glimpse('
			{
				[
					miniphoto
				][
					<div class="heading">name</div><br/>
					address<br/>
					birthdate<br/>
					yearsold
				][
					telefén: phones<br/>
					e-mail:   email<br/><br/>

					pojišťovna: ins<br/>
					zdraví:     health<br/>
					zájmy:      hobbies<br/>
					poznámka:   note
				][
					activities
				]
			}
			')} @members;

	print tab(
		row(td(div($this->glimpse("name"), 'class="heading"'))).
		row(td($members
			? tab(
				row(join '', map { tt($_) } qw(foto jméno detaily aktivity) ).
				$members
			, 'class="scraps"')
			: "žádní členové"
		))
	, 'class="card"');
}


# start print page
# ~~~~~~~~~~~~~~~~~
sub prrrint_start {
	my $pack = shift;

	my @fields = qp 'fields';
	my @memberfields = qp 'memberfields';

	@fields = qw(name lead) unless @fields;

	print
		tab(row(
			td(tab(
				row(
					td($activitier->multi('fields', undef, @fields), 'rowspan="3"').
					tt("aktivity / členové").
					td($personier->multi('memberfields', undef, @memberfields), 'rowspan="3"')
				). row(
					td(label(checkbox("nohrefs", undef, $qp::nohrefs). " bez odkazů"))
				). row(
					td(submit("", "zobraz"))
				)
			)). td(tab(
				row(tt("tisknout třídnice", 'colspan="2"')).
				row(
					td(
						label(checkbox("prrrintcover"). " tiskni obálku "). br.
						label(checkbox("prrrintfirstindi"). " obálku individuální "). br.
						label(checkbox("prrrintfirst"). " úvodní stránku ")
					). td(
						label(checkbox("prrrintwork"). " výkaz práce "). br.
						label(checkbox("prrrintworkwithsafety"). " výkaz s poučením "). br.
						label(checkbox("prrrintlist"). " docházku ")
					)
				)
			))

		), 'class="navig"'),

		tab(undef, 'class="scraps"');

	# print header row for all activities if we do not show members
	print row(join '', map { th($activitier->name($_)) } @fields) unless @memberfields;

}


# finish print page
# ~~~~~~~~~~~~~~~~~~
sub prrrint_finish {
	my $pack = shift;

	print tabb;
}


# print print page
# ~~~~~~~~~~~~~~~~~
sub prrrint {
	my ($this, $members, $leaders) = @_;

	my @fields = qp 'fields';
	my @memberfields = qp 'memberfields';

	@fields = qw(name lead) unless @fields;

	# activity header if displaying members
	print row(join '', map { th($activitier->name($_)) } @fields) if @memberfields;

	# activity's data (show as heading if displaying members)
	print row($this->glimpse((join '', map {"[$_]"} @fields), { nohrefs => $qp::nohrefs }),
			@memberfields && 'class="head"');

	# maybe add member details
	if (@memberfields) {
		my $members = row(join '', map { th($personier->name($_)) } @memberfields);

		for my $member (members Register $this->id) {
			$members .= (take Person $member)->glimpse(
				"{". (join '', map {"[$_]"} @memberfields) ."}", { nohrefs => $qp::nohrefs }
			);
		}

		print row(td(tab($members), 'colspan="99"')).row(undef, 'class="space"');
	}

	# nothing more unless we can print
	return unless $user->can("prrrint");

	# push members & leaders into aggregation fields
	push @$members, members Register $this->{id};
	push @$leaders, leaders Lead $this->{id};

	my $printer = take Printer $user->printer;
	my $season = take Season $user->season;

	if ($qp::prrrintcover) {
		my $text = "\\tridnice\\obalka\n";
		$text .= '
			\moveright 15cm\vbox{
				\hsize 13cm
				\centerline{\hlava}
				\vskip 2cm \centerline{\fmega DENÍK}
				\vskip 1cm \centerline{\em{'. $season->name .'}}
				'. $this->glimpse('
						\vskip 1.5cm \vbox{
							\leftskip 2cm plus 1 fill
							\rightskip 2cm plus 1 fill
							\baselineskip 22pt
							\fheading name
						}
						\vskip 1.5cm \hbox{\hbox to 5cm{\hfill\em{vedoucí:\quad}} \vtop{leaders}}
						\vskip .5cm \hbox{\hbox to 5cm{\hfill\em{rozvrh:\quad}} \vtop{placement}}', { prrrint => 1, short => 1 }
					). '

			}
		';

		$printer->prrrint($text, "landscape");
	}

	if ($qp::prrrintfirst) {
		my $text = "\\tridnice\\prvni\n";
		$text .= '
			\def\one#1#2{\vskip .3cm \hbox{\hbox to 3cm{\hfill\em{#1:\quad}} \vtop{\hsize 9cm#2}}}
			\hbox{
				\vbox to 19cm{
					\hsize 13cm
					\vskip 1cm

					\em{Poznámky:}
					\vskip 3mm
					\vrule\vbox{
						\hsize 12cm
						\hrule
						\vskip 7cm\
						\hrule
					}\vrule
					\vfill
					\em{Zhodnocení činnosti:}
					\vskip 3mm
					\vrule\vbox{
						\hsize 12cm
						\hrule
						\vskip 7cm\
						\hrule
					}\vrule
				}%
				\hskip 2cm%
				\vbox to 19cm{
					\hsize 13cm
					'. $this->glimpse('
							\vskip 1.5cm \vbox{
								\leftskip 1cm plus 1 fill
								\rightskip 1cm plus 1 fill
								\baselineskip 22pt
								\fheading name
							}
							\vskip 1cm
							\one{popis}{description}
							\one{vedoucí}{leaders}
							\vskip 1cm
							\one{kategorie}{category}
							\one{obor}{field}
							\one{věk}{age}
							\one{rozvrh}{placement}
						', { prrrint => 1 }
					). '
					\vfill
					\em{Plán práce:}
					\vskip 3mm

					\vrule
					\vbox{
						\hsize 12cm
						\hrule
						\vskip 5cm
						\leavevmode\hfill\vrule width 5cm height .3pt\hfill\hfill\vrule height .3pt width 4.5cm\hfill\par
						\leavevmode\hfill podpis vedoucího\hfill\hfill podpis ředitele\hfill\par
						\vskip .5cm
						\hrule
					}%
					\vrule
				}
			}
		';

		$printer->prrrint($text, "landscape");
	}

	if ($qp::prrrintfirstindi) {
		my $contacts =
			'\halign{\quad#\hfill&\quad#\hfill&\quad#\hfill\quad\vrule width 0pt height 15pt depth 3pt\cr
				\em{jméno} & \em{narození} & \em{kontakt}\vrule width 0pt depth 7pt\cr
				\noalign{\hrule} '.
			(
			 	join '', map {(take Person $_)->glimpse('name & birthdate & onetel\cr ',
						{ prrrint => 1 })}
					members Register $this->{id}
			).
			'}';

		my $text = "\\tridnice\\prvni\n";
		$text .= '
			\def\one#1#2{\vskip .3cm \hbox{\hbox to 3cm{\hfill\em{#1:\quad}} \vtop{\hsize 9cm#2}}}
			\hbox{
				\vbox to 19cm{
					\hsize 13cm
					\vskip 1cm

					\em{Členové:}
					\vskip 3mm

					'. $contacts .'

					\vfill
					\em{Zhodnocení činnosti:}
					\vskip 3mm
					\vrule\vbox{
						\hsize 12cm
						\hrule
						\vskip 7cm\
						\hrule
					}\vrule
				}%
				\hskip 2cm%
				\vbox to 19cm{
					\hsize 13cm
					\centerline{\hlava}
					'. $this->glimpse('
							\vskip 1.5cm \vbox{
								\leftskip 1cm plus 1 fill
								\rightskip 1cm plus 1 fill
								\baselineskip 22pt
								\fheading name
							}
							\vskip 1cm
							\one{vedoucí}{leaders}
							\one{členové}{members}
							\vskip 1cm
							\one{období}{'. $season->name({ prrrint => 1 }) .'}
							\one{rozvrh}{placement}
						', { prrrint => 1 }
					). '
					\vfill
					\em{Plán práce:}
					\vskip 3mm

					\vrule
					\vbox{
						\hsize 12cm
						\hrule
						\vskip 5cm
						\leavevmode\hfill\vrule width 5cm height .3pt\hfill\hfill\vrule height .3pt width 4.5cm\hfill\par
						\leavevmode\hfill podpis vedoucího\hfill\hfill podpis ředitele\hfill\par
						\vskip .5cm
						\hrule
					}%
					\vrule
				}
			}
		';

		$printer->prrrint($text, "landscape");
	}

	# work sheets
	if ($qp::prrrintwork || $qp::prrrintworkwithsafety) {
		my $text = "\\tridnice\n";
		my $safety = $qp::prrrintworkwithsafety ? '\raise 1.5cm\hbox{Poučení o bezpečnosti práce.}' : '';
		my $introduction = $qp::prrrintworkwithsafety ? '\raise 1.5cm\hbox{Seznámení se Salesiánským střediskem mládeže.}' : '';
		$text .= '
			\def\oneline{\vrule height 2.2cm width 0pt & & & \ \cr\noalign{\hrule}}
			\hbox{
				\vbox to 19cm{
					\hsize 13cm
					\vskip .5cm
					\em{Výkaz práce}
					\vskip 3mm

					\halign{
						\offinterlineskip
						\vrule\quad #\quad&\vrule\quad#\quad&\vrule\quad#\quad\hfill&\vrule\qquad#\qquad\vrule\cr\noalign{\hrule}%
						\vrule height 15pt depth 7pt width 0pt
						datum&počet&program schůzky\hskip 4cm&podpis\cr\noalign{\hrule depth 1pt}
						\vrule height 2.2cm width 0pt & & '. $safety .' & \ \cr\noalign{\hrule}
						\vrule height 2.2cm width 0pt & & '. $introduction .' & \ \cr\noalign{\hrule}
						\oneline%
						\oneline%
						\oneline%
						\oneline%
						\oneline%
					}

					\vfill
					deník zkontrolován dne\quad\vrule depth .3pt height 0pt width 3cm
					\hfill
					podpis\quad\vrule depth .3pt height 0pt width 3cm\par
				}\hskip 2cm
				\vbox to 19cm{
					\hsize 13cm
					\vskip .5cm
					\em{Výkaz práce}
					\vskip 3mm

					\halign{
						\offinterlineskip
						\vrule\quad #\quad&\vrule\quad#\quad&\vrule\quad#\quad\hfill&\vrule\qquad#\qquad\vrule\cr\noalign{\hrule}%
						\vrule height 15pt depth 7pt width 0pt
						datum&počet&program schůzky\hskip 4cm&podpis\cr\noalign{\hrule depth 1pt}
						\oneline%
						\oneline%
						\oneline%
						\oneline%
						\oneline%
						\oneline%
						\oneline%
					}

					\vfill
					deník zkontrolován dne\quad\vrule depth .3pt height 0pt width 3cm
					\hfill
					podpis\quad\vrule depth .3pt height 0pt width 3cm\par
				}%
			}
		';

		$printer->prrrint($text, "landscape");
	}

	if ($qp::prrrintlist) {
		my $text = "\\tridnice\n";
		my @members = members Register $this->{id};
		# push empty places (plus extra empty lines)
		push @members, (map {0} (1..($this->{max} - @members + $Conf::PrintExtraRows))) if $this->{max};
		my $perpage = 30;
		my $totalpages = 1 + int scalar @members / ($perpage + 1);
		my $page = 1;

		while (my @pagers = splice @members, 0, $perpage) {
			$text .= '
				\vbox to 19cm {
					\vskip .5cm
					\em{Docházka}
					\vskip 3mm

					\halign{
						\offinterlineskip
						\vrule\quad # \hfill\quad\vrule&\quad\hfill #\quad\vrule&\quad #\hfill '. ('\quad\vrule' x 51) .'\cr\noalign{\hrule}%
						\vrule height 24pt depth 4pt width 0pt \em{jméno} & \em{narození}\hfill & \hfill\em{telefon}\cr\noalign{\hrule depth 1pt}';

				for my $pid (@pagers) {
					if ($pid) {
						$text .= (take Person $pid)->glimpse('\vrule height 11pt depth 4pt width 0pt name & birthdate & onetel\cr\noalign{\hrule} ', { prrrint => 1 });
					}
					else {
						$text .= '\vrule height 11pt depth 4pt width 0pt\hskip 4cm & & \cr\noalign{\hrule} ';
					}
				}

			$text .= $this->glimpse("}\\vfil name / placementshort ($page/$totalpages)\\hfilll \\hbox{Značení: \\em{/} přítomen, \\em{--} nepřítomen, \\em{o} omluven\\break}, \\em{o}\\hskip -1.5mm\\em{-} omluven dodatečně}\\eject ",
					{ prrrint => 1, break => ', ' });
			$page++;
		}

		$printer->prrrint($text, "landscape");
			#\def\II{\vrule height 27pt depth 7pt width .5pt }
			#\def\I{\vrule height 11pt depth 4pt width .5pt }
	}
}



# info list of registrations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub registrations {
	my $this = shift;

	my $registrations = join '',
		map {(take Register $_)->glimpse("{[person][start][finish][base][price][debt][registrar][created][details]}")}
		#map {(take Register $_)->edit}
			activity Register $this->{id};
	$registrations = row(tt("človíček"). tt("zapsána k"). tt("zrušena k").
			tt("základ"). tt("cena"). tt("zaplatit"). tt("registroval"). tt("dne"). tt("detaily")).
			$registrations if $registrations;
	print tab(
			row(td(div($this->glimpse("name"), 'class="heading"'))).
			row(td(tab($registrations || "v tomto období žádné registrace")))
	, 'class="card"');
}


# export free activities into nice html page
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list {
	my $pack = shift;

	return unless $Conf::FreeActivitiesFilename;

	# open file
	open file, ">$Conf::FreeActivitiesFilename"
		or error("nemůžu otevřít soubor pro zápis volných kroužků"), return;

	# get text from setup
	my $text = (take Setup)->free_activities_text;

	# header
	print file $Conf::FreeActivitiesHeader, '<h3>Seznam volných aktivit '.
		(take Season $user->season)->name ."</h3>

		". ($text && "<p>$text</p>");

	for my $type ($Conf::ActivityTypeOneTime, $Conf::ActivityTypeRegular, $Conf::ActivityTypeOther) {
		my @aids = free Activity $type;
		next unless @aids;

		print file "<p class=\"nadpis\"><a href=\"#$type\" name=\"$type\">".
			{ 1 => "Tábory, jednorázové akce", 2 => "Pravidelné aktivity", 3 => "Ostatní aktivity" }->{$type} .
			'</a></p><table style="clear: both;">';
		# list all categories
		my $category;
		for my $aid (@aids) {
			my $activity = take Activity $aid;
			if ($activity->glimpse("category") ne $category) {
				$category = $activity->glimpse("category");
				print file $activity->glimpse('{<th>category</th>').
					(join '', map { th($_) } qw(rozvrh věk míst cena vedoucí podrobnosti)).roww;
			}
			print file $activity->glimpse('{[name][placementshort][<nobr>age</nobr>][free][price]
					[<nobr>lead</nobr>][details]}', { nohrefs => 1, short => 1 });
		}
		print file '</table>';
	}

	# footer
	print file '<h6>aktualizováno '.
		$now->user_stamp(undef, { long => 1 }) .'</h6>', $Conf::FreeActivitiesFooter;
			#<h5>Seznam není kompletní ani konečný (některé údaje se ještě mohou změnit).</h5>

	# close
	close file;

	return "ok";
}


# save changed data
# ~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update activities set
			name		=  '%s',
			description	=  '%s',
			condition	=  '%s',
			note		=  '%s',
			type		=   %s,
			sex		=   %s,
			fixed		=   %s,
			pub		=   %s,
			open		=   %s,
			card		=   %s,
			season		=   %s,
			category	=   %s,
			field		=   %s,
			min		=   %s,
			max		=   %s,
			youngest	=   %s,
			oldest		=   %s,
			price		=   %s,
			deposit		=   %s,
			start		=   %s,
			finish		=   %s,
			updated		=  now()
			where id = $this->{id}",
			(uq(@$this{qw(name description condition note)}),
			qd(@$this{qw(type sex fixed pub open card season category field min max youngest oldest price deposit)},
				$this->{start}->db_date, $this->{finish}->db_date))
		);
}


# glimpse at the activity in one <table> row
# ~~~~~~~
# <<  format -- string containing list of columns to be showed
# <<  par -- format parameters
sub glimpse {
	my ($this, $format, $par) = @_;

	my $break = $par->{break} || ($par->{prrrint} ? '\break ' : br);
	my $dash = $par->{prrrint} ? '--' : '-';
	my %gl;
	%gl = (
		age		=> sub {
					if ($this->{youngest}) {
						$this->{oldest} ? "$this->{youngest}$dash$this->{oldest}" : "od $this->{youngest}";
					}
					else {
						$this->{oldest} ? "do $this->{oldest}" : $dash;
					}
				},
		sex		=> sub { $this->{sex} && $sexer->name($this->{sex}) },
		category	=> sub { $categorier->name($this->{category}) },
		field		=> sub { $fielder->name($this->{field}) },

		coordinator	=> sub { join $break, map {(take Person $_)->glimpse("name", $par)} leaders Lead $this->{id}, $Conf::Ranks{coordinator} },
		leader		=> sub { join $break, map {(take Person $_)->glimpse("name", $par)} leaders Lead $this->{id}, $Conf::Ranks{leader} },
		leaders		=> sub { join $break, map {(take Person $_)->glimpse("name", $par)} leaders Lead $this->{id} },
		lead		=> sub { &{$gl{coordinator}} or &{$gl{leader}} },


		members		=> sub { join $break, map {(take Person $_)->glimpse("name", $par)} members Register $this->{id} },
		memberstels	=> sub { join $break, map {(take Person $_)->glimpse("name (onetel)", $par)} members Register $this->{id} },

		description	=> sub { $this->{description} },
		condition	=> sub { uqq($this->{condition}) },
		note		=> sub { uqq($this->{note}) },

		price		=> sub { "$this->{price},-" },
		deposit		=> sub { "$this->{deposit},-" },
		fixed		=> sub { $fixer->name($this->{fixed}) },

		min		=> sub { $this->{min} },
		max		=> sub { $this->{max} },

		count		=> sub { $this->{count} },
		free		=> sub { defined $this->{max} ? $this->{free} : "hafo" },
		load		=> sub {
						my $percent = int 100 * $this->{count} / ($this->{max} || $Conf::LoadHafo);
						$percent = 111 if $percent > 111;
						"<div class=\"load\">".
							($percent ? "<div class=\"bar\" style=\"width: $percent%;\">\&nbsp;</div>" : "").
							"<div class=\"fraction\">$this->{count}/". (defined $this->{max} ? $this->{max} : "hafo")."</div>".
						"</div>"
				},
		start		=> sub { $this->{start}->db_date && $this->start->user_date(undef,
						{ long => 1, prrrint => $par->{prrrint} })},
		starts		=> sub { $this->{start}->db_date && $this->start->user_date(undef,
						{ prrrint => $par->{prrrint} })},
		finishes	=> sub { $this->{finish}->db_date && $this->finish->user_date(undef,
						{ prrrint => $par->{prrrint} })},

		open		=> sub { $opener->name($this->{open}) },
		card		=> sub { $carder->name($this->{card}) },
		pub		=> sub { $puber->name($this->{pub}) },

		details		=> sub {
						join ' ', grep {$_}
							($this->{description}),
							($this->{condition} && "Podmínka: $this->{condition}"),
							(&{$gl{sex}} && "Pouze ".&{$gl{sex}} ."."),
							($this->{deposit} && "Nevratná záloha: $this->{deposit},-"),
							($this->{type} != $Conf::ActivityTypeOneTime && &{$gl{start}} && "Začátek ". &{$gl{start}} .".");
					},


		( $par->{nohrefs} || $par->{prrrint}
			? (
				name		=> sub {	if ($par->{prrrint}) {
									my $name = $this->{name};
									$name =~ s/-/--/g;
									return $name;
								}
								# add season name when browsing through all seasons
								$this->name . ($user->season eq "season" ? " (". (take Season $this->{season})->name. ")" : "");
							},
				dates		=> sub { $this->{start}->user_date && $this->{start}->user_date(undef, { short => 1, prrrint => $par->{prrrint} }).
								($this->{finish}->db_date ne $this->{start}->db_date
								 && $dash.$this->{finish}->user_date(undef, { short => 1, prrrint => $par->{prrrint} })) },
				placement	=> sub { ($this->{type} == $Conf::ActivityTypeOneTime && &{$gl{"dates"}}." ").
								(join $break, map {(take Place $_)->prrrint($par->{short}, $dash)} activity Place $this->{id}).
								($this->{type} == $Conf::ActivityTypeRegular && $par->{prrrint} &&
								 $this->{start}->db_date && $break .'od '. $this->start->user_date(undef, { long => 1, prrrint => $par->{prrrint} }))
							},
				flags		=> sub {
								($this->open ? "o" : "z").
								($this->card ? "k" : "n").
								($this->pub ? "v" : "i")
							}
			) : (
				name		=> sub { return undef unless $this->name;
								# add season name when browsing through all seasons
								my ($name, $namee) = $this->name =~ /^(.*)(.)$/;
								my $nameee = ($user->season eq "season" ? "(". (take Season $this->{season})->name. ")" : "");
								# description tooltip for internal activities should display its leaders
								# no -- have found a better way
								#my $description = uqq $this->pub ? $this->{description} :
									#join ', ', map {(take Person $_)->glimpse("name", { prrrint =>  1})} leaders Lead $this->{id};
								my $description = uqq $this->{description};

							 "<a href=\"$Conf::Url/aktivity/aktivity.pl?aids=$this->{id}\" title=\"$description\">". uqq($name) ."</a>".
							 "<a href=\"$Conf::Url/aktivity/aktivity.pl?aids=$this->{id}&action=edit\">". uqq($namee) ."</a>".
							 ($nameee && " <a href=\"$Conf::Url/aktivity/aktivity.pl?aids=$this->{id}\">". uqq($nameee) ."</a>")

							 },
				dates		=> sub { $this->{start}->user_date && $this->{start}->user_date_short.
								($this->{finish}->db_date ne $this->{start}->db_date && "-".$this->{finish}->user_date_short) },
				placement	=> sub { ($this->{type} == $Conf::ActivityTypeOneTime && &{$gl{"dates"}}." ").
								join br, map {(take Place $_)->show($par->{short})} activity Place $this->{id}
							},
				flags		=> sub {
								($this->open ? '<span title="otevřená">o<span>' : '<span title="zavřená">z').
								($this->card ? '<span title="kartičková">k</span>' : '<span title="nekartičková">n</span>').
								($this->pub ? '<span title="veřejná">v</span>' : '<span title="interní">i</span>')
							}
			)
		),
				place		=> sub {
								join $break, uniqss map {(take Place $_)->glimpse("place", $par)
									} activity Place $this->{id}
							},

				placementshort	=> sub { ($this->{type} == $Conf::ActivityTypeOneTime && &{$gl{"dates"}}." ").
								join $break, uniqss map {(take Place $_)->glimpse(
									"summary", { short => 1, prrrint => $par->{prrrint}, nohrefs => $par->{nohrefs},
										detail => ($this->{type} != $Conf::ActivityTypeRegular) }
									#"summary", { short => 1 }
								)} activity Place $this->{id}
							},
				placementshortest	=> sub { ($this->{type} == $Conf::ActivityTypeOneTime && $this->{start}->user_date
									&& $this->{start}->user_date_short ." ").
								join $break, uniqss map {(take Place $_)->glimpse(
									"summary", { short => 1, detail => 0, supershort => 1 }
									#"summary", { short => 1 }
								)} activity Place $this->{id}
							}
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# return query for browsing
#        ~~~~~~~~~~~~~~~~~~
# >>  query of all the activities
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor ( 0 => "jména", 1 => "času", 2 => "ceny", 3 => "id");
	my $puber = new Inquisitor (0 => "všechny", 1 => "veřejné", 2 => "interní");
	my $opener = new Inquisitor (0 => "všechny", 1 => "otevřené", 2 => "zavřené");
	my $freeer = new Inquisitor (0 => "všechny", 1 => "volné", 2 => "prázdné", 3 => "neprázdné", 4 => "nenaplněné", 5 => "plné");
	my @days = ck qp "day";

	my ($condition, $except, $direct, $directaction, $search, $freeonly);

	# if there's a '+' at the beginning, search only for free activities
	$freeonly = $qp::search =~ s/^\+//g;

	# let's start with parsing search string
	$search = $qp::search;

	# remove direct modifiers (and count them)
	if ($direct = $search =~ s/\s*([?!+\-\/]+)\s*$//g) {
		# how dogged is the direct jump
		$direct = length $1;
		# what king of redirection?
		$directaction = {
			"?" => "show",
			"!" => "edit",
			"+" => "register",
			"-" => "members",
			"/" => "prrrint"
		}->{substr($1, 0, 1)} if $direct;
	}

	# remove ',' and space from beginning and end
	$search =~  s/[,\s]*$//;
	$search =~ s/^[,\s]*//;

	# let's go!
	for my $word ($search =~ /(\s*,\s*|\s+|[^\s,]+)/g) {
		# convert escaped space (as '_') back to normal
		$word =~ s/_/ /g;
		$word = uq $word;

		# minus sign means 'not'
		if ($word =~ /^-(.*)$/) {
			$condition .= " not ";
			$word = $1;
		}

		# space means 'and'
		if ($word =~ /^\s+$/) {
			$condition .= " and ";
		}
		# comma means 'or'
		elsif ($word =~ /^(\s*,\s*)$/) {
			$condition .= " or ";
		}
		# search according to ids
		elsif ($word =~ /^id:(\d+)$/) {
			$condition .= "(a.id = $1)";
		}
		# select by time (since)
		elsif (($word =~ /^od:(\d+)$/) && (my $time = user_time Time $1)) {
			$condition .= "(p.finish >= '". $time->db_time ."')";
		}
		# select by time (until)
		elsif (($word =~ /^do:(\d+)$/) && (my $time = user_time Time $1)) {
			$condition .= "(p.start <= '". $time->db_time ."')";
		}
		# in direct search name & note only
		elsif ($direct || $freeonly) {
			$condition .= "(name ~* '$word' or note ~* '$word')";
		}
		# otherwise search everything
		else {
			$condition .= "(name ~* '$word' or description ~* '$word'
				or condition ~* '$word' or note ~* '$word' or p.detail ~* '$word')";
		}
	}
	# and last adjustment
	$condition = " and ($condition)" if $condition;

	# type condition
	my $type = ck $qp::type;
	$type = $Conf::ActivityTypeRegular if @days;
	$condition .= " and type = '$type'" if $type;

	# select categories
	my @categories = ck qp "category";
	$condition .= " and (". (join ' or ', map {"category = $_"} @categories) .")" if @categories;

	# age filter
	my $age = defined $qp::age ? ck $qp::age : ck $par->{age};
	$condition .= " and (youngest <= $age or youngest is null) and (oldest >= $age or oldest is null)" if defined $age;

	# sex filter
	my $sex = defined $qp::sex ? uq($qp::sex) : $par->{sex};
	$condition .= " and (sex = '$sex' or sex is null)" if $sex;

	# pub & open & free filters
	my $open = ck $qp::open;
	my $pub = ck $qp::pub;
	my $free = ck $qp::free;
	# set to open, pub and free when not supplied or searching for $freeonly
	$open = 1 if $freeonly || not defined $open;
	$pub = 1 if $freeonly || not defined $pub;
	$free = 1 if $freeonly || not defined $free;

	$condition .= { 1 => " and open", 2 => " and not open"}->{$open};
	$condition .= { 1 => " and pub", 2 => " and not pub"}->{$pub};

	# and finish with season condition
	$condition = "season = ". $user->season . $condition;

	# free filter
	$except .= {
		# free activities only
		#1 => " intersect select a.id, a.name, a.season, a.price, p.day, p.start
		#	from activities_free a
		#	join placed p on p.activity = a.id
		#	where free > 0 or free is null",
		1 => " except select a.id, a.name, a.season, a.price, p.day, p.start
			from activities_free a
			join placed p on p.activity = a.id
			where free <= 0",
		# empty activities
		2 => " intersect select a.id, a.name, a.season, a.price, p.day, p.start
			from activities_free a
			join placed p on p.activity = a.id
			where count = 0",
		# non-empty activities
		3 => " intersect select a.id, a.name, a.season, a.price, p.day, p.start
			from activities_free a
			join placed p on p.activity = a.id
			where count > 0",
		# activities with too few members
		4 => " intersect select a.id, a.name, a.season, a.price, p.day, p.start
			from activities_free a
			join placed p on p.activity = a.id
			where count < min",
		# full activities only
		5 => " intersect select a.id, a.name, a.season, a.price, p.day, p.start
			from activities_free a
			join placed p on p.activity = a.id
			where free <= 0"
	}->{$free};

	# days filtering
	$condition .= " and (". (join " or ", map { "p.day = $_" } @days) .")" if @days;

	# days filtering !!! UGLY, UGLY, UGLY !!!
	# (triple join because of minday & minstart make combinations of day&time that does not exist)
	# (and we have to get rid of them here)
	#	$except .= " except select a.id, a.name, a.season, a.price, q.day, r.start
	#		from activities a
	#		join placed p on p.activity = a.id
	#		join placed q on q.activity = a.id
	#		join placed r on r.activity = a.id
	#		where $condition and
	#		(". (join ' and ', map { ) .")";

	# set sorting
	my $sort = ck($qp::sort) || 0;

	#######################################################
	# build up the main query
	# (condition "or min(p.day) is null" is neccessary for including activities with specified hours but no day
	my $cleaver = query Cleaver
		"select a.id, a.name, a.season, a.price, min(p.day) as minday,
			(select min(start) from placed q where (q.day = min(p.day) or min(p.day) is null) and q.activity = a.id) as minstart
			from activities a
			left outer join placed p on p.activity = a.id
			where $condition group by a.id, a.name, a.season, a.price, a.start $except
		order by ". ( { 0 => "name, season, minday, minstart",
				1 => "minday, minstart, a.start, name",
				2 => "price, name, minday, minstart",
				3 => "id" }->{$sort} ),
    			$direct > 2 && $Conf::SliceSizesGreat;

	if (!$cleaver->empty && ($direct > 1 || $direct == 1 && $cleaver->total == 1 )) {
		my @aids;
		while (my ($aid) = $cleaver->next) {
			push @aids, $aid;
		}
		header undef, { redir => "$Conf::UrlActivities/?action=".$directaction."&aids=". join '.', @aids };
		return;
	}

	header $par->{header}, { javascript => "yes" } if $par->{header};
	form $par->{navigform}, "navig" if $par->{navigform};
	print tab(
		row(td(tab(
			row(
				td($categorier->multi("category", undef, @categories), 'rowspan="3"').
				td($dayer->multi("day", undef, @days), 'rowspan="3"').
				th("typ:").
				td($typer->select("type", uqq $type, "všechny")).
				td($opener->radio("open", br, $open), 'rowspan="3"').
				td($puber->radio("pub", br, $pub), 'rowspan="3"').
				td($freeer->radio("free", br, $free), 'rowspan="3"')
			). row(
				th("pohlaví:").
				td($sexer->select("sex", $sex))
			). row(
				th("věk:").
				td(input("age", $age, 3, 3))
			)
		))). row(td(tab(
			row(
				th("setřídit:").
				td($sorter->select("sort", $sort)).
				th("na stránku:").
				td($cleaver->slice).
				td(input("search", uqq $qp::search)).
				td(submit "", "najít")
			)
		))). row(td(tab(
			row(
				td("nalezené aktivity (" . $cleaver->info . ")", 'colspan="2"').
				td($cleaver->control, 'colspan="3"')
			)
		)))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná aktivita<p>"), return if $cleaver->empty;

	my $prefix = $par->{prefix} || "a";
	my $ider = new Ider ($prefix);

	#######################################################
	# start table
	my @headers = $par->{headers} ? @{$par->{headers}} : ("", qw(název detaily cena obsazeno věk vede kategorie stav));
	print tab(undef, 'class="scraps"'),
		row join '', map {th($_)} @headers;

	# glimpses
	while (my ($aid) = $cleaver->next) {
		my $p = take Activity $aid;
		print $p->glimpse($par->{glimpse} || '{[#][name][placement][price][load][age][lead][category][flags]}', {ider => $ider});
	}

	# finish table
	print row(td(checkall("$prefix.*$prefix.*$prefix"), 'colspan="9" class="footer"')), tabb;

	# we have found something
	1
}


# get short activity statistics
sub stats {
	$dbi->exe("select count(*) from activities
			where pub and season = ". $user->season);
	my $total = $dbi->val;

	$dbi->exe("select count(*) from activities_free
			where pub
			and count > 0
			and season = ". $user->season);
	my $nonempty = $dbi->val;

	return "$total ". infl($total, qw(aktivita aktivity aktivit)).
		", $nonempty ". infl($nonempty, qw(neprázdná neprázdné neprázdných));
}


1

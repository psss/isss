package Person;

  #######################################################
 ####  Person -- handling persons  #####################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new person
#  > take		constructor (takes pid)
#  > delete		delete a person
#
#  > browse		browsing the person
#  > stats		short person stats
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > name
#  > surname
#  > photo
#  > birthdate
#  > birthnumber
#  > sex
#  > animator
#  > street
#  > town
#  > zip
#  > email
#  > tel
#  > mobil
#  > mother
#  > father
#  > pmobil
#  > pemail
#  > infomail
#  > health
#  > insurance
#  > hobbies
#  > note
#  > created
#  > updated
#  > a			'a' if female, nothing otherwise (czech verbs)
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#  > name		get the name
#  > age		find out person's age
#  > animator		true if person is animator
#  > children		search for children
#  > mother		search for mother
#  > father		search for father
#
#  > glimpse		one <tr> info 'bout the person
#
#  > edit		make formular for editing
#  > show		show person info
#  > register		add/remove activities
#  > payments		payments listing
#
#  > save		save data into db

use locale;
use strict qw(subs vars);

use Aid;
use Ider;
use Card;
use Lead;
use Time;
use Cleaver;
use Message;
use Printer;
use Register;
use Inquisitor;

my $sexer = sex Inquisitor;
my $sexer2 = sex2 Inquisitor;
my $yesnoer = yesno Inquisitor;
my $personier = person Inquisitor;
my $activitier = activity Inquisitor;
my $infomailer = infomail Inquisitor;
my $insurancier = insurance Inquisitor;
my $shortinsurancier = shortinsurance Inquisitor;

my @attr = qw(id name surname photo birthdate birthnumber sex animator street
	town zip email tel mobil mother father pmobil pemail infomail health
	insurance hobbies note created updated);

# create new person (empty)
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
	my $id;

        # make sure user can create new persons
        error("nemáš právo vytvářet osoby"), return undef unless $user->can("edit_persons");

	# insert into db
	$dbi->beg;
		$dbi->exe("insert into persons (created, animator, infomail) values (now(), 'f', 't')");
		$dbi->exe("select currval('persons_id_seq')");
		$id = $dbi->val;
	$dbi->end;

	take Person $id;
}



# constructor for existing persons
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $pid) = @_;
	return undef unless $pid;

	my $this = {};

	$dbi->exe("select ". (join ", ", @attr) ." from persons where id = '". uq($pid) ."'")
		or error("taková osoba neexistuje (". $pid .")"), return undef;
	@$this{@attr} = $dbi->row;

	$this->{birthdate} = db_date Time $this->{birthdate};
	$this->{created} = db_stamp Time $this->{created};
	$this->{updated} = db_stamp Time $this->{updated};

	$this->{animator} = $this->{animator} eq 't' ? 1 : 0;
	$this->{infomail} = $this->{infomail} eq 't' ? 1 : 0;
	$this->{a} = $this->{sex} eq 'f' && 'a';

	bless $this;
}




# give birth to new person
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub birth {
	my ($pack, $pid) = @_;

	my $parent = take Person $pid;
	my $newborn = create Person;

	# copy name
	$newborn->{surname} = $parent->{surname};
	# set mother's/father's name
	($parent->a ? $newborn->{mother} : $newborn->{father}) = $parent->{name}. " ". $parent->{surname};

	# address
	$newborn->{street} = $parent->{street};
	$newborn->{town} = $parent->{town};
	$newborn->{zip} = $parent->{zip};

	# contacts
	$newborn->{tel} = $parent->{tel};
	$newborn->{pmobil} = $parent->{mobil};
	$newborn->{pemail} = $parent->{email};
	$newborn->{infomail} = $parent->{infomail};

	# insurance
	$newborn->{insurance} = $parent->{insurance};

	# save data
	$newborn->save;

	$newborn;
}



# deleting a person
# ~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat osoby"), return undef unless $user->can("edit_persons");

	if ($dbi->exe("delete from persons where id = $this->{id}", "try")) {
		# and delete the photo
		$dbi->rm($this->{photo}) if $this->{photo};
		message($this->name ." byl$this->{a} smazán$this->{a}");
		return "ok";
	}
	else {
		error ($this->name ." už nemůže být smazán$this->{a}");
		return undef;
	}
}


sub id {
	my $this = shift;

	$this->{id};
}


sub name {
	my $this = shift;

	return "$this->{name} $this->{surname}" if $this->{name} || $this->{surname};
	undef;
}


sub firstname {
	my $this = shift;

	$this->{name};
}


# czech female ending
sub a {
	my $this = shift;

	$this->{a};
}


sub age {
	my ($this, $yearsonly, $date) = @_;

	# if there is no birthdate, there is no age :-)
	return "" unless $this->{birthdate}->db_date;

	# use supplied date, otherwise use now
	my $since = "timestamp '".
		(($date && $date->db_date) ? $date->db_date : $now->db_date)
		 ." 23:59:59',";

	# brief years-only version
	if ($yearsonly) {
		$dbi->exe("select extract(years from age($since timestamp '". $this->{birthdate}->db_date ."'))");
		return $dbi->val;
	}
	# detail with months and days
	else {
		$dbi->exe("select age($since timestamp '". $this->{birthdate}->db_date ."')");
		return ymd($dbi->val);
	}
}


# is this person adult?
sub adult {
	my ($this) = @_;

	return $this->age("yearsonly") >= $Conf::AdultAge;
}


# search for person's children
sub children {
	my ($this) = @_;

	# without birthdate we can do nothing
	return () unless $this->{birthdate}->db_date;

	$dbi->exe("select id from persons where ".
		($this->a ? "mother" : "father") ." = '$this->{name} $this->{surname}'
		and street = '$this->{street}' and town = '$this->{town}'
		and age(birthdate, '". $this->{birthdate}->db_date ."') > '$Conf::GravidityAge years'
		order by surname, name");

	return $dbi->vals
}

# search for mother
sub mother {
	my $this = shift;

	# without birthdate we can do nothing
	return undef unless $this->{birthdate}->db_date;

	$this->{mother} =~ /(\S+)\s(\S+)/;
	return unless $dbi->exe("select id from persons where
		name = '$1' and surname = '$2'
		and age('". $this->{birthdate}->db_date ."', birthdate) > '$Conf::GravidityAge years'
		and street = '$this->{street}' and town = '$this->{town}'");
	$dbi->val;
}



# search for father
sub father {
	my $this = shift;

	# without birthdate we can do nothing
	return undef unless $this->{birthdate}->db_date;

	$this->{father} =~ /(\S+)\s(\S+)/;
	return unless $dbi->exe("select id from persons where
		name = '$1' and surname = '$2'
		and age('". $this->{birthdate}->db_date ."', birthdate) > '$Conf::GravidityAge years'
		and street = '$this->{street}' and town = '$this->{town}'");
	$dbi->val;
}



# search for parents
sub parents {
	my $this = shift;

	return grep {$_} $this->father, $this->mother;
}


# is this person animator?
sub animator {
	my $this = shift;

	$this->{animator};
}


# how many activities person leads in current season
sub leads {
	my ($this, $season) = @_;

	$season = $user->season unless defined $season;

	$dbi->exe("select count(activity) from lead l
			join activities a on l.activity = a.id
			where l.leader = $this->{id}
			  and a.season = $season");
	$dbi->val;
}


sub sex {
	my $this = shift;

	$this->{sex};
}


sub photo {
	my ($this, $class, $href) = @_;

	($href && "<a href=\"$Conf::UrlPersons?pids=$this->{id}\">").
	"<img src=\"". ($this->{photo} ? "$Conf::UrlPhoto$this->{photo}" : $Conf::UrlNoPhoto).
		"\" class=\"$class\" title=\"".$this->name."\"/>".
	($href && "</a>")
}


# get online map url for person's address
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub map {
	my $this = shift;

	$Conf::UrlMap .urrrl("$this->{street} $this->{town}");
}

# get person's photo's oid
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub photoid {
	my $this = shift;

	$this->{photo};
}


# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
# >> persons id (can change when there are duplicates)
sub edit {
        my $this = shift;

        # make sure user can edit this person
        error("nemáš právo upravovat osobu"), $this->show, return $this->{id} unless $user->can("edit_persons");
	my %err;


	if (defined ${"qp::p$this->{id}name"}) {
		# get new values
		for my $val (qw(name surname birthnumber birthdate sex animator
				street town zip tel mobil email mother father pmobil
				pemail infomail health insurance hobbies note)) {
			$this->{$val} = ${"qp::p$this->{id}$val"};

			# remove trailing spaces
			$this->{$val} =~ s/^\s*//;
			$this->{$val} =~ s/\s*$//;
			$this->{$val} =~ s/\s{2,}/ /;
		}

		# set/check birthdate -- if got some and it's bad -- then cry out!
		$this->{birthdate} = user_date Time $this->{birthdate};
		if (${"qp::p$this->{id}birthdate"} and not $this->{birthdate}->db_date) {
			$err{birthdate} = err "nesprávné datum"
		}

		# maybe set sex according to person's surname
		unless ($this->{sex} && $this->{surname}) {
			$this->{sex} = $this->{surname} =~ /á$/ ? 'f' : 'm';
		}

		# set vowel for females
		$this->{a} = $this->{sex} eq 'f' && 'a';

		# check the birthnumber
		if ($this->{birthnumber}) {
			my ($date, $sex) = parse_birth $this->{birthnumber};
			if ($date && (user_date Time $date)->user_date) {
				$this->{birthdate} = user_date Time $date;
				$err{birthdate} = "";
				$this->{sex} = $sex;
			}
			else {
				$err{birthnumber} = err "nesprávné rodné číslo";
			}
		}

		# maybe add/change photo
		if (my $phot = ${"qp::p$this->{id}photo"}) {
			if (my $oid = $dbi->save("p$this->{id}photo", $this->{photo})) {
				$this->{photo} = $oid;
			}
			else {
				$err{photo} = err "nepodařilo se nahrát novou fotografii";
			}

		}

		# check zip code
		if ($this->{zip}) {
			my @ar = $this->{zip} =~ /(\d)/g;
			unless (@ar == 5) {
				$err{zip} = err "neplatné psč";
			}
			else {
				$this->{zip} = "$ar[0]$ar[1]$ar[2] $ar[3]$ar[4]";
			}
		}
		# and phone numbers
		for my $tel (qw(tel mobil pmobil)) {
			if ($this->{$tel}) {
				my @ar = $this->{$tel} =~ /(\d)/g;
				unless (@ar == 9) {
					$err{$tel} = err "neplatné číslo";
				}
				else {
					$this->{$tel} = "$ar[0]$ar[1]$ar[2] $ar[3]$ar[4]$ar[5] $ar[6]$ar[7]$ar[8]";
				}
			}
		}
		# check insurance
		$this->{insurance} = ck $this->{insurance};
		$this->{insurance} = undef unless $this->{insurance};

		# check for duplicates
		my $condition = join ' or ', grep {$_} (
				($this->{birthnumber} && $this->{birthnumber} != '1111111111' &&
					"(birthnumber = '$this->{birthnumber}')" ),
				($this->{birthdate}->db_date && $this->{name} && $this->{surname} &&
					"(birthdate = '". $this->{birthdate}->db_date ."'
						and name = '". uq($this->{name}) ."'
						and surname = '". uq($this->{surname}) ."')")
			);

		if ($condition && $dbi->exe("select id from persons where id != $this->{id} and ($condition)")) {
			my $pid = $dbi->val;
			message "tak tohodle človíčka už tady máme!";
			$this->{name} = "duplikát";
			$this->{surname} = "";
			$this->{a} = "";
			$this->delete;
			$this = take Person $pid;
		}
		# otherwise simply save
		else {
			# save changes
			$this->save;
			message "uloženo";
		}
	};

	print tab(
	row(
		td(div($this->name && $this->glimpse("name") || "Nový človíček", 'class="heading"')).
		td(tab(
			row(td(($this->glimpse("photo")))).
			row(td("\n\t\t\t<input type=\"file\" name=\"p$this->{id}photo\"/>".$err{photo}))
		), 'rowspan="3"')
	). row(td(tab(
		row(
			th("<u>j</u>méno:").
			td(input("p$this->{id}name", uqq($this->{name}), $Conf::NameSize, $Conf::NameMax, 'accesskey="j"'))
		). row(
			th("příjmení:").
			td(input("p$this->{id}surname", uqq($this->{surname}), $Conf::NameSize, $Conf::NameMax))
		). row(
			th("<u>r</u>odné číslo:").
			td(input("p$this->{id}birthnumber", uqq($this->{birthnumber}), 12, 10, 'accesskey="r"').$err{birthnumber})
		). row(
			th("datum narození:").
			td(input("p$this->{id}birthdate",
				uqq($this->{birthdate}->user_date || ${"qp::p$this->{id}birthdate"}),
				@Conf::InputDate).$err{birthdate})
		). row(
			th("pohlaví:").
			td($sexer->radio("p$this->{id}sex", " ", ($this->{sex} or 'n')))
		). row(
			th("animátor:").
			td($yesnoer->radio("p$this->{id}animator", " ", $this->{animator}))
		)))
	). row(
		td(tab(
			row(
				th("<u>u</u>lice:").
				td(input("p$this->{id}street", uqq($this->{street}), @Conf::InputName, 'accesskey="u"'))
			). row(
				th("město:").
				td(input("p$this->{id}town", uqq($this->{town}), $Conf::NameSize, $Conf::NameMax))
			). row(
				th("psč:").
				td(input("p$this->{id}zip", uqq($this->{zip}), 6, 6).$err{zip})
			))
		)
	). row(
		td(tab(
			row(
				th("<u>t</u>elefén:").
				td(input("p$this->{id}tel", uqq($this->{tel}), @Conf::InputTel, 'accesskey="t"').$err{tel})
			). row(
				th("mo<u>b</u>il:").
				td(input("p$this->{id}mobil", uqq($this->{mobil}), @Conf::InputTel, 'accesskey="b"').$err{mobil})
			). row(
				th("<u>e</u>mail:").
				td(input("p$this->{id}email", uqq($this->{email}), @Conf::InputEmail, 'accesskey="e"'))
			). row(
				th("infomail:").
				td($infomailer->radio("p$this->{id}infomail", " ", $this->{infomail}))
			)
		)).
		td(tab(
			row(
				th("<u>o</u>tec:").
				td(input("p$this->{id}father", uqq($this->{father}), @Conf::InputName, 'accesskey="o"'))
			). row(
				th("matka:").
				td(input("p$this->{id}mother", uqq($this->{mother}), @Conf::InputName))
			). row(
				th("mobil:").
				td(input("p$this->{id}pmobil", uqq($this->{pmobil}), @Conf::InputTel).$err{pmobil})
			). row(
				th("email:").
				td(input("p$this->{id}pemail", uqq($this->{pemail}), @Conf::InputEmail))
			)
		))
	). row(td(tab(
		row(
			th("<u>p</u>ojišťovna:").
			td($insurancier->select("p$this->{id}insurance", $this->{insurance}, "neurčena", 'accesskey="p"'))
		). row(
			th("zdraví:").
			td(input("p$this->{id}health", uqq($this->{health}), $Conf::DescSize, $Conf::DescMax), 'colspan="2"')
		). row(
			th("zájmy:").
			td(input("p$this->{id}hobbies", uqq($this->{hobbies}), $Conf::DescSize, $Conf::DescMax), 'colspan="2"')
		). row(
			th("poznámka:").
			td(input("p$this->{id}note", uqq($this->{note}), $Conf::DescSize, $Conf::DescMax), 'colspan="2"')
		)), 'colspan="2"')
	), 'class="card"');

	$this->{id};
}


# show person info
# ~~~~~~~~~~~~~~~~
sub show {
	my $this = shift;

	# make sure we can view persons
        error("nemáš právo koukat na lidičky"), return unless $user->can("view_persons");

	# registered activities
	my @activities = activities Register $this->{id};
	my $activities = join '', map {(take Activity $_)->glimpse("{[][name][lead][placement]}")} @activities;
	$activities .= row(td().td("<b>
		<a href=\"$Conf::UrlActivities?aids=". (join '.', @activities) ."\">náhled</a> /
		<a href=\"$Conf::UrlActivities?action=prrrint&aids=". (join '.', @activities) ."\">tisk</a> /
		<a href=\"$Conf::UrlActivitiesIndex?open=0&pub=0&free=0&search=". (join ', ', map { "id:$_" } @activities) ."\">výběr</a></b> ".
		(@activities == 2 ? "obou" : "všech ". @activities) ." aktivit", 'colspan="7"'))
			if @activities > 1;

	# lead activities
	my @leads = activities Lead $this->{id};
	my $leads = join '', map {(take Activity $_)->glimpse("{[][name][placement]}")} @leads;
	$leads .= row(td().td("<b>
		<a href=\"$Conf::UrlActivities?aids=". (join '.', @leads) ."\">náhled</a> /
		<a href=\"$Conf::UrlActivities?action=prrrint&aids=". (join '.', @leads) ."\">tisk</a> /
		<a href=\"$Conf::UrlActivitiesIndex?open=0&pub=0&free=0&search=". (join ', ', map { "id:$_" } @leads) ."\">výběr</a></b> ".
		(@leads == 2 ? "obou" : "všech ". @leads) ." aktivit", 'colspan="7"'))
			if @leads > 1;

	# internal activities
	my @internal = activities Lead $this->{id}, "internal";
	my $internal = join '', map {(take Activity $_)->glimpse("{[][name][placement]}")} @internal;
	$internal .= row(td().td("<b>
		<a href=\"$Conf::UrlActivities?aids=". (join '.', @internal) ."\">náhled</a> /
		<a href=\"$Conf::UrlActivities?action=prrrint&aids=". (join '.', @internal) ."\">tisk</a> /
		<a href=\"$Conf::UrlActivitiesIndex?open=0&pub=0&free=0&search=". (join ', ', map { "id:$_" } @internal) ."\">výběr</a></b> ".
		(@internal == 2 ? "obou" : "všech ". @internal) ." aktivit", 'colspan="7"'))
			if @internal > 1;

	# look for children
	my $children = $this->glimpse("children");
	$children = row(th("děti:"). td($children)) if $children;

	print tab(
	row(
		td(div($this->glimpse("name"), 'class="heading"')).
		td(tab(
			row(td($this->glimpse("photo")))
		), 'rowspan="3"')
	). ($user->can("view_person_details")
		# including all details
		? row(td(tab(
			row(
				th("jméno:").
				td(uqq($this->{name}))
			). row(
				th("příjmení:").
				td(uqq($this->{surname}))
			). row(
				th("rodné číslo:").
				td(uqq($this->{birthnumber}))
			). row(
				th("datum narození:").
				td(uqq($this->{birthdate}->user_date))
			). row(
				th("věk:").
				td(uqq($this->age))
			). row(
				th("pohlaví:").
				td($sexer->name($this->{sex}))
			). row(
				th("animátor:").
				td($yesnoer->name($this->{animator}))
			)))
		). row(
			td(tab(
				row(
					th("ulice:").
					td($this->glimpse("street"))
				). row(
					th("město:").
					td($this->glimpse("town"))
				). row(
					th("psč:").
					td(uqq($this->{zip}))
				))
			)
		). row(
			td(tab(
				row(
					th("telefén:").
					td(uqq($this->{tel}))
				). row(
					th("mobil:").
					td($this->glimpse("mobil"))
				). row(
					th("email:").
					td($this->glimpse("email"))
				). row(
					th("infomail:").
					td($infomailer->name($this->{infomail}))
				)
			)).
			td(tab(
				row(
					th("rodiče:").
					td($this->glimpse("parents"))
				). row(
					th("mobil:").
					td($this->glimpse("pmobil"))
				). row(
					th("email:").
					td($this->glimpse("pemail"))
				)
			))
		). row(td(tab(
			row(
				th("pojištovna:").
				td($insurancier->name($this->{insurance}))
			). row(
				th("zdraví:").
				td(uqq($this->{health}), 'colspan="2"')
			). row(
				th("zájmy:").
				td(uqq($this->{hobbies}), 'colspan="2"')
			). $children. row(
				th("poznámka:").
				td(uqq($this->{note}), 'colspan="2"')
			)), 'colspan="2"')
		)
		# just basic contact data for informators
		: row(td(tab(
			row(
				th("telefén:").
				td(uqq($this->{tel}))
			). row(
				th("mobil:").
				td(uqq($this->{mobil}))
			). row(
				th("email:").
				td($this->glimpse("email"))
			)
		))). row(td(tab(
			row(
				th("otec:").
				td($this->glimpse("father"))
			). row(
				th("matka:").
				td($this->glimpse("mother"))
			). $children. row(
				th("mobil:").
				td(uqq($this->{pmobil}))
			). row(
				th("email:").
				td($this->glimpse("pemail"))
			)
		)))
	).($activities && row(td(tab(row(th("aktivity:").(tt("název").tt("vedoucí").tt("detaily"))) .$activities), 'colspan="2"'))
	). ($leads && row(td(tab(row(th("vede:").(tt("název").tt("detaily"))). $leads), 'colspan="2"'))
	). ($internal && row(td(tab(row(th("interní:").(tt("název").tt("detaily"))). $internal), 'colspan="2"')))
	, 'class="card"');
}


# registration formular
# ~~~~~~~~~~~~~~~~~~~~~~
sub register {
	my ($this, $reserve) = @_;

	# registration conflicts
	my ($problems, %err, %mess, $dataproblems, $note);

	# required data:
	$err{name} = err "opravdu, ale opravdu musíme znát celé jméno a příjmení", "jméno" unless $this->{name} && $this->{surname};
	$err{birth} = err "je nutné vědět, kdy se človíček narodil", "datum narození" unless $this->{birthdate}->db_date;
	$err{address} = err "musíme mít kompletní adresu", "adresa" unless $this->{town};

	# useful data
	$mess{phones}    = mess "mobil by se hodil", "mobil" unless $this->glimpse("onemobil");
	$mess{phones}    = mess "hodil by se alespoň nějaký telefén", "telefén" unless $this->glimpse("phones");
	$mess{emails}    = mess "mejlík by byl užitečný", "email" unless $this->glimpse("emails");
	$mess{insurance} = mess "bylo by dobré znát pojišťovnu", "pojišťovna" unless $this->{insurance};

	# highlight special keywords in person's note
	$note = uqq $this->{note};
	$note =~ s/(\b$_\b)/<span class=\"error\">\U\1\E<\/span>/ig for @Conf::NoteKeywords;

	$dataproblems = scalar keys %err;

	# explore person's family
	my $family;
	if ($this->age("yearsonly") < $Conf::FamilyAge) {
		# display parents
		$family = $this->glimpse("parents");
		$family = row(th("rodiče:"). td($family)) if $family;
	}
	else {
		# search for children
		$family = $this->glimpse("children");
		$family = row(th("děti:"). td($family)) if $family;
	}



	# register new activities
	unless ($dataproblems) {
		for my $activity (ids "register") {
			my ($registration, $problem) = create Register $this->{id}, $activity, $reserve;
			$problems .= row(
					td((take Activity $activity)->glimpse("name")).
					td($problem, 'colspan="7"')
					)
				if $problem;
		}
	}

	# registrations
	my $registrations;
	if ($user->can("edit_registrations") && !$dataproblems) {
		$registrations = join '', map {(take Register $_)->edit} person Register $this->{id};
		$registrations = row(tt("aktivita"). tt("kdy"). tt("zapsána k"). tt("zrušena k"). tt("zruš").
			tt("základ"). tt("cena"). tt("zaplatit"). tt("plať"). tt("pozn.")).
			$registrations#.
			#row(td.td.td.td.td.td.td.
				#td(checkbox("p$this->{id}printpayments")).tt("tiskni doklad"))
				if $registrations;

		# and print all pending payments
		prrrint_pending Payment $this->{id};# if ${"qp::p$this->{id}printpayments"};
	}
	else {
		$registrations = join '',
			map {(take Register $_)->glimpse("{[activity][start][finish][base][price][debt][details]}")}
				person Register $this->{id};
		$registrations = row(tt("aktivita"). tt("zapsána k"). tt("zrušena k").
				tt("základ"). tt("cena"). tt("zaplatit"). tt("pozn.")).
				$registrations if $registrations;
	}

	print tab(
	row(
		td(div($this->glimpse("name"), 'class="heading"').$err{name}).
		td(tab(
			row(td($this->glimpse("photo")))
		), 'rowspan="3"')
	). row(td(tab(
		row(
			th("narozen".($this->{sex} eq 'f' && 'a') .":").
			td($this->{birthdate}->user_date . ($this->{birthnumber} && " (r. č. $this->{birthnumber})") . $err{birth})
		). row(
			th("věk:").
			td(uqq($this->age))
		). row(
			th("zdraví:").
			td((join ', ', grep {$_} uqq($this->{health}), ($this->{insurance} && $this->glimpse("pojišťovna ins"))) . $mess{insurance})
		). row(
			th("zájmy:").
			td(uqq($this->{hobbies}))
		.$family)
	))). row(td(tab(
		 row(
			th("adresa:").
			td($this->glimpse("address") . $err{address})
		). row(
			th("telefén:").
			td($this->glimpse("phones") . $mess{phones})
		). row(
			th("email:").
			td($this->glimpse("emails") . $mess{emails})
		). row(
			th("pozn:").
			td($note)
		)
	))). row(td(tab(
		$registrations.$problems || row(td("není zaregistrován$this->{a} v žádné aktivitě"))
		), 'colspan="2"')
	)
	, 'class="card"');

	# return true if essential data missing
	$dataproblems;
}


# list payments
# ~~~~~~~~~~~~~~~~~~~~~~
sub payments {
	my $this = shift;

	my $ider = new Ider "p$this->{id}payment";

	# maybe print?
	if (my $action = ${"qp::p$this->{id}printpayments"}) {
		#if ($action =~ /nevystavené/) {
		#	prrrint_pending Payment $this->{id};
		#}
		#else {
			# print payment for this person, including zeroes
			prrrint Payment { person => $this->{id}, zeroes => 1 }, ids "p$this->{id}payment";
		#}
	}

	my $payments = join '',
		map {(take Payment $_)->glimpse("{[id][registration][activity][amount][collector][printed][#]}", { ider => $ider })}
		person Payment $this->{id};

	#my @pending = person Payment $this->{id}, "pending";
	#my $pending = submit "p$this->{id}printpayments", "tiskni nevystavené" if @pending;

	print tab(
		row(
			td(div($this->glimpse("name"), 'class="heading"'))
		). row(
			td(tab(
				$payments
				? row(tt("platba").tt("registr.").tt("aktivita"). tt("částka"). tt("vyřídil"). tt("provedena"). tt("vystavit doklad")).
				  $payments.
				  row(td.td.td.td.
					  td.td.#($pending).
					  td(submit("p$this->{id}printpayments", "tiskni")." vybrané platby")
				  )
				: row(td("v tomto období žádné platby"))
			))
		)
	, 'class="card"');
}


# list cards
# ~~~~~~~~~~~
sub cards {
	my $this = shift;

	# list of cards
	my $cards = join '', map {(take Card $_)->glimpse("{[id][created][printed]}")}
		person Card $this->{id};

	my $button;

	# no issuing cards unless person has payed for at least one activity
	if (card Activity $this->{id}, "yes, get only payed registrations please") {
		# maybe create a new card?
		create Card $this->{id}, "duplicate"
			if ${"qp::p$this->{id}cardduplicate"} && $user->can("add_cards");

		# find out if there is a pending card for this person
		my ($pending) = pending Card $this->{id};

		# maybe print a temporary one?
		prrrint Card [ $pending ], 'yes only a temporary one'
			if $pending && ${"qp::p$this->{id}cardprinttemporary"} && $user->can("prrrint_tmp_cards");

		# button for printing temporary card (if there is a pending one & user can)
		if ($pending && $user->can("prrrint_tmp_cards")) {
			$button = row(td(submit("p$this->{id}cardprinttemporary", "vytiskni dočasnou kartičku"), 'colspan="3"'));
		}
		# button for creating new card (if can & not already pending & and has some payed card activity)
		elsif ($user->can("add_cards")) {
			$button = row(td(submit("p$this->{id}cardduplicate", "vystav novou kartičku"), 'colspan="3"'));
		}
	}


	print tab(
		row(
			td(div($this->glimpse("name"), 'class="heading"'))
		). row(
			td(tab(
				($cards
					? row(tt("id").tt("žádost"). tt("vytisknuta")). $cards
					: row(td().td("v tomto období žádné karty"))
				).
				$button
			))
		)
	, 'class="card"');
}


# show schedule
# ~~~~~~~~~~~~~~
sub schedule {
	my $this = shift;

	print tab(
		row(td(div($this->glimpse("name"), 'class="heading"'))).
		row(td(
			schedule Place
				["schedule public",   map { activity Place $_ } (activities Register $this->{id}, undef, "unconfirmed too")],
				["schedule leading",  map { activity Place $_ } (activities Lead $this->{id})],
				["schedule internal", map { activity Place $_ } (activities Lead $this->{id}, "internal")]
		))
	, "class=\"card\"");

}


# start print page
# ~~~~~~~~~~~~~~~~~
sub prrrint_start {
	my $pack = shift;

	# set fields
	my @fields = qp 'fields';
	@fields = qw(name) unless @fields;

	# set activities & children fields
	my @activityfields = qp 'activityfields';
	my @leaderfields = qp 'leaderfields';
	my @childrenfields = qp 'childrenfields';
	my @parentsfields = qp 'parentsfields';

	print tab(row(td(tab(
			row(
				tt("človíček".br.$personier->multi('fields', undef, @fields)).
				tt("aktivity".br.$activitier->multi('activityfields', undef, @activityfields)).
				tt("vede".br.$activitier->multi('leaderfields', undef, @leaderfields)).
				tt("děti".br.$personier->multi('childrenfields', undef, @childrenfields)).
				tt("rodiče".br.$personier->multi('parentsfields', undef, @parentsfields))
			). row(
				td(label(checkbox("nohrefs", undef, $qp::nohrefs). " bez odkazů")).
				td(submit("", "zobraz"))
			)
		))), 'class="navig"'),

		tab(undef, 'class="scraps"');


	# print header row for all activities if we do not show activities or children
	print row(join '', map { th($personier->name($_)) } @fields) unless @activityfields || @leaderfields || @childrenfields || @parentsfields;

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
	my $this = shift;

	# set fields
	my @fields = qp 'fields';
	@fields = qw(name) unless @fields;

	my @activityfields = qp 'activityfields';
	my @leaderfields = qp 'leaderfields';
	my @childrenfields = qp 'childrenfields';
	my @parentsfields = qp 'parentsfields';

	# person's header row if details
	print row(join '', map { th($personier->name($_)) } @fields) if @activityfields || @leaderfields || @childrenfields || @parentsfields;

	# person's data (show as heading if displaying details)
	print row($this->glimpse((join '', map {"[$_]"} @fields), { nohrefs => $qp::nohrefs }),
			(@activityfields || @leaderfields || @childrenfields || @parentsfields) && 'class="head"');

	# maybe add person's activities
	if (@activityfields) {
		# activities header
		my $activities = row(join '', map { th($activitier->name($_)) } @activityfields);

		# individual activities
		for my $activity (activities Register $this->id) {
			$activities .= (take Activity $activity)->glimpse(
				"{". (join '', map {"[$_]"} @activityfields) ."}", { nohrefs => $qp::nohrefs }
			);
		}

		# print it
		print row(td(tab($activities), 'colspan="99"'));
		print row(undef, 'class="space"') unless @leaderfields || @childrenfields || @parentsfields;
	}

	# maybe add activities lead by person
	if (@leaderfields) {
		# activities header
		my $activities = row(join '', map { th($activitier->name($_)) } @leaderfields);

		# individual activities
		for my $activity (activities Lead $this->id) {
			$activities .= (take Activity $activity)->glimpse(
				"{". (join '', map {"[$_]"} @leaderfields) ."}", { nohrefs => $qp::nohrefs }
			);
		}

		# print it
		print row(td(tab($activities), 'colspan="99"'));
		print row(undef, 'class="space"') unless @childrenfields || @parentsfields;
	}

	# maybe add person's children
	if (@childrenfields) {
		# children header
		my $children = row(join '', map { th($personier->name($_)) } @childrenfields);

		# individual children
		for my $child ($this->children) {
			$children .= (take Person $child)->glimpse(
				"{". (join '', map {"[$_]"} @childrenfields) ."}", { nohrefs => $qp::nohrefs }
			);
		}

		# print it
		print row(td(tab($children), 'colspan="99"')).row(undef, 'class="space"');
		print row(undef, 'class="space"') unless @parentsfields;
	}

	# maybe add person's parents
	if (@parentsfields) {
		# parents header
		my $parents = row(join '', map { th($personier->name($_)) } @parentsfields);

		# individual parents
		for my $parent ($this->parents) {
			$parents .= (take Person $parent)->glimpse(
				"{". (join '', map {"[$_]"} @parentsfields) ."}", { nohrefs => $qp::nohrefs }
			);
		}

		# print it
		print row(td(tab($parents), 'colspan="99"')).row(undef, 'class="space"');
	}



}


# start message page
# ~~~~~~~~~~~~~~~~~~~
sub messages_start {
	my $pack = shift;

	my $mobiler = new Inquisitor (
			#nomobil   => 'neposílat',
			mobil     => 'na svůj mobil',
			pmobil    => 'na mobil rodičů',
			onemobil  => 'na svůj nebo rodičů',
			ponemobil => 'na rodičů nebo svůj',
			amobil    => "do $Conf::AdultAge rodičům, jinak sobě"
	);

	my $addresser = new Inquisitor (
			#noaddress   => 'neposílat',
			address     => 'na svůj email',
			paddress    => 'na email rodičů',
			oneaddress  => 'na svůj nebo rodičů',
			poneaddress => 'na rodičů nebo svůj',
			aaddress    => "do $Conf::AdultAge rodičům, jinak sobě"
	);

	my $ratherer = new Inquisitor (
			sms         => 'smsku',
			rathersms   => 'raději smsku, jinak email',
			ratherboth  => 'obojí',
			ratheremail => 'raději email, jinak smsku',
			email       => 'email'
	);

	my $messenger = new Inquisitor (
			sendmessages  => 'pošli',
			listmessages  => 'nic neposílej, pouze vygeneruj seznam, na který by se zprávy poslaly'
	);

	my $mobil = $qp::mobil || 'mobil';
	my $address = $qp::address || 'address';
	my $rather = $qp::rather || 'ratherboth';
	my $messageaction = $qp::messageaction || 'listmessages';

	print '
		<script type="text/javascript">
		<!--
		function infl(number) {
			if (number == 1) { return " písmenko"; }
			if (number >= 2 && number <= 4) { return " písmenka"; }
			return " písmenek";
		}

		function count() {
			var max = '. $Conf::MessageSmsMaxLength .';
			var sms = document.forms[0].smsmessage.value;

			if (sms.length > max) {
				sms = sms.substr(0,max);
			}

			var written = sms.length;
			var left = max - sms.length;

			document.getElementById("written").innerHTML = written + infl(written);
			document.getElementById("left").innerHTML =  left + infl(left);

			document.forms[0].smsmessage.value = sms;
		}

		document.write(count());
		-->
		</script>
	';

	# find out all possible From: addresses
	my $sender = take Person $user->person;
	my @sender = ( $Conf::MessageEmailFrom );
	my @fromms = ( 0 => uqq $Conf::MessageEmailFrom );

	if ($sender->glimpse("email")) {
		$sender[1] = $sender->glimpse("name <email>", { prrrint => 1 });
		push @fromms, 1 => uqq $sender[1];
	}

	if ($sender->glimpse("pemail")) {
		$sender[2] = $sender->glimpse("name <pemail>", { prrrint => 1 });
		push @fromms, 2 => uqq $sender[2];
	}

	my $frommer = new Inquisitor @fromms;

	print tab(
		row(
			($user->can('send_sms') && td(tab( # sms
				row(td('<div class="heading">sms</div>')).
				row(td($mobiler->radio('mobil', br, $mobil))).
				row(td('napsáno: <span id="written"></span>'. br. 'zbývá: <span id="left"></span>')).
				row(td('zpráva:'. br. area('smsmessage', uqq($qp::smsmessage), @Conf::InputSms, 'onKeyUp="count()" onfocus="count()" onclick="count()" onchange="count()" onmouseup="count()"')))
			))). ($user->can('send_email') && td(tab( # email
				row(td('<div class="heading">email</div>')).
				row(td($addresser->radio('address', br, $address))).
				row(
					td('odesílatel:'. br. $frommer->select("emailfrom", $qp::emailfrom)).
					td(br. label(checkbox('emailcopy', undef, $qp::emailcopy). " poslat sobě kopii"))).
				row(td('předmět: '. br. input('emailsubject', uqq($qp::emailsubject), @Conf::InputEmailSubject), 'colspan="2"')).
				row(td('zpráva:'. br. area('emailmessage', uqq($qp::emailmessage), @Conf::InputEmailMessage, 'wrap="hard"'), 'colspan="2"'))
			)))
		). ($user->can('send_sms') && $user->can('send_email') &&
		 	row(td(tab(row(
				td($ratherer->radio('rather', tdd.td, $rather))
			)), 'colspan="2"'))
		). (($user->can('send_sms') || $user->can('send_email')) &&
		 	row(td(tab(row(
				td($messenger->radio('messageaction', tdd.td, $messageaction))
			)), 'colspan="2"'))
		), 'class="card"').

		tab(undef, 'class="scraps"'),
			row(join '', map {th($_)} qw(jméno mobil rodičů email rodičů));

	my ($sms, $email);

	# set up the sms message
	if ($user->can('send_sms') && $qp::smsmessage) {
		$sms = sms Message $qp::smsmessage;
	}

	# set up the email message
	if ($user->can('send_email') && $qp::emailmessage) {
		$email = email Message $qp::emailsubject, $qp::emailmessage, $sender[$qp::emailfrom];

		# and maybe send a copy to ourselves
		$email->send($sender[$qp::emailfrom]) if $email && $qp::emailcopy;
	}

	return $messageaction, $sms, $email, $mobil, $address, $rather;
}


# finish message page
# ~~~~~~~~~~~~~~~~~~~~
sub messages_finish {
	my ($pack, $sent_sms, $sent_emails, $messageaction) = @_;

	print tabb;

	if ($messageaction eq "listmessages" && (@$sent_sms || @$sent_emails)) {
		print tab(undef, 'class="card"'), row;

		print td(
			div("čísla", 'class="heading"').
			join ', ', @$sent_sms
		) if @$sent_sms;

		print td(
			div("adresy", 'class="heading"').
			uqq join ', ', @$sent_emails
		) if @$sent_emails;

		print tabb;
	}

}


# person message row
# ~~~~~~~~~~~~~~~~~~~
sub messages {
	my ($this, $sent_sms, $sent_emails, $messageaction, $sms, $email, $mobil, $address, $rather) = @_;

	my ($smscontact, $emailcontact, $smserr, $emailerr, $smserr1, $smserr2, $emailerr1, $emailerr2);

	# decing according to age if adult-contacts chosen
	$mobil = $this->adult ? "onemobil" : "ponemobil" if $mobil eq "amobil";
	$address = $this->adult ? "oneaddress" : "poneaddress" if $address eq "aaddress";

	# find out the mobile number we should use
	if ($sms) {
		$smscontact = $this->{mobil} if $mobil eq 'mobil';
		$smscontact = $this->{pmobil} if $mobil eq 'pmobil';
		$smscontact = $this->{mobil} || $this->{pmobil} if $mobil eq 'onemobil';
		$smscontact = $this->{pmobil} || $this->{mobil} if $mobil eq 'ponemobil';
	}

	# find out the email address we should use
	if ($email) {
		$emailcontact = $this->{email} if $address eq 'address';
		$emailcontact = $this->{pemail} if $address eq 'paddress';
		$emailcontact = $this->{email} || $this->{pemail} if $address eq 'oneaddress';
		$emailcontact = $this->{pemail} || $this->{email} if $address eq 'poneaddress';
	}

	# navigate errors & messages to the right place
	$smserr = $smscontact eq $this->{mobil} ? \$smserr1 : \$smserr2;
	$emailerr = $emailcontact eq $this->{email} ? \$emailerr1 : \$emailerr2;

	# sending sms
	if ($smscontact && ($rather !~ /email/ || $rather eq 'ratheremail' && !$emailcontact)) {
		# if duplicate, just inform about it
		if (grep { /$smscontact/ } @$sent_sms ) {
			$$smserr = mess "duplicitní číslo bylo ignorováno", "dup";
		}
		# otherwise add to list and (maybe) send
		else {
			push @$sent_sms, $smscontact;
			if ($messageaction eq 'sendmessages') {
				$$smserr = $sms->send($smscontact) || info "v pořádku zasláno", "ok";
			}
			else {
				$$smserr = info "na toto číslo by byla zaslána sms zpráva", "by";
			}
		}
	}

	# sending email
	if ($emailcontact && ($rather !~ /sms/ || $rather eq 'rathersms' && !$smscontact)) {
		# if duplicate, just inform about it
		if (grep { /$emailcontact/ } @$sent_emails ) {
			$$emailerr = mess "duplicitní adresa byla ignorována", "dup";
		}
		# otherwise add to list and (maybe) send
		else {
			push @$sent_emails, $this->name. " <$emailcontact>";
			if ($messageaction eq 'sendmessages') {
				$$emailerr = $email->send($this->name. " <$emailcontact>") || info "v pořádku zasláno", "ok";
			}
			else {
				$$emailerr = info "na tuto adresu by byla zaslána emailová zpráva", "by";
			}
		}
	}

	print $this->glimpse("{[name][mobil$smserr1][pmobil$smserr2][email$emailerr1][pemail$emailerr2]}");
}


# maybe save changed data
# ~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update persons set
			name		= '%s',
			surname		= '%s',
			birthnumber	= '%s',
			sex		= '%s',
			street		= '%s',
			town		= '%s',
			zip		= '%s',
			email		= '%s',
			tel		= '%s',
			mobil		= '%s',
			mother		= '%s',
			father		= '%s',
			pmobil		= '%s',
			pemail		= '%s',
			health		= '%s',
			hobbies		= '%s',
			note		= '%s',
			animator	= '%s',
			infomail	= '%s',
			photo		=  %s,
			birthdate	=  %s,
			insurance	=  %s,
			updated		= now()
			where id = $this->{id}",
			(uq(@$this{qw(name surname birthnumber sex street town
				      zip email tel mobil mother father pmobil pemail
				      health hobbies note)}),
			 ($this->{animator} ? 't' : 'f'),
			 ($this->{infomail} ? 't' : 'f'),
			qd $this->{photo}, $this->{birthdate}->db_date, $this->{insurance})
		);
}


# glimpse at the user in one <table> row
# ~~~~~~~
# <<  format -- string containing list of columns to be showed
#     (i)d  (n)ame  (b)irthnumber
#     an `<' at the beginning means to include <tr>
#     an `>' at the end to include </tr>
# <<  ider -- ider to be used as name of checkbox
sub glimpse {
	my ($this, $format, $par) = @_;

	my $break = $par->{prrrint} ? '\break ' : br;
	my $dash = $par->{prrrint} ? '--' : '-';
	my %gl;

	%gl = (
		($par->{nohrefs} || $par->{prrrint}
			? (
				name		=> sub { $this->name },
				surname		=> sub { $this->{surname} },
				email		=> sub { $this->{email} },
				pemail		=> sub { $this->{pemail} && $this->{pemail}. (!$par->{prrrint} && "<span class=\"sup\" title=\"na rodiče\">r</span>") },
				mobil		=> sub { $this->{mobil} },
				pmobil		=> sub { $this->{pmobil} && $this->{pmobil}. (!$par->{prrrint} && "<span class=\"sup\" title=\"na rodiče\">r</span>") },
				street		=> sub { $this->{street} },
				town		=> sub { $this->{town} },
				address		=> sub { join ', ', grep {$_} $this->{street}, $this->{town}, $this->{zip} },
				mother		=> sub { $this->{mother} },
				father		=> sub { $this->{father} }
			)
			: (
				name		=> sub {
							 my ($name, $namee) = $this->{name} =~ /^(.*)(.)$/;
							 my ($surname, $surnamee) = $this->{surname} =~ /^(.*)(.)$/;

							 return uqq($this->name) unless $user->can("view_persons");

							"<nobr>".
								"<a href=\"$Conf::UrlPersons?pids=$this->{id}\" title=\"náhled\">$name</a>".
								"<a href=\"$Conf::UrlPersons?pids=$this->{id}&action=edit\" title=\"upravit\">$namee</a> ".
								"<a href=\"$Conf::UrlPersons?pids=$this->{id}&action=register\" title=\"registrace\">$surname</a>".
								"<a href=\"$Conf::UrlPersons?pids=$this->{id}&action=schedule\" title=\"rozvrh\">$surnamee</a>".
							  "</nobr>"
							},
				surname		=> sub { "<a href=\"$Conf::UrlPersons?pids=$this->{id}\">". uqq($this->{surname}) ."</a>" },
				email		=> sub { $this->{email} &&
								($user->can("send_email")
								? "<a href=\"$Conf::UrlPersons?action=messages&messageaction=sendmessages&address=address&rather=email&pids=$this->{id}\">$this->{email}</a>"
								: $this->{email})
							},
				pemail		=> sub { $this->{pemail} &&
								($user->can("send_email")
								 ? "<a href=\"$Conf::UrlPersons?action=messages&messageaction=sendmessages&address=paddress&rather=email&pids=$this->{id}\">$this->{pemail}</a>"
								 : $this->{pemail}). "<span class=\"sup\" title=\"na rodiče\">r</span>"
							},
				mobil		=> sub { $this->{mobil} &&
								($user->can("send_sms")
								? "<a href=\"$Conf::UrlPersons?action=messages&messageaction=sendmessages&mobil=mobil&rather=sms&pids=$this->{id}\">$this->{mobil}</a>"
								: $this->{mobil})
							},
				pmobil		=> sub { $this->{pmobil} &&
								($user->can("send_sms")
								? "<a href=\"$Conf::UrlPersons?action=messages&messageaction=sendmessages&mobil=pmobil&rather=sms&pids=$this->{id}\">$this->{pmobil}</a>"
								: $this->{pmobil}). "<span class=\"sup\" title=\"na rodiče\">r</span>"
							},
				street		=> sub { $this->{street} && "<a href=\"". $this->map ."\">$this->{street}</a>"; },
				town		=> sub { $this->{town} && "<a href=\"". $this->map ."\">$this->{town}</a>"; },
				address		=> sub { "<a href=\"". $this->map ."\">". (
								join ', ', grep {$_} $this->{street}, $this->{town}, $this->{zip}). "</a>"; },
				mother		=> sub {
								return unless $this->{mother};
								my $pid;
								return (take Person $pid)->glimpse("name") if $pid = $this->mother;
								$this->{mother}
							},
				father		=> sub {
								return unless $this->{father};
								my $pid;
								return (take Person $pid)->glimpse("name") if $pid = $this->father;
								$this->{father}
							}
			)
		),
		firstname	=> sub { $this->{name} },

		zip		=> sub { $this->{zip} },

		birthnumber	=> sub { $this->{birthnumber} },
		birthdate	=> sub { $this->{birthdate}->user_date(undef, { prrrint => $par->{prrrint}}) },
		birthdatelong	=> sub { $this->{birthdate}->user_date(undef, { prrrint => $par->{prrrint}, long => 1, year => 1}) },

		insurance	=> sub { $insurancier->name($this->{insurance}) },
		insnum		=> sub { $this->{insurance} },
		ins		=> sub { $shortinsurancier->name($this->{insurance}) },

		health		=> sub { $this->{health} },
		hobbies		=> sub { $this->{hobbies} },
		note		=> sub { $this->{note} },

		#photo		=> sub { br.$this->name. br. $this->photo("photo", !$par->{nohrefs}) }, # pexeso version
		photo		=> sub { $this->photo("photo", !$par->{nohrefs}) },
		miniphoto	=> sub { $this->photo("miniphoto", !$par->{nohrefs}) },
		miminiphoto	=> sub { $this->photo("miminiphoto", !$par->{nohrefs}) },

		age		=> sub { $this->age },
		years		=> sub { $this->age("yearsonly") },
		yearsold	=> sub { my $age = $this->age("yearsonly"); "$age ". infl($age, qw(rok roky roků)) },

		tel		=> sub { $this->{tel} },
		onemobil	=> sub { $this->adult ? &{$gl{mobil}} || &{$gl{pmobil}} : &{$gl{pmobil}} || &{$gl{mobil}} },
		onetel		=> sub { $this->{tel} || &{$gl{onemobil}} },
		phones		=> sub { join ', ', grep {$_} ($this->{tel}, &{$gl{mobil}}, &{$gl{pmobil}}) },

		oneemail	=> sub { $this->adult ? &{$gl{email}} || &{$gl{pemail}} : &{$gl{pemail}} || &{$gl{email}} },
		emails		=> sub { join ', ', grep {$_} (&{$gl{email}}, &{$gl{pemail}}) },
		infomail	=> sub { $infomailer->name($this->{infomail}) },

		parents		=> sub { join ', ', grep {$_} (&{$gl{father}}, &{$gl{mother}}) },

		activities	=> sub { join $break, map { (take Activity $_)->glimpse("name", $par) } activities Register $this->{id} },
		leads		=> sub { join $break, map { (take Activity $_)->glimpse("name", $par) } activities Lead $this->{id} },
		children	=> sub { join ', ', map {(take Person $_)->glimpse("name", $par)} $this->children; }
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# return query for browsing
#        ~~~~~~~~~~~~~~~~~~
# >>  query of all the users
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor (
			0 => "id",
			1 => "jména",
			2 => "narození"
	);

	# make work copy
	my $search = $qp::search;

	my ($direct, $directaction, $directactivity);
	# remove possible direct activity (for direct searching)
	$search =~ s/(\++)(.*)$/$1/;
	$directactivity = $2;

	# remove direct modifiers (and count them)
	if ($direct = $search =~ s/\s*([?!+\-*=\/:])(?![0-9])\s*//g) {
		# what king of redirection?
		$directaction = {
			"?" => "show",
			"!" => "edit",
			"+" => "register",
			"-" => "payments",
			"*" => "cards",
			"=" => "schedule",
			"/" => "prrrint",
			":" => "messages"
		}->{$1} if $direct;
	}
	# remove ',' and space from beginning and end
	$search =~  s/[,\s]*$//;
	$search =~ s/^[,\s]*//;

	# let's go!
	my $condition;
	for my $word ($search =~ /(\s*,\s*|\s+|[^\s,]+)/g) {
		# convert escaped space (as '_') back to normal
		$word =~ s/_/ /g;
		$word = uq $word;
		# and
		if ($word =~ /^\s+$/) {
			$condition .= " and ";
		}
		# or
		elsif ($word =~ /^(\s*,\s*)$/) {
			$condition .= " or ";
		}
		# search according to ids
		elsif ($word =~ /^id:(\d+)$/) {
			$condition .= "(p.id = $1)";
		}
		# 9 digits -- birthnumber or phone
		elsif ($word =~ /^\d{9}$/) {
			$condition .= "(p.birthnumber = '$word'";
			my @ar = $word =~ /(\d)/g;
			$word = "$ar[0]$ar[1]$ar[2] $ar[3]$ar[4]$ar[5] $ar[6]$ar[7]$ar[8]";
			$condition .= " or p.tel = '$word' or p.mobil = '$word' or p.pmobil = '$word')";
		}
		# birthdate
		elsif ($word =~ /^\d+\.\d+.\d+$/) {
			my $date = (user_date Time $word)->db_date;
			# bad date turn into false
			$condition .= $date ? "(p.birthdate = '$date')" : "'f'";
		}
		# 10 digits -- birthnumber
		elsif ($word =~ /^\d{10}$/) {
			$condition .= "(p.birthnumber = '$word')";
		}
		# 5 digits -- zip
		elsif ($word =~ /^\d{5}$/) {
			$word =~ s/^(...)/\1 /;
			$condition .= "(p.zip = '$word')";
		}
		# 4 digits -- birth year
		elsif ($word =~ /^\d{4}$/) {
			$condition .= "(extract (year from p.birthdate) = $word)";
		}
		# if direct -- search only names and notes
		elsif ($directaction) {
			$condition .= "( p.name ~* '^$word'
				or p.surname ~* '^$word'
				or p.note ~* '$word'
			)";
		}
		# otherwise everything
		else {
			$condition .= "( p.name ~* '^$word'
				or p.surname ~* '^$word'
				or p.street ~* '$word'
				or p.town ~* '$word'
				or p.email ~* '$word'
				or p.pemail ~* '$word'
				or p.mother ~* '$word'
				or p.father ~* '$word'
				or p.health ~* '$word'
				or p.hobbies ~* '$word'
				or p.note ~* '$word'
			)";
		}
	}
	# and last adjustment
	$condition = " and ($condition)" if $condition;

	# animators only
	$condition .= " and animator" if $qp::animatorsonly;

	# infomailers only
	$condition .= " and infomail" if $qp::infomailersonly;

	# sex filter
	my $sex = $qp::sex || $par->{sex};
	$condition .= " and (sex = '$sex')" if $sex;

	# age filter
	my $youngest = ck $qp::youngest;
	my $oldest = ck $qp::oldest;
	$condition .= " and (extract(years from age(birthdate)) >= $youngest)"
		if defined $youngest;
	$condition .= " and (extract(years from age(birthdate)) <= $oldest)"
		if defined $oldest;

	# active members filter
	my $leftouter = $qp::activeonly ? "" : "left outer";

	#logg $condition;
	my $sort = defined $qp::sort ? $qp::sort : 1;
	#######################################################
	my $cleaver = query Cleaver "
		select distinct(p.id), p.name, p.surname, p.birthdate
			from persons p
		$leftouter join registrations_really_active r
			on p.id = r.person and r.pub and season = ". $user->season ."
		where 't' $condition
		order by ".  ("p.id", "p.surname, p.name", "p.birthdate")[$sort],
		$direct > 2 && $Conf::SliceSizesGreat;

	# if there is exactly one result for direct action or direct > 1 (we accept more results)
	# make the direct action!
	if (!$cleaver->empty && ($direct > 1 || $direct == 1 && $cleaver->total == 1 )) {
		my @pids;
		while (my ($pid) = $cleaver->next) {
			push @pids, $pid;
		}
		header undef, { redir => "$Conf::UrlPersons?action=$directaction".
			"&search=$directactivity&pids=". join '.', @pids };
		return;
	}

	header $par->{header}, { javascript => "yes" } if $par->{header};
	form $par->{navigform}, "navig" if $par->{navigform};

	print tab(
		row(td(
			tab(
				row(
					th("pohlaví:").
					td($sexer2->select("sex", $sex), 'colspan="4"')
				). row(
					th("věk od:").
					td(input("youngest", $youngest, @Conf::InputAge)).
					th("do:").
					td(input("oldest", $oldest, @Conf::InputAge))
				)
			)
		). td(
			tab(row(td(
					label(checkbox("animatorsonly", undef, $qp::animatorsonly). " pouze animátory").br.
					label(checkbox("activeonly", undef, $qp::activeonly).
					" <span title=\"tzn. členy zaregistrované v tomto období alespoň v jedné veřejné aktivitě\">jen aktivní členy</span></label>").br.
					label(checkbox("infomailersonly", undef, $qp::infomailersonly).
					" <span title=\"pouze ty, kteří si přejí zasílat informační emaily\">pouze zájemce o infomail</span></label>")
			)))
		)). row(td(tab(row(
			th("setřídit:").
			td($sorter->select("sort", uqq $sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(input("search", uqq $qp::search)).
			td(submit "", "najít")
		)), 'colspan="2"')). row(td(tab(row(
			td("nalezené osoby (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		)), 'colspan="2"'))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná osoba<p>"), return if $cleaver->empty;

	my $prefix = $par->{prefix} || "p";
	my $ider = new Ider ($prefix);

	#######################################################
	# start table
	print tab(undef, 'class="scraps"'),
		row th(""). th("jméno"). th("věk").
			($user->can("view_person_details") && th("narození")).
			th("telefén"). th("mobil"). th("adresa");

	# glimpses
	while (my ($pid) = $cleaver->next) {
		my $p = take Person $pid;
		print $p->glimpse("{[#][name][years]".
			($user->can("view_person_details") && "[birthdate]").
			"[tel][onemobil][address]}", { ider => $ider });
	}

	# finish table
	print row(td(checkall("p.*p.*p"), 'colspan="7" class="footer"')), tabb;

	# we have found something
	1
}



# short person stats
sub stats {
	$dbi->exe("select count(distinct(person))
			from registrations_really_active
			where pub and season = ". $user->season);
	my $active = $dbi->val;

	return "$active ". infl($active, "registrovaný člen", "registrovaní členové", "registrovaných členů");
}


1

package Register;

  #######################################################
 ####  Register -- registering activities  ############
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new registration
#  > take		constructor (takes rid)
#  > cancel		cancel registration
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > person
#  > activity
#  > price
#  > start
#  > finish
#
#  > days		for how many days is the registration valid
#  > alldays		days count for the whole activity
#  > pay		how much should be payed (real price)
#  > payed		how much has been already payed
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#  > price		total price to be payed for this registration
#  > debt		amount to be still payed
#
#  > glimpse		one <tr> info 'bout the user
#
#  > edit		make formular for editing
#
#  > person
#  > activity
#
#  > activities
#  > members
#  > sweep		delete old registrations

use strict qw(subs vars);

use Aid;
use Card;
use Time;
use Setup;
use Person;
use Payment;
use Activity;
use Inquisitor;



#  create new registration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# << person, activity, start date
sub create {
	my ($pack, $pid, $aid, $reservation) = @_;
	fatal "je třeba zadat osobu a aktivitu" unless defined $aid && defined $pid;

	my $activity = take Activity $aid;
	my $person = take Person $pid;
	my $start;

	# guess start date unless we got it
	#unless (defined $start) {

		# just find out start date
		if ($now->compare($activity->start) == 1
				&& $now->compare($activity->finish) == -1
				&& !$reservation) {
			# if the activity is active (and we're not reservating) then register from now
			$start = $now;
		}
		else {
			# otherwise register from the activity start
			$start = $activity->start;
		}
	#}
	# check start date otherwise
	#else {
	#	$start = $activity->start
	#		if $start->compare($activity->start) == -1 ||
	#		   $start->compare($activity->finish) == 1;
	#}


	# guess price (suggest 0,- for active animators)
	my $price = $person->leads($activity->season) && $activity->type != $Conf::ActivityTypeOneTime
		? 0
		: $activity->price;

	my $id;

	# insert into db
	$dbi->beg;
		$dbi->exe("lock table registrations in exclusive mode");
		# is there any free place in the activity?
		unless ($dbi->exe("select free from activities_free where id = $aid and (free > 0 or free is null)")) {
			$dbi->end;
			return undef, err "aktivita je již bohužel plně obsazena", "obsazena";
		}
		# hasn't the person already registered this activity?
		if ($dbi->exe("select activity from registrations_active
					where person = $pid and activity = $aid")) {
			$dbi->end;
			return undef, "tuto aktivitu už má ". $person->firstname ." zapsánu". err "už zapsána";
		}

		# decide whether to use fake registration time for reservation or a real one
		my $created;
		$created = (take Setup)->fake_time->db_stamp if $reservation;
		$created = (current Time)->db_stamp unless $created;

		# insert it
		$dbi->exe("insert into registrations (person, activity, price, start, registrar, created) values
				($pid, $aid, ". qd($price) .", '". $start->db_date ."', ". $user->person .", '$created')");
		$dbi->exe("select currval('registrations_id_seq')");
		$id = $dbi->val;
	$dbi->end;
	# if the activity is card activity -- create card request
	create Card $pid if $activity->card;

	# return created registration and "no problem"
	((take Register $id), "");
}



# constructor for existing registrations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  rid
sub take {
	my ($pack, $rid) = @_;
	return undef unless $rid;

	my $this = {};

	$dbi->exe("select id, person, activity, price, start, finish, registrar, canceller, created, cancelled,
			days, alldays, pay, payed
			from registrations_complete where id = $rid")
		or fatal("takový zápis neexistuje ($rid)");
	@$this{qw(id person activity price start finish registrar canceller created cancelled days alldays pay payed)} = $dbi->row;

	$this->{start} = db_date Time $this->{start};
	$this->{finish} = db_date Time $this->{finish};
	$this->{created} = db_stamp Time $this->{created};
	$this->{cancelled} = db_stamp Time $this->{cancelled};

	bless $this;
}




# delete the registration
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat registrace"), return unless $user->can("edit_registrations");
	my $success = $dbi->exe("delete from registrations where id = $this->{id}", "try");

	# if successfully deleted, clear possible card requests
	clean Card $this->{person} if $success;

	$success;
}


# save changed data
# ~~~~~~~~~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update registrations set
			price		=  %s,
			start		=  %s,
			finish		=  %s,
			canceller	=  %s,
			cancelled	=  %s
			where id = $this->{id}",
			qd($this->{price}, $this->{start}->db_date, $this->{finish}->db_date, $this->{canceller}, $this->{cancelled}->db_stamp)
		);
}


# return registration id
# ~~~~~~~~~~~~~~~~~~~~~~~
sub id {
	my $this = shift;

	$this->{id};
}



# total price to be payed for this registration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub price {
	my $this = shift;

	$this->{pay};
}


# amount to be still payed
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub debt {
	my $this = shift;

	$this->{pay} - $this->{payed};
	#price - total Payment $this->{id};
}


# after how long time this registration will be deleted?
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub willdie {
	my $this = shift;

	return "" if defined $this->{payed};

	$dbi->exe("select cast ('". $this->{created}->db_stamp ."' as timestamp)
			+ cast (confirm_time || ' days' as interval) - '". $now->db_date ."' from setup");

	my $time = ymd $dbi->val;
	return '<span title="registrace bude zrušena dnes v noci">dnes</span>' unless $time;
	"<span title=\"registrace bude zrušena za $time\">$time</span>";
}


# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit registration
        error("nemáš právo upravovat registrace"), return
		unless $user->can("edit_registrations");
	my %err;

	my $activity = take Activity $this->{activity};

	# if update then make some checks
	if (defined ${"qp::register$this->{id}start"}) {
		# get values
		$this->{price} = ck ${"qp::register$this->{id}price"};
		$this->{start} = user_date Time ${"qp::register$this->{id}start"};
		$this->{finishold} = $this->{finish};
		$this->{finish} = user_date Time ${"qp::register$this->{id}finish"};

		# set start to regular activity start if not specified
		if (${"qp::register$this->{id}start"} =~ /^\s*$/) {
			$err{start} = err "neplatné datum, nastavuji na začátek aktivity";
			$this->{start} = $activity->start;
		}

		# if ticked `cancel' -- try to delete the registration completely
		if (${"qp::register$this->{id}cancel"}) {
			if ($this->delete) { # no payment -- deleted completely
				return undef;
			}
			else { # mark as unregistered today (or first day of the activity)
				$this->{finish} = $now->compare($activity->start) == -1
					? $activity->start
					: $now;
			}
		}

		# check dates
		$err{start} = err "nesprávné datum" unless $this->{start}->user_date;
		$err{finish} = err "nesprávné datum" if !$this->{finish}->user_date && ${"qp::register$this->{id}finish"} ne "";
		# correct overlaps
		if ($this->{start}->compare($activity->start) == -1 ||
				$this->{start}->compare($activity->finish) == 1) {
			$this->{start} = $activity->start;
			$err{start} = err "datum přesahovalo -- nastavuji na začátek aktivity";
		}
		if ($this->{finish}->compare($activity->finish) == 1 ||
				$this->{finish}->compare($activity->start) == -1 ||
				$this->{finish}->compare($this->{start}) == -1) {
			$this->{finish} = $activity->finish;
			$err{finish} = err "datum přesahovalo -- nastavuji na konec aktivity";
		}

		#todo:  compare dates... with activity season...

		# set standard price if problems...
		unless (defined $this->{price}) {
			$err{price} = err "neplatná cena, nastavuji výchozí";
			$this->{price} = $activity->price;
		}

		# maybe perform a payment
		if (${"qp::register$this->{id}pay"}) {
			my $amount = ck ${"qp::register$this->{id}amount"};
			unless (defined $amount) {
				$err{amount} = err "neplatná částka";
			}
			# but don't pay zeros
			#elsif ($amount) {
			# pay zeros too -- for blocking registration deletions (and printing info)
			else {
				create Payment $this->{id}, $amount;
			}
		}

		# reviving cancelled registration -- have to check for free place before saving
		if ($this->{finishold}->db_date && !$this->{finish}->db_date) {
			$dbi->beg;
				$dbi->exe("lock table registrations in exclusive mode");
				unless ($dbi->exe("select free from activities_free
						where id = $this->{activity} and (free > 0 or free is null)")) {
					$this->{finish} = $this->{finishold};
					$err{finish} .= err "registraci nelze obnovit -- aktivita je obsazena";
				}
				# hasn't the person another active registration for this activity?
				if ($dbi->exe("select activity from registrations_active
							where person = $this->{person} and activity = $this->{activity}")) {
					$this->{finish} = $this->{finishold};
					$err{finish} .= err "tuto registraci nelze obnovit -- aktivita už má jinou aktivní registraci";
				}
				# unset canceller & cancel time if revival was succesfull
				if (!$err{finish}) {
					$this->{canceller} = undef;
					$this->{cancelled} = db_stamp Time "xxx";
				}

				# and finally save!
				$this->save;
			$dbi->end;
			# revive Card request (unless errors & activity is card activity)
			create Card $this->{person} if !$err{finish} && $activity->card;
		}
		# otherwise -- just save -- no problems to be afraid of
		else {
			# if registration was cancelled, set the canceller & cancelled time
			if ($this->{finish}->db_date && !$this->{finishold}->db_date) {
				$this->{canceller} = $user->person;
				$this->{cancelled} = current Time;
			}

			# save in any case
			$this->save;

			# and if cancelled, clean possible card requests (if this was last card activity)
			clean Card $this->{person}
				if $this->{finish}->db_date && !$this->{finishold}->db_date;
		}

		# update to current data (days, pay, payed)
		$this = take Register $this->{id};
	};

	# check problem with age & sex
	$err{problems} = $activity->check($this->{person});

	# check schedule colisions
	#my $conflicts = join ', ', map {(take Activity $_)->glimpse("name")} $this->conflicts;
	#$err{conflicts} = err("tato registrace koliduje s následujícími již zapsanými aktivitami",
	#		"konflikty"). " $conflicts" if $conflicts;
	#$err{conflicts} = err("tato registrace koliduje s jinou již zapsanou aktivitou", "konflikt")
	#	if $this->conflicts;
	my $conflicts = join ', ', map {(take Activity $_)->glimpse("name", { nohrefs => 1 })} $this->conflicts;
	$err{conflicts} = err("registrace koliduje s již zapsanými aktivitami ($conflicts)",
			"konflikt") if $this->conflicts;

	# return the edit row
	row(
		td(
			$activity->glimpse("name")
		). td(
			$activity->glimpse("placementshortest")
		). td(
			input("register$this->{id}start",
				$this->{start}->user_date || uqq(${"qp::register$this->{id}start"}),
				@Conf::InputDateShort, ($this->{registrar} && 'title="registroval: '. (take Person $this->{registrar})->name.
				", ". $this->{created}->user_date_long("year", "time").'"')
			).$err{start}
		). td(
			input("register$this->{id}finish",
				$this->{finish}->user_date || uqq(${"qp::register$this->{id}finish"}),
				@Conf::InputDateShort, ($this->{canceller} && 'title="zrušil: '. (take Person $this->{canceller})->name.
				", ". $this->{cancelled}->user_date_long("year", "time").'"')
			).$err{finish}
		). td(
			$this->{finish}->user_date ?  "" : checkbox("register$this->{id}cancel",
				undef, undef, 'title="zrušit aktivitu"')
		). td(
			input("register$this->{id}price", $this->{price}, @Conf::InputPrice). $err{price}
		). td(
			$activity->price($this->{days}, $this->{alldays}, $this->{price}, $this->{pay}) .",-"
		). td(
			input("register$this->{id}amount", $this->debt, @Conf::InputPrice). $err{amount}
		). td(
			checkbox("register$this->{id}pay", undef, undef, "platit nalevo uvedenou částku")
		). td(
			join ' ', grep {$_} ($err{problems}, $err{conflicts}, $this->willdie)
		)
	)
}


# return registrations conflicting with this one
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub conflicts {
	my ($this) = @_;

	$dbi->exe("select other.activity from
				placed_view other,
				placed_view this,
				registrations_active this_registration,
				registrations_active other_registration
			where
				-- join
				this_registration.id = $this->{id} and
				other_registration.person = $this->{person} and
				other_registration.id != $this->{id} and
				this.activity = this_registration.activity and
				other.activity = other_registration.activity and

				-- no colision with other-type activities
				this.type != $Conf::ActivityTypeOther and
				other.type != $Conf::ActivityTypeOther and

				-- activity types have to be the same (regular x onetime make many pointless conflicts)
				this.type = other.type and

				-- times have to  crosss
				coalesce(this.start, '00:00:00') < coalesce(other.finish, '23:59:59') and
				coalesce(this.finish, '23:59:59') > coalesce(other.start, '00:00:00') and

				-- dates have to cross
				this.date_start <= other.date_finish and
				this.date_finish >= other.date_start and

				(
				-- days of week have to be the same or null and (longer than week or hit the same day of week)
					this.day = other.day or (
					 	other.day is null and (
							other.date_finish - other.date_start >= 7
							or
							this.day + (case when this.day < extract(dow from other.date_start) then 7 else 0 end)
							<=
							extract(dow from other.date_finish) +
								(case when extract(dow from other.date_finish) < extract(dow from other.date_start) then 7 else 0 end)
						)
					) or (
						this.day is null and (
							this.date_finish - this.date_start >= 7
							or
							other.day + (case when other.day < extract(dow from this.date_start) then 7 else 0 end)
							<=
							extract(dow from this.date_finish) +
								(case when extract(dow from this.date_finish) < extract(dow from this.date_start) then 7 else 0 end)
						)
					)
				)
	");

##! kvuli volne oratori, ktera je cely tyden a pak s ni vsecko konfliktuje...
#				-- day have to be the same
#				this.day = other.day

	$dbi->vals;
}




# glimpse at the registration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub glimpse {
	my ($this, $format, $par) = @_;

	# to fetch activity only once
	my $activity;

	my %gl = (
		activity	=> sub { ($activity || ($activity = take Activity $this->{activity}))->glimpse("name", $par) },
		person		=> sub { (take Person $this->{person})->glimpse("name") },
		registrar	=> sub { (take Person $this->{registrar})->glimpse("name") },
		canceller	=> sub { (take Person $this->{canceller})->glimpse("name") },
		created 	=> sub { $this->{created}->user_date_long("years", "time") },
		start		=> sub { $this->{start}->user_date },
		finish		=> sub { $this->{finish}->user_date },
		base		=> sub { $this->{price} .",-" },
		price		=> sub { $this->{pay} .",-" },
		debt		=> sub { $this->debt .",-" },
		willdie		=> sub { $this->willdie },
		details		=> sub { join ' ', grep {$_}
						($activity || ($activity = take Activity $this->{activity}))->check($this->{person}),
						#($this->conflicts && err("tato registrace koliduje s jinou již zapsanou aktivitou", "konflikt")),
						$this->willdie;
					}
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# get activity's registrations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub activity {
	my ($this, $activity) = @_;

	# if called as object function -- return activity id
	return $this->{activity} unless $this eq 'Register';

	$dbi->exe("select id from registrations_view
			where activity = $activity
			  order by person_surname, person_name");
	$dbi->vals;
}


# get person's registrations (or just person id)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub person {
	my ($this, $person) = @_;

	# if called as object function -- return person id
	return $this->{person} unless $this eq 'Register';

	$dbi->exe("select id from registrations_view
			where person = $person
			  and season = ". $user->season ."
			  order by activity_name");
	$dbi->vals;
}


# get current activity members
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub members {
	my ($pack, $activity) = @_;

	$dbi->exe("select person from registrations_really_active
			where activity = $activity
			  order by person_surname, person_name");
			  #and payed is not null
			  #and finish is null
	$dbi->vals;
}


# get current activities of a person
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub activities {
	my ($pack, $person, $public, $unconfirmed) = @_;

	my $condition;
	$condition = "" if $public eq "all" || !defined $public;
	$condition = " and pub" if $public eq "public";
	$condition = " and not pub" if $public eq "internal";
	$condition .= " and payed is not null" unless $unconfirmed;

	$dbi->exe("select activity from registrations_really_active_including_unconfirmed
			where person = $person
			  and season = ". $user->season ."
			  $condition
			  order by activity_name, season");
			  #and payed is not null
			  #and finish is null
	$dbi->vals;
}


# delete old nonconfirmed registrations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub sweep {
	#my ($pack, $silently) = @_;

	$dbi->beg;
		$dbi->exe("lock table registrations in share mode");
		$dbi->exe("
			select id from registrations, setup
				where age('". (current Time)->db_date ."', cast (created as date)) >
					cast (confirm_time || ' days' as interval)
			except select registration from payments");
		my @rids = $dbi->vals;
		for my $rid (@rids) {
			#$dbi->exe("delete from registrations where id = $rid");
			# delete including possible card requests
			(take Register $rid)->delete;
			#print "mažu registraci $rid". br;
		}
	$dbi->end;
	@rids;
}


# browsing registrations
# ~~~~~~~~~~~~~~~~~~~~~~~
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor ( 0 => "id", 1 => "človíčka", 2 => "aktivity", 3 => "času", 4 => "dluhu");
	my $payer = new Inquisitor 0 => 'všechny', 1 => 'vyrovnané', 2 => 'nevyrovnané';
	my $confirmer = new Inquisitor 0 => 'všechny', 1 => 'potvrzené', 2 => 'nepotvrzené';

	my $sort = ck $qp::sort;
	$sort = 0 unless defined $sort;

	my $since = user_stamp Time $qp::since;
	my $until = user_stamp Time $qp::until;

	my $payed = (ck $qp::payed) || 0;
	my $confirmed = (ck $qp::confirmed) || 0;

	my $search = $qp::search;

	my $condition;
	# remove ',' and space from beginning and end
	$search =~  s/[,\s]*$//;
	$search =~ s/^[,\s]*//;

	# let's go!
	for my $word ($search =~ /(\s*,\s*|\s+|[^\s,]+)/g) {
		# convert escaped space (as '_') back to normal
		$word =~ s/_/ /g;
		$word = uq $word;
		# space means 'and'
		if ($word =~ /^\s+$/) {
			$condition .= " and ";
		}
		# comma means 'or'
		elsif ($word =~ /^(\s*,\s*)$/) {
			$condition .= " or ";
		}
		# negating search
		elsif ($word =~ /^-(.*)$/) {
			$condition .= "not(activity_name ~* '$1' or activity_note ~* '$1' or person_name ~* '$1' or person_surname ~* '$1')";
		}
		# negating search
		elsif ($word =~ /^(\d+)$/) {
			$condition .= "(id = $1)";
		}
		# simple search pattern
		else {
			$condition .= "(activity_name ~* '$word' or activity_note ~* '$word' or person_name ~* '$word' or person_surname ~* '$word')";
		}
	}
	# and last adjustment
	$condition = " and ($condition)" if $condition;

	$condition .= " and r.created >= '". $since->db_stamp ."'" if $since->db_stamp;
	$condition .= " and r.created <= '". $until->db_stamp ."'" if $until->db_stamp;

	$condition .= " and (payed = pay or pay = 0)" if $payed == 1;
	$condition .= " and (payed != pay or (payed is null and pay != 0))" if $payed == 2;
	$condition .= " and payed is not null" if $confirmed == 1;
	$condition .= " and payed is null" if $confirmed == 2;

	my $cleaver = query Cleaver "select id, person_surname, person_name, activity_name from
			registrations_complete r
			where season = ". $user->season ." $condition
		order by ". (("id desc", "person_surname, person_name", "activity_name, person_surname, person_name", "created desc", "pay - payed desc")[$sort]);

	header $par->{header}, { javascript => "yes" } if $par->{header};
	form $par->{navigform}, "navig" if $par->{navigform};

	print tab(
		row(td(tab(
			row(
				th(
					"o<u>d</u>: ".input("since", $since->user_stamp, @Conf::InputStamp, 'accesskey="d"').br.br.
					"do: ".input("until", $until->user_stamp, @Conf::InputStamp)
				). td($payer->radio("payed", "<br/>", $payed), 'rowspan="2"').
				td($confirmer->radio("confirmed", "<br/>", $confirmed), 'rowspan="2"')
			). row(
				th()
			)
		))). row(td(tab(row(
			th("setřídit dle:").
			td($sorter->select("sort", $sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(input('search', uqq $search)).
			td(submit "", "najít")
		)))). row(td(tab(row(
			td("nalezené registrace (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		))))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná registrace<p>"), return if $cleaver->empty;

	my $ider = new Ider "p";

	# start table
	print tab(undef, $Conf::TabScraps),
		row th("id"). th("človíček"). th("aktivita"). th("registroval"). th("datum"). th("dluh"). th("detaily");

	# glimpses
	while (my ($rid) = $cleaver->next) {
		my $r = take Register $rid;
		my $checkbox = (take Person $r->person)->glimpse("#", { ider => $ider });
		print $r->glimpse("{[id][$checkbox person][activity][registrar][created][debt][details]}");
	}

	# finish table
	print row(td(checkall("p.*p.*p"), 'colspan="7" class="footer"')), tabb;
	print tabb;

	# choose all link
	#print "<a href=\"$Conf::UrlPersonsIndex?search=". (join ', ', map { "id:$_" } @pids) ."\">výběr všech</a> výše uvedených človíčků";

	# we have found something
	1
}


1

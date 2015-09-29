package Room;

  #######################################################
 ####  Room -- handling rooms  #########################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new room
#  > take		constructor (takes rid)
#  > delete		delete a user
#  > browse		browsing the users
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > name		.
#  > description	.
#  > capacity		.
#  > manager		.
#
#  > updated		shall we save at destroy?
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#  > name		get the name
#
#  > glimpse		one <tr> info 'bout the room
#
#  > edit		make formular for editing
#  > show		show room info
#
#  > DESTROY		destructor -- save data if updated

use locale;
use strict qw(subs vars);

use Aid;
use Place;
use Person;
use Cleaver;
use Inquisitor;

my $dayer = longday Inquisitor;

# create new room (empty)
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
	my $this = {};
	bless $this;

	# insert into db
	$dbi->beg;
		$dbi->exe("insert into rooms (name) values (null)");
		$dbi->exe("select currval('rooms_id_seq')");
		$this->{id} = $dbi->val;
	$dbi->end;

	# the rest is empty
	$this->{updated} = 0;

	$this;
}



# constructor for existing rooms
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  rid
sub take {
	my ($pack, $rid) = @_;
	return undef unless $rid;
	#fatal("take potřebuje číslo místnosti") unless $rid;

	my $this = {};

	$dbi->exe("select id, name, description, capacity, manager from rooms where id = '". uq($rid) ."'")
		or fatal("taková místnost neexistuje");
	@$this{qw(id name description capacity manager)} = $dbi->row;

	#[$this->{updated} = 0;

	bless $this;
}




# deleting a room
# ~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat místnosti"), return undef unless $user->admin;

	if ($dbi->exe("delete from rooms where id = $this->{id}", "try")) {
		message("místnost $this->{login} byla úspěšně smazána");
		return "ok";
	}
	else {
		error ("místnost ($this->{name}) už nelze smazat");
		return undef;
	}

	$this->{updated} = 0;
}


sub id {
	my $this = shift;

	$this->{id};
}


sub name {
	my $this = shift;

	$this->{name}
}


sub capacity {
	my $this = shift;

	$this->{capacity};
}


# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit this room
        error("nemáš právo upravovat místnosti"), $this->show, return unless $user->can("edit_rooms");

	my %err;
	my $managerer = animator Inquisitor;

	if (defined ${"qp::r$this->{id}name"}) {
		for my $val (qw(name description capacity manager)) {
			$this->{$val} = ${"qp::r$this->{id}$val"};
			if ($val eq 'capacity' and not defined ($this->{capacity} = ck $this->{capacity})) {
				$err{capacity} = err "neplatná kapacita místnosti";
			}
			$this->{updated} = 1;
		}
		$this->{manager} = undef unless $this->{manager};
	}

	print tab(row(td(div($this->glimpse("name") || 'Nová místnost', 'class="heading"'))).row(td(
		tab(
		row(
			th("<u>n</u>ázev:").
			td(input("r$this->{id}name", uqq($this->{name}), @Conf::InputName, 'accesskey="n"'))
		).
		row(
			th("popis:").
			td(input("r$this->{id}description", uqq($this->{description}), $Conf::DescSize, $Conf::DescMax))
		).
		row(
			th("kapacita:").
			td(input("r$this->{id}capacity", uqq(defined $this->{capacity} ?
				$this->{capacity} : ${"qp::r$this->{id}capacity"}), 7, 3).$err{capacity})
		).
		row(
			th("zodpovídá:").
			td($managerer->select("r$this->{id}manager", $this->{manager}, " "))
		)
	, 'class="place"'))), 'class="card"');
}


# show room info
# ~~~~~~~~~~~~~~
sub show {
	my $this = shift;

	#my $placement = join '', map {row().td('').(take Place $_)->glimpse("[d][s-f][a][(t-h)]>")} room Place $this->{id};
	my $placement = join '', map {(take Place $_)->glimpse("{[][day][start-finish][activity][leaders]}")} room Place $this->{id};

	my @activities = activities Place $this->{id};
	$placement .= row(td().td("<b>
		<a href=\"$Conf::UrlActivities?aids=". (join '.', @activities) ."\">náhled</a> /
		<a href=\"$Conf::UrlActivities?action=prrrint&aids=". (join '.', @activities) ."\">tisk</a> /
		<a href=\"$Conf::UrlActivitiesIndex?open=0&pub=0&free=0&search=". (join ', ', map { "id:$_" } @activities) ."\">výběr</a></b> ".
		(@activities == 2 ? "obou" : "všech ". @activities) ." aktivit", 'colspan="7"'))
			if @activities > 1;

	print tab(row(td(div($this->glimpse("name") || "Nová místnost", 'class="heading"'))).
		row(td(tab(
			row(th("název:").td($this->{name})).
			row(th("popis:").td($this->{description})).
			row(th("kapacita:").td($this->{capacity})).
			row(th("zodpovídá:").td($this->{manager} && (take Person $this->{manager})->name))
		))). row(td(tab(
			row(th("rozvrh:").($placement && tt("den").tt("čas").tt("aktivita").tt("vede"))).$placement
		)))
	, 'class="card"');
}


# show schedule
# ~~~~~~~~~~~~~~
sub schedule {
	my $this = shift;

	print tab(
		row(td(div($this->glimpse("name") || "Nová místnost", 'class="heading"'))).
		row(td(schedule Place
			["schedule public",   room Place $this->{id}, "public"],
			["schedule internal", room Place $this->{id}, "internal"]
		))
	, "class=\"card\"");

}


# start print page
# ~~~~~~~~~~~~~~~~~
sub prrrint_start {
	my $pack = shift;

	print tab(row(td(
		label(checkbox("prrrintschedule"). " tiskni rozvrh ")
	)), 'class="navig"');
}


# finish print page
# ~~~~~~~~~~~~~~~~~~
sub prrrint_finish {
	my $pack = shift;
}


# printing schedules
# ~~~~~~~~~~~~~~~~~~~
sub prrrint {
	my $this = shift;

	my $placement = join '', map {(take Place $_)->glimpse("{[][day][start-finish][activity][leaders]}")} room Place $this->{id};
	print tab(
		row(td(div($this->glimpse("name") || "Nová místnost", 'class="heading"'))).
		row(td(tab($placement)))
	, "class=\"card\"");

	# and maybe print the schedule
	if ($qp::prrrintschedule) {
		my $printer = take Printer $user->printer;

		my $text = $this->glimpse(
			'\rozvrh\ \vskip 7mm minus 12mm\centerline{\fheading name}\vskip 1cm minus 7mm', { prrrint => 1 });

		$text .= '
			\halign{
				\em{#}\quad\hfill&\hfill#--&#\quad\hfill & #\quad\hfill & \vtop{#}\hfill \cr
		';

		my ($day, $showday, $manager);
		for my $pid (room Place $this->{id}) {
			my $place = take Place $pid;
			if ($day ne $place->glimpse('longday')) {
				$text .= '\noalign{\vrule height 3pt width 0pt\hrule width 16cm\vrule depth 3pt width 0pt}';
				$day = $place->glimpse('longday');
				$showday = $day;
			}
			$text .= $place->glimpse(
				"\\vrule height 12pt depth 3pt width 0pt $showday&start&finish&activity&leaders\\vrule depth 5pt width 0pt \\cr ",
				{ prrrint => 1 });
			$showday = '';
		}

		# if we know the room manager -- set it
		$manager = '\em{Zodpovědná osoba:} '. (take Person $this->{manager})->glimpse("name", { prrrint => 1 })
			if $this->{manager};

		#$text .= '}\vfill'. $manager .'\fmini\rightskip0pt \hfill '.
		$text .= '}\vskip 2cm minus 1.7cm'. $manager .'\rightskip0pt \hfill vytisknuto '.
			$now->user_date(undef, { long => 1, year => 1 }) .'\vfill\break\eject';

		$printer->prrrint($text);
	}
}


# maybe save changed data
# ~~~~~~~~~~
sub DESTROY {
	my $this = shift;

	if ($this->{updated}) {
		$dbi->exe(sprintf "update rooms set
				name          = '%s',
				description   = '%s',
				capacity      = %s,
				manager       = %s
				where id = $this->{id}",
				uq(@$this{qw(name description)}), qd(@$this{qw(capacity manager)})
			);
	}
}


# glimpse at the room in one <table> row
# ~~~~~~~
# <<  format -- string containing list of columns to be showed
#     (i)d  (n)ame  (d)escription (c)apacity (m)anager checkbo(x)
#     an `<' at the beginning means to include <tr>
#     an `>' at the end to include </tr>
# <<  ider -- ider to be used as name of checkbox
sub glimpse {
	my ($this, $format, $par) = @_;

	my %gl = (
		($par->{nohrefs} || $par->{prrrint} || !$user->can("view_rooms")
		 	? ( name	=> sub { $this->{name} })
			: ( name	=> sub {
							my ($name, $namee) = $this->{name} =~ /^(.*)(.)$/;

							"<a href=\"$Conf::Url/mistnosti/mistnosti.pl?rids=$this->{id}\" ".
								"title=\"". uqq($this->{description}) ."\">". uqq($name) ."</a>".
							"<a href=\"$Conf::Url/mistnosti/mistnosti.pl?rids=$this->{id}&action=schedule\" title=\"rozvrh\">".
								uqq($namee). "</a>"
					})
		),
		description	=> sub { $this->{description} },
		capacity	=> sub { $this->{capacity} },
		manager		=> sub { $this->{manager} && (take Person $this->{manager})->glimpse("name") }
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# browsing rooms
# ~~~~~~~~~~~~~~~
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor (
			0 => "jména",
			1 => "kapacity"
	);

	my ($condition, $direct, $directaction, $search);

	# let's start with parsing search string
	$search = $qp::search;

	# remove direct modifiers (and count them)
	if ($direct = $search =~ s/\s*([?!+\-\/=])\s*//g) {
		# what king of redirection?
		$directaction = {
			"?" => "show",
			"!" => "edit",
			"/" => "prrrint",
			"=" => "schedule"
		}->{$1} if $direct;
	}
	# remove ',' and space from beginning and end
	$search =~  s/[,\s]*$//;
	$search =~ s/^[,\s]*//;

	# let's go!
	for my $word ($search =~ /(\s*,\s*|\s+|[^\s,]+)/g) {
		# convert escaped space (as '_') back to normal
		$word =~ s/_/ /g;
		$word = uq $word;
		if ($word =~ /^\s+$/) {
			$condition .= " and ";
		}
		elsif ($word =~ /^(\s*,\s*)$/) {
			$condition .= " or ";
		}
		else {
			$condition .= "(name ~* '$word' or description ~* '$word')";
		}
	}
	# and last adjustment
	$condition = " and ($condition)" if $condition;

	# capacity filter
	my $capacity = ck $qp::capacity;
	$condition .= " and capacity >= $capacity" if $capacity;

	# searching free rooms
	my $day = ck $qp::day;
	my $start = user_time Time $qp::start;
	my $finish = user_time Time $qp::finish;

	if ($qp::now) {
		$dbi->exe("select now(), now() + '1 hour', extract (dow from now())");
		($start, $finish, $day) = $dbi->row;
		$start = db_stamp Time $start;
		$finish = db_stamp Time $finish;
	}

	if (defined $day && $day != -1 || $start->db_time || $finish->db_time) {
		$condition .= " except select distinct r.id, r.name from placed_view p
			join rooms r
			   on r.id = p.room
			where season = ". $user->season;
		$condition .= " and (day = $day)" if defined $day && $day != -1;
		$condition .= " and (coalesce(". qd($start->db_time) .", '00:00:00') < coalesce(finish, '23:59:59'))" if $start->db_time;
		$condition .= " and (coalesce(". qd($finish->db_time) .", '23:59:59') > coalesce(start, '00:00:00'))" if $finish->db_time;
	}

	my $cleaver = query Cleaver "select id, name from rooms
		where 't' $condition order by ". ($qp::sort ? "capacity" : "name"),
		      $direct > 2 && $Conf::SliceSizesGreat;

	if (!$cleaver->empty && ($direct > 1 || $direct == 1 && $cleaver->total == 1 )) {
		my @rids;
		while (my ($rid) = $cleaver->next) {
			push @rids, $rid;
		}
		header undef, { redir => "$Conf::UrlRooms/?action=".$directaction."&rids=". join '.', @rids };
		return;
	}

	header $par->{header}, { javascript => "yes" } if $par->{header};
	form $par->{navigform}, "navig" if $par->{navigform};
	print tab(
		row(td(tab(row(
			th("kapacita:").
			td(input("capacity", $capacity, 4, 3)).
			th("den:").
			td($dayer->select("day", $day, " ", undef, -1)).
			th("od:").
			td(input("start", $start->user_time_short, @Conf::InputTime)).
			th("do:").
			td(input("finish", $finish->user_time_short, @Conf::InputTime)).
			td(checkbox("now"). " teď")
		)))). row(td(tab(row(
			th("setřídit:").
			td($sorter->select("sort", uqq $qp::sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(input("search", uqq $qp::search)).
			td(submit "action", "najít")
		)))). row(td(tab(row(
			td("nalezené místnosti (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		))))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná místnost<p>"), return if $cleaver->empty;

	my $ider = new Ider "r";

	# start table
	print tab(undef, 'class="scraps"'),
		row th(""). th("id"). th("název"). th("zodpovídá"). th("kapacita").th("popis");

	# glimpses
	while (my ($rid) = $cleaver->next) {
		my $r = take Room $rid;
		print $r->glimpse("{[#][id][name][manager][capacity][description]}", { ider => $ider });
	}

	# finish table
	print row(td(checkall("r.*r.*r"), 'colspan="7" class="footer"')), tabb;

	# we have found something
	1
}


1

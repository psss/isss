package Place;

  #######################################################
 ####  Place -- placing placed in rooms  ###########
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new activity
#  > take		constructor (takes pid)
#  > delete		delete a user
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > activity
#  > room
#  > detail
#  > start
#  > finish
#  > day
#
#  > date_start		date interval -- for information purposes only
#  > date_finish
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#
#  > glimpse		one <tr> info 'bout the user
#
#  > edit		make formular for editing
#  > show		show user info
#
#  > save		save data into database
#  > conflicts		get activities which conflict with us

use strict qw(subs vars);

use Aid;
use Time;
use Room;
use Activity;
use Inquisitor;

my $roomer = room Inquisitor;
my $dayer = day Inquisitor;
my $longdayer = longday Inquisitor;

#  create new place for an activity
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
	my ($pack, $activity, $room) = @_;
	fatal "je třeba zadat aktivitu k umístění" unless defined $activity;
	my $id;
	$room = 'null' unless defined $room;

	# insert into db
	$dbi->beg;
		# why day????
		#$dbi->exe("insert into placed (activity, day) values ($activity, 0)");
		$dbi->exe("insert into placed (activity, room) values ($activity, $room)");
		$dbi->exe("select currval('placed_id_seq')");
		$id = $dbi->val;
	$dbi->end;

	take Place $id;
}



# constructor for existing placements
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $pid) = @_;
	return undef unless $pid;

	my $this = {};

	$dbi->exe("select id, activity, room, detail, start, finish, day, date_start, date_finish
			from placed_view where id = $pid")
		or fatal("takové umístění neexistuje ($pid)");
	@$this{qw(id activity room detail start finish day date_start date_finish)} = $dbi->row;

	$this->{start} = db_time Time $this->{start};
	$this->{finish} = db_time Time $this->{finish};
	$this->{date_start} = db_date Time $this->{date_start};
	$this->{date_finish} = db_date Time $this->{date_finish};

	bless $this;
}



# copying placements
# ~~~~~~~~~~~~~~~~~~~
# << new activity's id
sub copy {
	my ($this, $activity) = @_;

	my $new = create Place $activity;
	$this->{id} = $new->id;
	$this->{activity} = $activity;
	$this->save;
	$this;
}




# deleting a placement
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat umístění"), return unless $user->can("edit_placed");
	$dbi->exe("delete from placed where id = $this->{id}");
}


sub id {
	my $this = shift;

	$this->{id};
}



# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit this activity
        error("nemáš právo upravovat umístění"), $this->show, return unless $user->can("edit_placed");
	my %err;

	# if update then make some checks
	if (defined ${"qp::place$this->{id}day"}) {
		# get new values
		for my $val (qw(room detail day start finish)) {
			$this->{$val} = ${"qp::place$this->{id}$val"};
		}

		# check dates -- if got some and they're bad -- then cry out!
		for my $time (qw(start finish)) {
			$this->{$time} = user_time Time $this->{$time};
			if (${"qp::place$this->{id}$time"} ne "" and not $this->{$time}->db_time) {
				$err{$time} = err "nesprávný čas"
			}
		}

		$this->{room} = undef unless $this->{room};
		$this->{day} = undef if $this->{day} == -1;
		$this->delete, return "" if ${"qp::place$this->{id}delete"};

		$this->save;
	};

	my $conflicts = join ', ', map {(take Activity $_)->glimpse("name")} $this->conflicts;
	$err{conflicts} = err("toto umístění koliduje s následujícími aktivitami", "konflikty") if $conflicts;

	my $room;
	$err{capacity} = err $room->name ." má kapacitu pouze ". $room->capacity. infl($room->capacity, " místo", " místa", " míst"), "kapacita"
		if $this->{room} && ($room = take Room $this->{room})->capacity < (take Activity $this->{activity})->max;

	row(
		td().
		td($dayer->select("place$this->{id}day", $this->{day}, " ", undef, "-1")).
		td(input("place$this->{id}start", $this->{start}->user_time_short, $Conf::TimeSize, $Conf::TimeMax)).
		td(input("place$this->{id}finish", $this->{finish}->user_time_short, $Conf::TimeSize, $Conf::TimeMax)).
		td($roomer->select("place$this->{id}room", $this->{room}, " ")).
		td(input("place$this->{id}detail", uqq $this->{detail}, 7, $Conf::DescMax)).
		td(checkbox("place$this->{id}delete")).
		td(join ' ', $err{capacity}, $err{conflicts}).
		td($conflicts)
	)
}


# save changed data
# ~~~~~~~~~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update placed set
			activity	=  %s,
			detail		= '%s',
			day		=  %s,
			room		=  %s,
			start		=  %s,
			finish		=  %s
			where id = $this->{id}",
			($this->{activity}, uq($this->{detail}),
			qd($this->{day}, $this->{room}, $this->{start}->db_time, $this->{finish}->db_time))
		);
}


# get activities which conflict with us
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub conflicts {
	my $this = shift;

	$dbi->exe("select other.activity from
				placed_view other,
				placed_view this
			where
				-- join
				this.id	 = $this->{id} and
				other.id != $this->{id} and

				-- rooms have to be same
				this.room is not null and
				this.room = other.room and

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

	$dbi->vals;
}



# glimpse at the placement in one <table> row
# ~~~~~~~
# <<  format -- string containing list of columns to be showed
#     (i)d  (a)ctivity (r)oom (s)tart (f)inish (d)ay
#     an `<' at the beginning means to include <tr>
#     an `>' at the end to include </tr>
# <<  ider -- ider to be used as name of checkbox
sub glimpse {
	my ($this, $format, $par) = @_;

	my $dash = $par->{prrrint} ? "--" : "-";
	my $space = $par->{prrrint} ? " " : '&nbsp;';

	my %gl;
	%gl = (
		 activity  => sub { (take Activity $this->{activity})->glimpse("name", $par) },
		 leaders   => sub { (take Activity $this->{activity})->glimpse("leaders", $par) },
		 lead      => sub { (take Activity $this->{activity})->glimpse("lead", $par) },
		 room      => sub { ($this->{room} ? (take Room $this->{room})->glimpse("name", $par) : "") },
		 place     => sub { join ', ', grep {$_} ($this->{room} ? (take Room $this->{room})->glimpse("name", $par) : ""), $this->{detail} },
		 start     => sub { $this->{start}->user_time(undef, { short => 1 }) },
		 finish    => sub { $this->{finish}->user_time(undef, { short => 1 }) },
		 dstart    => sub { $this->{date_start}->user_date },
		 dfinish   => sub { $this->{date_finish}->user_date },
		 day       => sub { $par->{short} ? $dayer->name($this->{day}) : $longdayer->name($this->{day}) },
		 longday   => sub { $longdayer->name($this->{day}) },
		 times     => sub { join $dash, grep {$_} &{$gl{start}}, (!$par->{supershort} && &{$gl{finish}}) },
		 detail    => sub { $this->{detail} },
		 summary   => sub {
		 			join ",$space", grep {$_}
						&{$gl{day}},
						&{$gl{times}},
						((!$par->{short} || $par->{detail}) && (&{$gl{room}}, $this->{detail}))
				},
		 tooltip   => sub {
		 			join ' / ', grep {$_}
						($this->{room} ? (take Room $this->{room})->glimpse("name", { nohrefs => 1 }) : ""),
						$this->{detail},
						(take Activity $this->{activity})->glimpse("leaders", { nohrefs => 1, break => ', ' });
				}


	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# show short place info
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub show {
	my ($this, $short) = @_;

	join ', ', grep {$_}
		$dayer->name($this->{day}),
		(join '-', grep {$_} $this->{start}->user_time_short, $this->{finish}->user_time_short),
		($this->{room} && !$short ? (take Room $this->{room})->glimpse("name") : ""),
		(!$short && uqq($this->{detail}))
}


# show short place info for printing
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prrrint {
	my ($this, $short, $dash) = @_;

	$dash = '--' unless $dash;

	join ', ', grep {$_}
		$longdayer->name($this->{day}),
		(join $dash, grep {$_} $this->{start}->user_time_short, $this->{finish}->user_time_short),
		($this->{room} && !$short ? (take Room $this->{room})->glimpse("name", { nohrefs => "no!" }) : ""),
		(!$short && uqq($this->{detail}))
}


# place place into nice rectangular
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub place {
	my ($this, $type) = @_;

	return unless defined $this->{day};
	$type = "schedule" unless defined $type;

	my $start = int ($Conf::ScheduleHourWidth *
		(1 + $this->{start}->{hou} - $Conf::ScheduleStart + $this->{start}->{min} / 60));
	my $finish = int ($Conf::ScheduleHourWidth *
		(1 + $this->{finish}->{hou} - $Conf::ScheduleStart + $this->{finish}->{min} / 60));

	my $left = $start;
	my $width = $finish - $start - $Conf::ScheduleCut;
	my $top = $Conf::ScheduleHourHeight * (($this->{day} || 7) - 1);

	$this->glimpse(
		"<table class=\"$type\" style=\"position: absolute; top: ${top}px; left: ${left}px; width: ${width}px;\">
			<tr><td class=\"heading\">activity</td></tr>
			<tr><td style=\"padding: 0px\">
				<table title=\"tooltip\" width=\"100%\">
					<tr><td class=\"since\">start</td></tr>
					<tr><td class=\"until\">finish</td></tr>
				</table>
			]</tr>
		</table>"
	);
}

# place placements into nice schedule
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub schedule {
	my ($this, @placements) = @_;

	my $tables;
	for my $placements (@placements) {
		my $type = shift @$placements;
		$tables .= join '', map {(take Place $_)->place($type)} @$placements;
	}

	# why?!?!?!?!?!?!?!?!?!?!?!?!
	my $daywidth = $Conf::ScheduleWidth - $Conf::ScheduleHourWidth / 2;

	# add days
	$tables .= join '', map { "<div class=\"schedule\" style=\"position: absolute; top: ".
		($_ * $Conf::ScheduleHourHeight) ."px; width: ${daywidth}px\">". $dayer->name(($_ + 1) % 7) ."</div>" } (0..6);

	"<div style=\"height: ${Conf::ScheduleHeight}px; width: ${Conf::ScheduleWidth}px\">
		<div style=\"position: relative;\">$tables</div>
	</div>";
}


#  get activity's placements
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub activity {
	my ($pack, $activity) = @_;

	$dbi->exe("select id from placed_view
			where activity = $activity
			  order by day, start, finish");
			  #and season = ". $user->season ."
	$dbi->vals;
}



# get all activities placed in a room
sub activities {
	my ($pack, $room) = @_;

	$dbi->exe("select distinct a.id, a.name from
			activities a join placed p on a.id = p.activity
			where p.room = $room
			and season = ". $user->season ."
			order by a.name
		");

	my @aids;
	while (my ($aid) = $dbi->row) {
		push @aids, $aid;
	}

	@aids;
}



#  get room's placements
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub room {
	my ($pack, $room, $public) = @_;

	my $condition;
	$condition = "" if $public eq "all" || !defined $public;
	$condition = " and pub" if $public eq "public";
	$condition = " and not pub" if $public eq "internal";

	$dbi->exe("select id from placed_view
			where room = $room
				$condition
			  and season = ". $user->season ."
			order by day, start, finish");
	$dbi->vals;
}


1

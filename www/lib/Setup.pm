package Setup;

  #######################################################
 ####  Setup -- setting thing up  ######################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > take		read setup
#
#  object data:
#  ~~~~~~~~~~~~
#  > round_rate			.
#  > confirm_time		.
#  > free_activities_text	.
#  > fake_time			.
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > edit		make formular for editing
#  > save		save setup
#
#  > free_activities_text
#  > fake_time

use locale;
use strict qw(subs vars);

use Aid;
use Conf;
use Activity;
use Inquisitor;

my $dayer = new Inquisitor (
		0  => 0,
		1  => 1,
		2  => 2,
		3  => 3,
		4  => 4,
		5  => 5,
		6  => 6,
		7  => 7,
		8  => 8,
		9  => 9,
		10 => 10,
		11 => 11,
		12 => 12,
		13 => 13,
		14 => 14,
		21 => 21,
		28 => 28
);

my $rounder = new Inquisitor (
		  1 => 1,
		  5 => 5,
		 10 => 10,
		 20 => 20,
		 50 => 50,
		100 => 100
);


my @attr = qw(round_rate confirm_time fake_time free_activities_text);


# reading the setup from database
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my $this = {};

	$dbi->exe("select ". (join ", ", @attr) ." from setup")
		or fatal("nastavení neexistuje???");
	@$this{@attr} = $dbi->row;

	$this->{fake_time} = db_stamp Time $this->{fake_time};

	bless $this;
}


# get free_activities_text
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub free_activities_text {
	my $this = shift;

	$this->{free_activities_text};
}


# get possible fake registration time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fake_time {
	my $this = shift;

	$this->{fake_time};
}



# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
# >> persons id (can change when there are duplicates)
sub edit {
        my $this = shift;

        # make sure user can edit this person
        error("nemáš právo upravovat nastavení"), return unless $user->can("edit_setup");

	if (defined ${"qp::setup_round_rate"}) {
		# get new values
		for my $val (@attr) {
			$this->{$val} = ${"qp::setup_$val"};
		}

		# check them
		$this->{round_rate} = ck $this->{round_rate};
		$this->{round_rate} = $Conf::DefaultRegistrationsConfirmTime
			unless defined $this->{round_rate};

		$this->{confirm_time} = ck $this->{confirm_time};
		$this->{confirm_time} = $Conf::DefaultRoundRate
			unless defined $this->{confirm_time};

		$this->{fake_time} = user_stamp Time $this->{fake_time};

		# save changes
		$this->save;
		message "uloženo";
	};

	print tab(
		row(td(div("Nastavení", 'class="heading"'))).
		row(td(tab(
			row(
				th('zaokrouhlení částek:').
				td($rounder->select("setup_round_rate", $this->{round_rate}). " Kč")
			). row(
				th('potvrzení registrací:').
				td($dayer->select("setup_confirm_time", $this->{confirm_time}).
					infl($this->{confirm_time}, " den", " dny", " dní"))
			). row(
				th('datum rezervací:').
				td(input("setup_fake_time", $this->{fake_time}->user_stamp, @Conf::InputStamp))
			). row(
				th('text seznamu volných aktivit:', 'rowspan="2"').
				td(area("setup_free_activities_text", uqq($this->{free_activities_text}), 40, 5))
			)
		)))
	 , 'class="card"');
}



# save changed data
# ~~~~~~~~~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update setup set
			round_rate		= %s,
			confirm_time		= %s,
			fake_time		= %s,
			free_activities_text	= '%s'",

			$this->{round_rate},
			$this->{confirm_time},
			qd($this->{fake_time}->db_stamp),
			uq $this->{free_activities_text}
		);
}



1

package Time;

  #######################################################
 ####  Time -- handling with times  ####################
#######################################################
#
#  make dates, times, timestamps,...
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > current		constructor for current time (now)
#
#  > user_date		user format (31. 12. 2000)
#  > user_time		user format (18:12:13)
#  > user_stamp		user format (31. 12. 2000 18:12:13)
#
#  > db_date		postgres' format (2000-12-31)
#  > db_time		postgres' format (18:12:13)
#  > db_stamp		postgres' format (2000-12-31 18:12:13)
#
#  object data:
#  ~~~~~~~~~~~~
#  > yea		year
#  > mon		month
#  > day		day
#  > hou		hour
#  > min		minute
#  > sec		seconds
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > check_date		check if date is ok
#  > check_time		check if time is ok
#
#  > user_date_short	user short format (31. 12.)
#  > user_date_long	user long format (31. prosince 2000)
#
#  > compare		compare two dates
#

use strict;

my @months = qw(
	ledna února března dubna května června
	července srpna září října listopadu prosince
);

my @days = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);


# check date ranges
# ~~~~~~~~~~~~~~~~~
sub check_date {
	my $this = shift;

	my $leap = $this->{mon} == 2 && ($this->{yea} % 4 == 0) &&
		($this->{yea} % 100 != 0 || $this->{yea} % 400 == 0);

	$this->{yea} >= 1900 && $this->{yea} <= 2500 &&
	$this->{mon} >= 1    && $this->{mon} <= 12   &&
	$this->{day} >= 1    && $this->{day} <= $days[$this->{mon} - 1] + $leap;
}


# check time ranges
# ~~~~~~~~~~~~~~~~~~
sub check_time {
	my $this = shift;

	defined $this->{hou} && defined $this->{min} && defined $this->{sec} &&
	$this->{hou} >= 0    && $this->{hou} <= 23   &&
	$this->{min} >= 0    && $this->{min} <= 59   &&
	$this->{sec} >= 0    && $this->{sec} <= 59;
}


# constructor for actual time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub current {
	my $this = {};
	@$this{qw(yea mon day hou min sec dow)} = (localtime())[5,4,3,2,1,0,6];
	$this->{yea} += 1900;
	$this->{mon}++;

	# set fixed timestamp
	#@$this{qw(day mon yea hou min sec)} = (10, 4, 2007, 10, 00, 00);

	# set fixed date
	#@$this{qw(day mon yea)} = (10, 4, 2007);

	bless $this;
}


# user_date -- constructing, setting, getting user date
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  7. 7. 2007
# <<  or:      (7[*7[*2007]])   (* for any nondigit)
sub user_date {
	my ($this, $string, $par) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new date
	if ($string) {
		@$this{qw(day mon yea)} = $string =~ /(\d+)/g;
	}

	# unless user specified month/year fill them with current values
	if (not defined $this->{mon} or not defined $this->{yea}) {
		my $now = current Time;
		$this->{mon} = $now->{mon} unless defined $this->{mon};
		$this->{yea} = $now->{yea} unless defined $this->{yea};
	}

	return $this if $constructing;
	return undef unless $this->check_date;

	my $sp = $par->{prrrint} ? '\thinskip ' : ' ';

	# long version
	return sprintf("%i.$sp", $this->{day}). $months[$this->{mon} - 1].
		($par->{year} ? " $this->{yea}" : "").
		($par->{'time'} ? " ". $this->user_time : "")
			if $par->{long};

	# short version
	return sprintf "%i.$sp%i.", @$this{qw(day mon)} if $par->{short};

	# regular version
	sprintf "%i.$sp%i.$sp%i", @$this{qw(day mon yea)};
}

# user_time -- constructing, setting, getting user time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  7:07:07
# <<  or:      (7[*7[*7]])   (* for any nondigit)
sub user_time {
	my ($this, $string, $par) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new time
	if ($string) {
		@$this{qw(hou min sec)} = $string =~ /(\d{1,2})/g;
		$this->{min} = 0 unless defined $this->{min};
		$this->{sec} = 0 unless defined $this->{sec};
	}

	return $this if $constructing;
	return undef unless $this->check_time;

	# short version
	return sprintf "%i:%02i", @$this{qw(hou min)} if $par->{short};

	# long version
	sprintf "%i:%02i:%02i", @$this{qw(hou min sec)};
	#(sprintf "%i:%02i", @$this{qw(hou min)}).
	#	($this->{sec} == 0 ? "" : sprintf ":%02i", $this->{sec});
}


# user_stamp -- constructing, setting, getting user stamp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  7. 7. 2007 7:07:07
# <<  or:      (7[*7[*2007]]) (7[*7[*7]])   (* for any nondigit)
#              (separated on the right most space)
sub user_stamp {
	my ($this, $string, $par) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new stamp
	if ($string) {
		my ($date, $time) = $string =~ /(.*)\s(\S+)/;
		# if no space -- suppose that we got only date
		unless ($date) {
			$date = $string;
			$time = '00:00:00';
		}
		$this->user_date($date);
		$this->user_time($time);
	}

	return $this if $constructing;
	return undef unless $this->check_date && $this->check_time;
	$this->user_date(undef, $par)." ".$this->user_time(undef, $par);
}


# db_date -- constructing, setting, getting database date
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  2007-07-07
sub db_date {
	my ($this, $string) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new date
	if ($string) {
		@$this{qw(yea mon day)} = $string =~ /(\d+)/g;
	}

	return $this if $constructing;
	return undef unless $this->check_date;
	sprintf "%i-%02i-%02i", @$this{qw(yea mon day)};
}


# db_time -- constructing, setting, getting database time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  07:07:07
sub db_time {
	my ($this, $string) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new time
	if ($string) {
		@$this{qw(hou min sec)} = $string =~ /(\d+)/g;
	}

	return $this if $constructing;
	return undef unless $this->check_time;
	sprintf "%02i:%02i:%02i", @$this{qw(hou min sec)};
}

# db_stamp -- constructing, setting, getting db stamp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  format:  2007-07-07 07:07:07
sub db_stamp {
	my ($this, $string) = @_;

	my $constructing = $this eq 'Time';
	bless $this = {} if $constructing;

	# if got string let's set up new stamp
	if ($string) {
		my ($date, $time) = $string =~ /(\S+) (\S+)/;
		$this->db_date($date);
		$this->db_time($time);
	}

	return $this if $constructing;
	return undef unless $this->check_date && $this->check_time;
	$this->db_date." ".$this->db_time;
}




# return date in long format 23. prosince 2000
# ~~~~~~~~~~~
sub user_date_long {
	my ($this, $year, $time) = @_;

	return undef unless $this->check_date;
	return undef if $time && !$this->check_time;

	sprintf("%i. ", $this->{day}). $months[$this->{mon} - 1].
		($year ? " $this->{yea}" : "").
		($time ? " ". $this->user_time : "");
}


# return date in short format 23. 12.
# ~~~~~~~~~~~
sub user_date_short {
	my ($this, $print) = @_;

	return undef unless $this->check_date;

	my $space = $print ? '\thinskip' : " ";

	sprintf("%i.$space%i.", $this->{day}, $this->{mon});
}


sub user_time_short {
	my ($this) = @_;

	return undef unless $this->check_time;
	sprintf "%i:%02i", @$this{qw(hou min)};
}

# compare two dates
# > -1	we're less (earlier)
# >  0  equal
# >  1  we're greater (later)
sub compare {
	my ($this, $other) = @_;

	return undef unless $this->check_date && $other->check_date;

	return 0 if
		$this->{yea} == $other->{yea} &&
		$this->{mon} == $other->{mon} &&
		$this->{day} == $other->{day};

	return -1 if
		$this->{yea} < $other->{yea} ||
		$this->{yea} == $other->{yea} && $this->{mon} < $other->{mon} ||
		$this->{yea} == $other->{yea} && $this->{mon} == $other->{mon} && $this->{day} < $other->{day};

	return 1;
}


# day of week (currently works only for current Time)
# ~~~~~~~~~~~
sub dow {
	my $this = shift;

	$this->{dow};
}


1

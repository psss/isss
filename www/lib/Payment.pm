package Payment;

  #######################################################
 ####  Payment -- handling payment database ############
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new payment
#  > take		constructor (takes pid)
#  > prrrint		print payments (can be more than one)
#  > cancel		cancel (delete) payment
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > registration
#  > amount
#  > created		create time
#  > printed		time when the payment was executed (printed)
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#
#  > glimpse		one <tr> info 'bout the user
#

use strict qw(subs vars);

use Aid;
use Time;
use Printer;
use Register;


#  create new payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub create {
	my ($pack, $registration, $amount) = @_;
	$amount = ck $amount;
	fatal "je třeba zadat registraci a částku" unless defined $registration && defined $amount;

	# insert into db
	my $id;
	$dbi->beg;
		$dbi->exe("insert into payments (registration, amount, collector, created)
				values ($registration, $amount, ". $user->person .", '". $now->db_stamp ."')");
		$dbi->exe("select currval('payments_id_seq')");
		$id = $dbi->val;
	$dbi->end;

	take Payment $id;
}



# constructor for existing payments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $pid) = @_;
	return undef unless $pid;

	my $this = {};

	$dbi->exe("select id, registration, amount, collector, created, printed from payments where id = $pid")
		or fatal("taková platba neexistuje ($pid)");
	@$this{qw(id registration amount collector created printed)} = $dbi->row;

	$this->{created} = db_stamp Time $this->{created};
	$this->{printed} = db_stamp Time $this->{printed};

	bless $this;
}



# return payment id
# ~~~~~~~~~~~~~~~~~~~~~~~
sub id {
	my $this = shift;

	$this->{id};
}



# glimpse at the payment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub glimpse {
	my ($this, $format, $par) = @_;

	# to fetch registration only once
	my $registration;

	my %gl = (
		 id		=> sub { sprintf "%0".$Conf::PaymentZeroes."i", $this->{id} },
		 registration	=> sub { sprintf "%0".$Conf::RegistrationZeroes."i", $this->{registration} },
		 activity	=> sub { ($registration || ($registration = take Register $this->{registration}))->glimpse("activity", $par) },
		 person		=> sub { ($registration || ($registration = take Register $this->{registration}))->glimpse("person", $par) },
		 amount		=> sub { "$this->{amount},-" },
		 created	=> sub { $this->{created}->user_stamp },
		 printed	=> sub { $this->{printed}->user_stamp },
		 collector	=> sub { $this->{collector} && (take Person $this->{collector})->glimpse("name", $par) }
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# get total sum of payments for specified registration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub total {
	my ($pack, $registration) = @_;
	return undef unless defined $registration;

	$dbi->exe("select sum(amount) from payments where registration = $registration");
	$dbi->val;
}


# set the payment as printed / get printed time
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub printed {
	my $this = shift;

	unless ($this->{printed}->db_date) {
		$this->{printed} = db_stamp Time $now->db_stamp;
		$dbi->exe("update payments set printed = '". $this->{printed}->db_stamp ."' where id = $this->{id}");
	}

	$this->{printed};
}


# get person's payments
# ~~~~~~~~~~~~~~~~~~~~~~
sub person {
	my ($pack, $person) = @_;

	$dbi->exe("select p.id from payments p
			join registrations r
			  on p.registration = r.id
			join activities a
			  on r.activity = a.id
			where r.person = $person
			  and a.season = ". $user->season ."
			  order by p.id");
	$dbi->vals;
}


# print all pending payments for a person in current season
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub prrrint_pending {
	my ($pack, $person) = @_;

	$dbi->beg;
		$dbi->exe("lock table payments in share mode");
		$dbi->exe("select p.id from payments p
				join registrations r
				  on p.registration = r.id
				join activities a
				  on r.activity = a.id
				where r.person = $person
				  and a.season = ". $user->season ."
				  and p.printed is null
				  order by p.id");
		my @pids = $dbi->vals;

		# print payments (except zeroes-only)
		if (@pids && prrrint Payment { person => $person, zeroes => 0 }, @pids) {
			# if printing is ok -- set as printed
			for my $pid (@pids) {
				$dbi->exe("update payments set printed = '". $now->db_stamp ."' where id = $pid");
			}
		}
	$dbi->end;
}



# print payments
# ~~~~~~~~~~~~~~~
sub prrrint {
	my ($this, $pars, @pids) = @_;

	my (@income, @outcome, $payment, $total, $heading, $act, $number, $details, $zeroesonly);
	$total = 0;
	$zeroesonly = 1;

	for my $pid (@pids) {
		$payment = take Payment $pid;
		$payment->printed;
		if ($payment->{amount} >= 0) {
			push @income, $payment;
		}
		else {
			push @outcome, $payment;
		}
		$total += $payment->{amount};
		$zeroesonly = 0 if $payment->{amount} != 0;
	}

	# if there's not any payment to print -- finito!
	return undef if !@income && !@outcome;

	# if there are only zero payments and we do not want to print them -- we're finished
	return "ok" if $zeroesonly && !$pars->{zeroes};

	# payment number to last payments id
	$number = sprintf "%0".$Conf::PaymentZeroes."i", $payment->id;
	if ($total >= 0) {
		$heading = "Příjmový";
		$act = "přijato od";
	}
	else {
		$heading = "Výdajový";
		$act = "vyplaceno";
	}

	my $person = take Person $pars->{person};
	my $print = "
		\\nadpis{$heading pokladní doklad č. $number}
		\\hlavicka

		\\em{datum:} ". $payment->printed->user_date(undef, { long => 1, year => 1, prrrint => 1 }) ."\\break
		\\em{$act:} ". $person->glimpse("name", { prrrint => "yes!" }). "\\break
		\\em{adresa:} ". $person->glimpse("address", { prrrint => "yes!" });

	if (@income) {
		$print .= "\n\n\t\t \\em{částky přijaté za přihlášené aktivity:}\\smallskip";

		for my $payment (@income) {
			my $activity = take Activity ((take Register $payment->{registration})->activity);
			$print .= "\n\t\t\t\\hbox to 8,5cm {".
				$activity->glimpse('name', { nohrefs => "no!" }).
				($activity->type == $Conf::ActivityTypeOther && ", členský příspěvek").
				'\dotfill\ '.
				$payment->glimpse('amount') .'}';
			#my $info = $activity->glimpse('placement') || $activity->glimpse('description');
			#my $info = join '\break ', grep {$_}
			#	$activity->glimpse('description', { prrrint => 1 }),
			#	$activity->glimpse('placement', { prrrint => 1 });
			$details .= $activity->glimpse("\\em{{name:}} \\break placement \\smallskip", { prrrint => "yes" });
		}
	}

	if (@outcome) {
		$print .= "\n\n\t\t \\em{částky vyplacené za zrušené aktivity:}\\smallskip";

		for my $payment (@outcome) {
			my $activity = take Activity ((take Register $payment->{registration})->activity);
			$print .= "\n\t\t\t\\hbox to 8,5cm {".
				$activity->glimpse('name', { nohrefs => "no!" }).
				'\dotfill\ '.
				$payment->glimpse('amount') .'}';
		}
	}

	my $longtotal = $total;
	$longtotal =~ s/-/---/;
	$print .= '

		\leavevmode\hbox to 8,5cm{\em{celkem\dotfill\ Kč '. $longtotal .',-}}\break
		\em{slovy:} '. speak($total) .'
		\medskip
		\em{převzal:}
		\bigskip
		\hrule
	';

	#$details = "\\em{Informace o aktivitách:}\\smallskip\n\n$details" if $details;

	$print = '
\doklady
\hbox {
	\vtop  {
		\hsize 8.5cm

		'. $print.$details .'
	}
	\hskip 2cm
	\vtop  {
		\hsize 8.5cm

		'. ($total != 0 ? $print.$details : "") .'
	}
}
	';

	(take Printer $user->printer)->prrrint($print)
}


# cancelling payments
# ~~~~~~~~~~~~~~~~~~~~
sub cancel {
	my ($pack, @pids) = @_;

	error("nemáš právo rušit platby"), return unless $user->can("cancel_payments");

	for my $pid (@pids) {
		$dbi->exe("delete from payments where id = $pid");
	}
}



# browsing payments
# ~~~~~~~~~~~~~~~~~~
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor (
			0 => "id",
			1 => "vytvoření",
			2 => "tisku"
	);

	my $sort = ck $qp::sort;
	$sort = 2 unless defined $sort;

	my $since = user_stamp Time $qp::since;
	my $until = user_stamp Time $qp::until;

	my $condition = " and created >= '". $since->db_stamp ."'" if $since->db_stamp;
	$condition .= " and created <= '". $until->db_stamp ."'" if $until->db_stamp;

	my $cleaver = query Cleaver "select id
			from payments_view
			where season = ". $user->season ." $condition
			order by ". (("id", "created", "printed")[$sort]) ." desc";

	$dbi->exe("select sum(amount)
			from payments_view
			where season = ". $user->season . $condition);
	my $sum = $dbi->val;
	$sum = 0 unless defined $sum;


	header $par->{header} if $par->{header};
	form $par->{navigform} if $par->{navigform};

	print tab(
		row(td(tab(row(
			td("čas od: ".input("since", $since->user_stamp, @Conf::InputStamp)).
			td("do: ".input("until", $until->user_stamp, @Conf::InputStamp))
		)))). row(td(tab(row(
			th("setřídit dle:").
			td($sorter->select("sort", $sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(submit "", "najít")
		)))). row(td(tab(row(
			td("nalezené platby (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		)))). row(td(tab(row(
			td("celkem Kč $sum,-")
		))))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná platba<p>"), return if $cleaver->empty;

	# this will contain all displayed users' ids
	my @pids;
	my $ider = new Ider "p";

	# start table
	print tab(undef, $Conf::TabScraps),
		row th("id"). th("človíček"). th("aktivita"). th("částka"). th("vyřídil"). th("provedena");

	# glimpses
	while (my $pid = $cleaver->next) {
		my $p = take Payment $pid;
		my $checkbox = $user->can("cancel_payments") ? "#" : "";
		print $p->glimpse("{[$checkbox id][person][activity][amount][collector][printed]}", { ider => $ider });
		push @pids, $pid;
	}

	# finish table
	#print row(td(checkbox "pids", join ('.', @pids)).td("všechny", 'colspan="7"')), tabb;
	print tabb;

	# we have found something
	1
}
1

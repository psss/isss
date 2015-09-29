package Card;

  #######################################################
 ####  Card -- handling member cards  ##################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new card
#  > take		constructor (takes cid)
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > person
#  > season
#  > printed
#  > created
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > id 		get the id
#
#  > glimpse		information center :)
#

use strict qw(subs vars);

use Aid;
use Time;
use Person;
use Season;
use Printer;
use Cleaver;
use Inquisitor;


#  create (maybe) new card request
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# < if $duplicate is true, then the card will be created
#   even if there already is a card for the season
sub create {
	my ($pack, $person, $duplicate) = @_;
	fatal "je třeba zadat osobu pro kterou se má karta vytvořit"
		unless defined $person;

	# insert into db
	my $id;
	$dbi->beg;
		$dbi->exe("lock table cards in share mode");
		# if card already exists (or is already pending when making duplicate) -- do not create new one
		if ($dbi->exe("select id from ".($duplicate ? "cards_pending": "cards") ."
					where person = $person
					  and season = ". $user->season)) {
			$dbi->end;
			return undef;
		}
		$dbi->exe("insert into cards (person, season, created)
				values ($person, ". $user->season .", now())");
		$dbi->exe("select currval('cards_id_seq')");
		$id = $dbi->val;
	$dbi->end;

	take Card $id;
}



# constructor for existing cards
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  cid
sub take {
	my ($pack, $cid) = @_;
	return undef unless $cid;

	my $this = {};

	$dbi->exe("select id, person, season, printed, created from cards where id = $cid")
		or fatal("taková karta neexistuje ($cid)");
	@$this{qw(id person season printed created)} = $dbi->row;

	$this->{printed} = db_stamp Time $this->{printed};
	$this->{created} = db_stamp Time $this->{created};

	bless $this;
}



# return card id
# ~~~~~~~~~~~~~~~~~~~~~~~
sub id {
	my $this = shift;

	$this->{id};
}



# glimpse at the card
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub glimpse {
	my ($this, $format, $par) = @_;

	my %gl = (
		 id		=> sub { sprintf "%0".$Conf::CardZeroes."i", $this->{id} },
		 person		=> sub { (take Person $this->{person})->glimpse("name") },
		 photo		=> sub { (take Person $this->{person})->glimpse("miminiphoto") },
		 created	=> sub { $this->{created}->user_date_long("year", "time") },
		 printed	=> sub { $this->{printed}->user_date_long("year", "time") || 'čeká na tisk...' }
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# get pending card's aids for current season and specified person
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub pending {
	my ($pack, $person) = @_;

	return undef unless defined $person;

	$dbi->exe("select id from cards_pending
			where person = $person
			  and season = ". $user->season);
	$dbi->vals;
}


# get person's cards
# ~~~~~~~~~~~~~~~~~~~~~~
sub person {
	my ($pack, $person) = @_;

	$dbi->exe("select id from cards
			where person = $person
			  and season = ". $user->season ."
			  order by created");
	$dbi->vals;
}


# clean card requests for person without any active card activity
# ~~~~~~~~~~~~~~~~~~~
sub clean {
	my ($pack, $person) = @_;

	#todo: may be some share locking? to be sure...
	unless (card Activity $person) {
		$dbi->exe("delete from cards
				where person = $person
				  and printed is null
				  and season = ". $user->season);
	}
}


# cancel card requests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub cancel {
	my ($pack, @cids) = @_;

	for my $cid (@cids) {
		$dbi->exe("delete from cards where id = $cid and printed is null");
	}
}


# browsing cards
# ~~~~~~~~~~~~~~~
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor (
			0 => "id",
			1 => "žádosti",
			2 => "tisku"
	);

	my $sort = ck $qp::sort;
	$sort = 2 unless defined $sort;

	my $condition;
	$condition = " and printed is null" if $qp::pendingonly;
	$condition .= " and photo is not null" if $qp::photoonly;
	$condition .= " and (payed > 0 or pay = payed)" if $qp::payedonly;
	$condition .= " and c.season = ". $user->season ." and r.season = ". $user->season
		unless $user->season eq 'season';

	my $cleaver = query Cleaver "select distinct c.id, c.created, printed from cards c
			join persons p
			  on c.person = p.id
			join registrations_view r
			  on c.person = r.person
			where r.card
			  $condition
		order by ". (("id desc", "c.created desc", "printed desc, c.created asc")[$sort]),
		      [ 8, "1 papír", 16, "2 papíry", 32, "4 papíry", 64, "8 papírů", 128, "16 papírů", 256, "32 papírů", 512, "64 papírů", 1024, "128 papírů" ];

	header $par->{header}, { javascript => "yes" } if $par->{header};
	form $par->{navigform}, "navig" if $par->{navigform};

	print tab(
		row(td(tab(row(
			td(label(checkbox("pendingonly", undef, $qp::pendingonly). " jen čekající kartičky")).
			td(label(checkbox("photoonly", undef, $qp::photoonly). " jen s fotkou")).
			td(label(checkbox("payedonly", undef, $qp::payedonly). " jen zaplacené"))
		)))). row(td(tab(row(
			th("setřídit dle:").
			td($sorter->select("sort", $sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(submit "", "najít")
		)))). row(td(tab(row(
			td("nalezené kartičky (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		))))
		, 'class="navig"');

	form $par->{checkboxform} if $par->{checkboxform};

	# make sure there is something
	print("\n\t\t\tnenalezena žádná kartička<p>"), return if $cleaver->empty;

	my $ider = new Ider "c";

	# start table
	print tab(undef, $Conf::TabScraps),
		row th(""). th("id"). th("fotka"). th("človíček"). th("žádost").th("vytisknuta");

	# glimpses
	while (my ($cid) = $cleaver->next) {
		my $u = take Card $cid;
		print $u->glimpse("{[#][id][photo][person][created][printed]}", { ider => $ider });
	}

	# finish table
	print row(td(checkall("c.*c.*c"), 'colspan="7" class="footer"')), tabb;

	# we have found something
	1
}


# print all pending cards for current season
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub prrrint_pending {
	my ($pack) = @_;

	#$dbi->beg;
		#$dbi->exe("lock table cards in share mode");

		# season browsing condition
		my $condition;
		$condition = " and c.season = ". $user->season ." and r.season = ". $user->season
			unless $user->season eq 'season';

		# if there are some -- print them!
		prrrint Card [ $dbi->vals ] if
			$dbi->exe("select distinct c.id from cards_pending c
					join persons p
					  on c.person = p.id
					join registrations_view r
					  on c.person = r.person
					where p.photo is not null
					  and pay = payed
					  $condition");

	#$dbi->end;
}


# print cards
# ~~~~~~~~~~~~
sub prrrint {
	my ($pack, $cids, $temporary) = @_;

	error("je třeba zadat id karet, které se mají vytisknout"), return undef unless @$cids;

	my $printer = take Printer $user->printer;

	while (my @cids8 = splice @$cids, 0, 8) {
		my $print = "\\prukazky\n";
		my @cids8copy = @cids8;
		my @photoids;

		while (my @cids2 = splice @cids8, 0, 2) {
			$print .= '\hbox to 20cm{';

			for my $cid (@cids2) {
				my $card = take Card $cid;
				my $person = take Person $card->{person};
				my ($photoid, $photo, $sign);

				if ($photoid = $person->photoid) {
					push @photoids, $photoid;
					$photo = "\\epsfysize=3cm\\epsfbox{photo$photoid.eps}";
				}
				else {
					$photo = '\ ';
				}

				# for adults and animators add special right sign
				if ($person->animator || $person->adult) {
					$sign = '
						\vrule\vtop to 3.3cm{%
							\hsize 0.37cm%
							\leavevmode\vfill%
							\leftskip 0cm plus 1fill%
							\fmini%
							'. ($person->animator
								? 'A N\break I\break M\break Á T O R'
								: 'D O S P Ě L '.($person->a ? "Á" : "Ý")
							) .'
							\vfill%
						}%
					';
				}


				# cards are: 8.6x5.4cm with spacing 6mm and margin 1.6cm

				$print .=
					'\vrule\vbox to 5.4cm{
						\hsize 8.6cm
						\hrule
						\vskip 2mm
						\hbox to 8.6cm{
							\hfill
							\vbox to .6cm {%
								\hsize .9cm
								\vss
								\hbox to .6cm{\hss\epsfysize=.7cm\epsfbox{logo.eps}\hss}
								\vss
							}
							\hfill
							\vbox to .6cm {%
								\hsize 5.6cm
								\vfill
								\hfill\fheading PRŮKAZ ČLENA STŘEDISKA\hfill
								\vfill
							}
							\hfill
							\vbox to .6cm {%
								\baselineskip 8pt
								\hsize 1.2cm
								\vfill
								\hbox to 1.2cm{\hfill\fmini '. $card->glimpse("id") .'}\break
								\hbox to 1.2cm{\hfill\fmini '. (take Season $user->season)->name({ prrrint => 1 }) .'}%
								\vfill
							}
							\hfill
						}
						\vskip 2mm
						\hrule
						\hbox to 8.6cm{%
							\vtop to 3.6cm {
								\hsize 3cm
								\leftskip 3mm
								\ \vfill'. $photo .'\vfill}%
							\vtop{\hsize 5.2cm
								\vskip 3mm'.
								$person->glimpse('
									\baselineskip 10pt
									{{\fname {firstname}\vskip 1mm
									{surname}}}\vskip 3pt
									\em{{narozen'. $person->a .':}}\break birthdatelong
									\vskip 3pt
									\em{{bytem:}}\break address
								', { prrrint => "yes" }).'
							}%
							'. $sign .'
							\hfill
						}
						\hrule
						\baselineskip 8pt
						\leftskip 0pt plus 1fill
						\vskip 1mm
						\fmini Salesiánské středisko mládeže, Foerstrova 2, Brno-Žabovřesky

						www: brno.sdb.cz --- email: stredisko@brno.sdb.cz --- tel: 541 213 110\hfill
						\vfill
						\hrule
						}\vrule\hskip 6mm';
			}

			$print .= "\\hfil}\\vskip 6mm\n";
		}

		chdir $Conf::PrintDir;
		# export & convert photos
		for my $oid (@photoids) {
			$dbi->expooort($oid, "photo$oid.jpg");
			system "$Conf::PrintCommandConvert photo$oid.jpg photo$oid.eps";
		}

		# if printing is ok (and not making only temporary cards) -- set as printed
		if ($printer->prrrint($print) && !$temporary) {
			for my $cid (@cids8copy) {
				$dbi->exe("update cards set printed = '". $now->db_stamp ."'
						where id = $cid and printed is null");
			}
		}

		# remove photos
		for my $oid (@photoids) {
			system "rm photo$oid.*";
		}
	}
}


# print card backs
# ~~~~~~~~~~~~~~~~~
sub prrrint_back {
	my $print = "\\prukazky\n";

	for my $row (1..4) {
		$print .= '\hbox to 20cm{';

		for my $col (1..2) {
			$print .=
				'\vrule\vbox to 5.4cm{
					\hsize 8.6cm
					\leftskip 6.6mm
					\rightskip 6.6mm
					\hrule
					\vskip 5mm
					\vfill

					Držitel této průkazky má to štěstí být
					registrovaným členem střediska
					mládeže. S ní může vstupovat do
					střediska a také do vyhrazených
					místností (kulečník, posilovna),
					půjčovat si hry a sportovní potřeby a
					využívat dalších výhod.

					\vfill

					Průkazku využívá jen její držitel a
					zodpovídá za půjčenou věc, dokud ji
					v pořádku nevrátí.

					\vfill

					Držitel dodržuje
					Pravidla pro návštěvníky.

					\vfill
					\vskip 5mm
					\hrule
					}\vrule\hskip 6mm';
		}

		$print .= "\\hfil}\\vskip 6mm\n";
	}

	(take Printer $user->printer)->prrrint($print);

}


1

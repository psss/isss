package Inquisitor;

  #######################################################
 ####  Inquisitor  --  not only comfort selector  #####
#######################################################
#
#  used for comfortly accessing domains, categories,
#  and others, including making nice html <selects>
#
#  class methods: (constructors)
#  ~~~~~~~~~~~~~~
#  > new		inquisitor that takes (keys, values) as pars
#  > db			common constor for all `db' inquisitors
#
#  > role		role inquisitor
#  > season		season inquisitor
#  > printer		printer inquisitor
#  > category		category inquisitor
#  > room		room inquisitor
#  > day		day inquisitor
#
#  object data:
#  ~~~~~~~~~~~~
#  > hash		hash containing all values
#  > keys		keys in the order as we've got them
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > select		make html <select>
#  > multi		make html <select multi>
#  > radio		make html <input type=radio...>s
#
#  > name		returns name corresponding to an `id'

use strict;

use GlobDbi;
use Util;


# general constructor -- takes ids and names as pars
sub new {
	my $this = {};

	shift; # throw out package name

	my ($id, $name);
	while ($id = shift, defined ($name = shift)) {
		($id, $name) = uqq $id, $name;
		$this->{hash}->{$id} = $name;
		push @{$this->{keys}}, $id;
	}

	bless $this;
}


# common db constructor
sub db {
	my ($pack, $query) = @_;
	my $this = {};

	$dbi->exe($query);
	while (my ($id, $name) = $dbi->row) {
		($id, $name) = uqq $id, $name;
		$this->{hash}->{$id} = $name;
		push @{$this->{keys}}, $id;
	}

	bless $this;
}


# constructor for subjects
sub role {
	db Inquisitor "select id, name from roles order by id";
}


# constructor for subjects
sub season {
	db Inquisitor "select id, name from seasons order by id";
}


# constructor for subjects
sub printer {
	db Inquisitor "select id, name from printers order by id";
}


# costructor for selecting activity categories
sub category {
	db Inquisitor "select id, name from categories order by id";
}


# costructor for selecting activity fields
sub field {
	db Inquisitor "select id, id || ' - ' || name from fields order by id";
}

# insurance companies
sub insurance {
	db Inquisitor "select id, id || ' - ' || name from insurances order by id";
}

# short insurance companies
sub shortinsurance {
	db Inquisitor "select id, shortly from insurances order by id";
}

# costructor for selecting type
sub type {
	db Inquisitor "select id, name from types order by id";
}

# costructor for selecting activity categories
sub room {
	db Inquisitor "select id, name from rooms order by name";
}

# selecting animators
sub animator {
	db Inquisitor "select id, surname || ' ' || coalesce(name, '') from persons where animator order by surname, name";
}


# costructor for selecting sex
sub sex {
	new Inquisitor qw(m muž f žena);
}


# costructor for selecting sex
sub sex2 {
	new Inquisitor undef, "kluci i holky", qw(m kluci f holky);
}


# boolean selector
sub yesno {
	new Inquisitor qw(1 ano 0 ne);
}


# boolean selector
sub infomail {
	new Inquisitor qw(1 posílat 0 neposílat);
}


# constructor for cards
sub card {
	new Inquisitor (t => "kartičková", f => "nekartičková");
}


# costructor for selecting days of week
sub day {
	#new Inquisitor 0, " ", qw(1 po 2 út 3 st 4 čt 5 pá 6 so 0 ne);
	new Inquisitor qw(1 po 2 út 3 st 4 čt 5 pá 6 so 0 ne);
}


# costructor for selecting days of week
sub longday {
	new Inquisitor qw(1 pondělí 2 úterý 3 středa 4 čtvrtek 5 pátek 6 sobota 0 neděle);
}


# costructor for choosing if the activity is public
sub pub {
	new Inquisitor t => 'veřejná', f => 'interní';
}


# costructor for choosing if the activity is open
sub fixed {
	new Inquisitor f => 'poměrná', t => 'fixní';
}


# costructor for selecting price type
sub opened {
	new Inquisitor t => 'otevřená', f => 'zavřená';
}


# for inquisiting activities
sub activity {
	new Inquisitor
		name		=> 'název',
		lead		=> 'vede',
		leaders		=> 'vedoucí',
		age		=> 'věk',
		placement	=> 'rozvrh',
		placementshort	=> 'rozvržek',
		place		=> 'místo',
		price		=> 'cena',
		deposit		=> 'záloha',
		fixed		=> 'typ ceny',
		free		=> 'míst',
		count		=> 'členů',
		load		=> 'obsazeno',
		min		=> 'min',
		max		=> 'max',
		sex		=> 'pohlaví',
		start		=> 'zahájení',
		starts		=> 'začíná',
		finishes	=> 'končí',
		category	=> 'kategorie',
		field		=> 'obor',
		flags		=> 'příznaky',
		open		=> 'stav',
		card		=> 'kartičky',
		pub		=> 'zveřejnění',
		description	=> 'popis',
		condition	=> 'podmínka',
		details		=> 'podrobnosti',
		note		=> 'poznámka',
		members		=> 'členové';
}


# for inquisiting persons
sub person {
	new Inquisitor
		name		=> 'jméno',
		birthdate	=> 'narození',
		address		=> 'adresa',
		onetel		=> 'telefén',
		oneemail	=> 'email',

		firstname	=> 'křestní',
		surname		=> 'příjmení',
		father		=> 'otec',
		mother		=> 'matka',

		birthnumber	=> 'rodné číslo',
		birthdatelong	=> 'narození',

		phones		=> 'telefény',
		emails		=> 'emaily',
		infomail	=> 'infomail',
		onemobil	=> 'mobil',
		tel		=> 'pevná',

		street		=> 'ulice',
		town		=> 'město',
		zip		=> 'psč',

		age		=> 'věk',
		years		=> 'roků',

		insurance	=> 'pojišťovna',
		insnum		=> 'č. poj.',
		ins		=> 'poj.',

		photo		=> 'foto',
		miniphoto	=> 'minifoto',
		miminiphoto	=> 'milifoto',

		health		=> 'zdraví',
		hobbies		=> 'zájmy',
		note		=> 'poznámka',
		parents		=> 'rodiče',
		children	=> 'děti',

		activities	=> 'aktivity',
		leads		=> 'vede';
}




# takes id, returns corresponding name
sub name {
	my ($this, $which) = @_;
	$this->{hash}->{$which};
}


# makes html <select>
# <<  name -- tag name for <select>
# <<  selected -- selected item's id
# <<  all -- one more item -- used mainly for `antiitem' (nochoice)
sub select {
	my ($this, $name, $selected, $noitem, $opts, $noitemval) = @_;
	my $return;

	$this->{hash}->{$noitemval || 0} = $noitem if defined $noitem;

	$return .= "\n\n\t\t<select name=\"$name\" size=\"1\" $opts>";
	for ($noitem ? $noitemval || 0 : (), @{$this->{keys}}) {
		$return .= "\n\t\t\t<option value=\"$_\"" .
			($selected eq $_ ? " selected=\"selected\"" : "") .
			">$this->{hash}->{$_}</option>";
	}
	$return .= "\n\t\t</select>";
}

# makes html <select multi>
# <<  name -- tag name for <select>
# <<  selected -- selected item's id
# <<  all -- one more item -- used mainly for `antiitem' (nochoice)
sub multi {
	my ($this, $name, $par, @selected) = @_;
	my $return;

	$par->{noitemval} = 0 unless defined $par->{noitemval};
	$this->{hash}->{$par->{noitemval}} = $par->{noitem} if defined $par->{noitem};

	$return .= "\n\n\t\t<select name=\"$name\" size=\"$Conf::InputSelectSize\" multiple>";
	for my $i ($par->{noitem} ? $par->{noitemval} : (), @{$this->{keys}}) {
		$return .= "\n\t\t\t<option value=\"$i\"" .
			(grep(/^$i$/, @selected)? " selected=\"selected\"" : "") .
			">$this->{hash}->{$i}</option>";
	}
	$return .= "\n\t\t</select>";
}


# makes html <input type=radio...>s
# <<  name -- tag name for <input>
# <<  space -- what should be put between radio buttons
# <<  selected -- selected item's id
sub radio {
	my ($this, $name, $space, $selected) = @_;
	my $return;

	for my $i (@{$this->{keys}}) {
		$return .= "\n\t\t\t<label><input type=\"radio\" class=\"noborder\" name=\"$name\" value=\"$i\"" .
			($selected eq $i ? " checked=\"checked\"" : "") .
			"/>&nbsp;$this->{hash}->{$i}</label>$space";
	}
	$return;
}

1

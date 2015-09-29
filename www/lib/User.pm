package User;

  #######################################################
 ####  User -- handling user info & setup  #############
#######################################################
#
#  getting/setting names/logins/settings
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new user
#  > take		constructor (takes uid)
#  > log_in		constructor (takes login)
#  > delete		delete a user
#  > browse		browsing the users
#
#  object data:
#  ~~~~~~~~~~~~
#  > id			these are selfexplanatory
#  > login		.
#
#  > person		person id -- reference to user's details
#  > season		.
#  > printer		.
#  > role		.
#
#  > writable		true if current user can change user info
#  > me			true if it's me (current user)
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > admin		returns true if user is admin
#
#  > id 		get the id
#  > name		get user's name & surname
#  > login		get/set login
#
#  > season		get user's season id
#  > printer		get user's printer id
#
#  > glimpse		one <tr> info 'bout the user
#
#  > edit		make formular for editing
#  > update		update data from formular
#  > show		show user info
#
#  > save		save data into db

use locale;
use strict qw(subs vars);

use Log;
use Conf;
use Html;
use Ider;
use Util;
use Query;
use Cleaver;
use GlobDbi;
use Inquisitor;

my $seasoner = season Inquisitor;
my $roler = role Inquisitor;
my $printerer = printer Inquisitor;

my $current_user_login;
my $current_user_is_admin;

# create new user (empty)
# ~~~~~~~~~~~~~~~
sub create {
	my $this = {};
	bless $this;

	# insert into db
	$dbi->beg;
		# make implicit login
		$dbi->exe("select max(id) from users");
		$this->{login} = "newuser" . ($dbi->val + 1);

		# insert
		$dbi->exe("insert into users (login) values ('$this->{login}')");
		# find out id
		$dbi->exe("select currval('users_id_seq')");
		$this->{id} = $dbi->val;
	$dbi->end;

	# set the rest
	$this->{person} = undef;
	$this->{role} = 1;
	$this->{season} = 1;
	$this->{printer} = 1;

	$this->{writable} = 1;
	$this->{me} = 0;

	$this->save;

	$this;
}



# constructor for existing users
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  uid
sub take {
	my ($pack, $uid) = @_;
	fatal("take potřebuje číslo uživatele") unless $uid;

	my $this = {};

	$dbi->exe("select id, login, person, role, season, printer from users
			where id = '". uq($uid) ."'")
	or fatal("takový uživatel neexistuje");
	@$this{qw(id login person role season printer)} = $dbi->row;

	# write for admin and for self
	$this->{me} = $this->{login} eq $current_user_login;
	$this->{writable} = 1 if $this->{me} || $current_user_is_admin;

	bless $this;
}




# constructor for existing users
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  login, password
sub log_in {
	my ($pack, $login) = @_;
	my $this = {};
	bless $this;

	fatal "nepřihlášen!" unless $login;

	# unless we found login in db
	unless ($dbi->exe("select id, login, person, role, season, printer from users
			where login = '". uq($login) ."'")) {
		# return undef -- won't be validated
		logg "neexistující login ($login)";
		return undef;
	}

	# set data
	@$this{qw(id login person role season printer)} = $dbi->row;
	$this->{writable} = 1;
	$this->{me} = 1;

	# set current_user & admin flag
	$current_user_login = $login;
	$current_user_is_admin =
		$dbi->exe("select login from users where role = 0 and login='$login'");

	$this;
}


# deleting a user
# ~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nelze smazat sebe sama!"), return if $this->{me};
	error("nemáš právo mazat uživatele"), return unless $current_user_is_admin;

	if ($dbi->exe("delete from users where id = $this->{id}", "try")) {
		message("uživatel $this->{login} byl úspěšně smazán");
	}
	else {
		error ("uživatele nelze smazat");
	}
}


sub id {
	my $this = shift;

	$this->{id};
}


sub name {
	my $this = shift;

	return "nikdo" unless $this->{person};
	return unless $dbi->exe("select name, surname from persons where id = $this->{person}");
	join " ", $dbi->row;
}


sub admin {
	my $this = shift;

	# admin when in admin role -- id = 0
	$this->{role} == 0;
}



# get/set user's login
# ~~~~~~~~~~~~~~~~~~~~
# <<  ($login)  -- maybe new login
sub login {
	my ($this, $login) = @_;

	if (defined $login) {
		# make sure we can edit this user info
		error("login uživatele může měnit pouze správce"), return
			unless $current_user_is_admin;

		# we have to make sure there is no duplicate
		$dbi->exe("update users set login = '".uq($login)."' where id = $this->{id}", "try")
			or error("login $login již zřejmě existuje"), return undef;
		$this->{login} = $login;
		$this->save;
	}

	$this->{login};
}


# user setup -- printer & season settings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub setup {
        my $this = shift;

	if (defined ${"qp::user$this->{id}season"}) {
		# make sure we can edit this user
		error("nemáš právo měnit nastavení uživatele $this->{id}"), return
			unless $this->{writable};

		$this->{printer} = ck ${"qp::user$this->{id}printer"};
		$this->{season} = ck ${"qp::user$this->{id}season"};

		$this->save;
	}

	'<div>období:</div>
		<label accesskey="o">'.
			$seasoner->select("user$this->{id}season", $this->{season}, undef,
				'onchange="submit();" title="změnit aktuální období"').
		'</label>'.

	($this->can("prrrint") && '<div>tiskárna:</div>
	 	<label accesskey="t">'.
		$printerer->select("user$this->{id}printer", $this->{printer}, undef,
			'onchange="submit();" title="změnit aktivní tiskárnu"').
		'</label>'
	)
}


# get current user's season id
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub season {
	my $this = shift;
	# season number or "season" which in queries gives "season = season" alias all seasons
	$this->{season} || "season";
}


# get current user's printer id
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub printer {
	my $this = shift;
	$this->{printer};
}


# get person's id (reference to person details)
sub person {
	my $this = shift;
	$this->{person};
}


# priht something to users printer
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#sub prrrint {
#	my ($this, $text, $landscape) = @_;
#
#	$this->{printerer} = take Printer $this->{printer} unless $this->{printerer};
#	$this->{printerer}->prrrint($text, $landscape);
#}


# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit this user
        error("nemáš právo upravovat uživatele"), $this->show, return unless $current_user_is_admin;
	my %err;

        # update name
	if (defined ${"qp::u$this->{id}login"}) {
		# maybe change login
		my $login         =    ${"qp::u$this->{id}login"};
		$this->login($login) if $login ne $this->{login};

		$this->{person}   =  ${"qp::u$this->{id}person"};
		$this->{role}     =  ${"qp::u$this->{id}role"};
		$this->{season}   =  ${"qp::u$this->{id}season"};
		$this->{printer}  =  ${"qp::u$this->{id}printer"};

		$this->{person} = undef unless $this->{person};

		# and don't forget to save changes
		$this->save;
	}

	my $animatorer = animator Inquisitor;

	print tab(
		row(td(div($this->name, 'class="heading"'))).
		row(td(tab(
			row(
				th("login:").
				td("<input type=\"text\" name=\"u$this->{id}login\" value=\"".
						uqq($this->{login})."\" size=\"20\">")
			). row(
				th("človíček:").
				td($animatorer->select("u$this->{id}person", $this->{person}, " "))
			). row(
				th("role:").
				td($roler->select("u$this->{id}role", $this->{role}))
			). row(
				th("období:").
				td($seasoner->select("u$this->{id}season", $this->{season}))
			). row(
				th("tiskárna:").
				td($printerer->select("u$this->{id}printer", $this->{printer}))
			)
		)))
	, 'class="card"');

}


# show user info
# ~~~~~~~~~~~~~~
sub show {
	my $this = shift;
	print tab(row(td(
		"\n\n\t\t<div class=\"heading\">". $this->name ."</div>".
		tab(
			row(th("login:").td($this->{login})).
			row(th("role:").td($roler->name($this->{role}))).
			row(th("období:").td($seasoner->name($this->{season}))).
			row(th("tiskárna:").td($printerer->name($this->{printer})))
		, 'class="form"')
	)), 'class="card"');
}


# save changed data
# ~~~~~~~~~~~~~~~~~
sub save {
	my $this = shift;

	$dbi->exe(sprintf "update users set
			login     = '%s',
			role      = '%i',
			season    = '%i',
			printer   = '%i',
			person    =  %s
			where id = $this->{id}",
			uq(@$this{qw(login role season printer)}),
			qd($this->{person})
		);
}


# glimpse at the user in one <table> row
# ~~~~~~~
# <<  format -- string containing list of columns to be showed
#     (i)d  (n)ame  (l)ogin  checkbo(x)
#     (s)eason (p)rinter (r)ole
#     an `<' at the beginning means to include <tr>
#     an `>' at the end to include </tr>
# <<  ider -- ider to be used as name of checkbox
sub glimpse {
	my ($this, $format, $par) = @_;

	my %gl = (
		($par->{nohrefs} || !$current_user_is_admin
			? ( name	=> sub { $this->name })
			: ( name	=> sub { "<a href=\"$Conf::Url/uzivatele/uzivatele.pl?uids=$this->{id}\">". uqq($this->name) ."</a>" })
		),
		login	=> sub { $this->{login} },
		role	=> sub { $roler->name($this->{role}) },
		season	=> sub { $seasoner->name($this->{season}) },
		printer	=> sub { $printerer->name($this->{printer}) }
	);

	my $result;

	for my $scrap ($format =~ /(\w+|\\[\\\[\]{}#]|.)/gm) {
		$result .=  $gl{$scrap} ? &{$gl{$scrap}} : glimpsie($this, $scrap, $par);
	}

	$result;
}


# browsing users
# ~~~~~~~~~~~~~~~
sub browse {
	my ($pack, $par) = @_;

	my $sorter = new Inquisitor (
			0 => "jména",
			1 => "id",
			2 => "role"
	);

	my $ors;

	for my $word ($qp::search =~ /([\w\d]+)/g) {
		if ($word =~ /^\d+$/) {
			$ors .= " or id = $word"
		}
		else {
			$ors .= " or name ~* '$word' or surname ~* '$word'".
				" or login ~* '$word'";
		}
	}

	$ors = "where (1 = 0 $ors)" if $ors;
	my $cleaver = query Cleaver "select u.id
		from users u left outer join persons p on u.person = p.id $ors
		order by ". (("p.surname, p.name", "u.id", "u.role")[$qp::sort]);

	print tab(
		row(td(tab(row(
			th("setřídit:").
			td($sorter->select("sort", uqq $qp::sort)).
			th("na stránku:").
			td($cleaver->slice).
			td(input("search", uqq $qp::search)).
			td(submit "", "najít")
		)))). row(td(tab(row(
			td("nalezení uživatelé (" . $cleaver->info . ")", 'colspan="2"').
			td($cleaver->control, 'colspan="3"')
		))))
		, 'class="navig"');

	# make sure there is something
	print("\n\t\t\tnenalezen žádný uživatel<p>"), return if $cleaver->empty;
	print "\n\n</form><form name=\"form\" action=\"$par->{checkboxform}\" method=\"post\" enctype=\"multipart/form-data\"/>"
		if $par->{checkboxform};

	my $ider = new Ider "u";

	# start table
	print tab(undef, $Conf::TabScraps),
		row th(""). th("id"). th("jméno"). th("login").th("role").th("období").th("tiskárna");

	# glimpses
	while (my $uid = $cleaver->next) {
		my $u = take User $uid;
		print $u->glimpse("{[#][id][name][login][role][season][printer]}", { ider => $ider });
	}

	# finish table
	print row(td(checkall("u.*u.*u"), 'colspan="7" class="footer"')), tabb;

	# we have found something
	1
}

# 0 administrator
# 1 editor
# 2 register
# 3 viewer
# 4 info
# 5 guest

sub can {
	my ($this, $what) = @_;

	{
		do_system_stuff		=> $this->{role} <= $Conf::Roles{admin},
		edit_users 		=> $this->{role} <= $Conf::Roles{admin},
		edit_seasons 		=> $this->{role} <= $Conf::Roles{admin},
		edit_printers		=> $this->{role} <= $Conf::Roles{admin},
		edit_setup		=> $this->{role} <= $Conf::Roles{admin},
		cancel_cards		=> $this->{role} <= $Conf::Roles{admin},
		cancel_payments		=> $this->{role} <= $Conf::Roles{admin},

		edit_rooms 		=> $this->{role} <= $Conf::Roles{editor},
		edit_activities		=> $this->{role} <= $Conf::Roles{editor},
		edit_placed		=> $this->{role} <= $Conf::Roles{editor},
		edit_lead		=> $this->{role} <= $Conf::Roles{editor},
		prrrint_cards		=> $this->{role} <= $Conf::Roles{editor},
		browse_payments		=> $this->{role} <= $Conf::Roles{editor},
		send_sms		=> $this->{role} <= $Conf::Roles{editor},
		make_reservations	=> $this->{role} <= $Conf::Roles{editor},

	 	edit_persons		=> $this->{role} <= $Conf::Roles{register},
		browse_registrations	=> $this->{role} <= $Conf::Roles{register},
		edit_registrations	=> $this->{role} <= $Conf::Roles{register},
		add_cards		=> $this->{role} <= $Conf::Roles{register},
		prrrint_tmp_cards	=> $this->{role} <= $Conf::Roles{register},
		send_email		=> $this->{role} <= $Conf::Roles{register},
		send_messages		=> $this->{role} <= $Conf::Roles{register},

		view_payments		=> $this->{role} <= $Conf::Roles{viewer},
		view_cards		=> $this->{role} <= $Conf::Roles{viewer},
		view_person_details	=> $this->{role} <= $Conf::Roles{viewer},
		prrrint			=> $this->{role} <= $Conf::Roles{viewer},
		view_stats		=> $this->{role} <= $Conf::Roles{viewer},
		view_registrations	=> $this->{role} <= $Conf::Roles{viewer},

		view_rooms		=> $this->{role} <= $Conf::Roles{info},
		view_persons		=> $this->{role} <= $Conf::Roles{info},
		view_schedule		=> $this->{role} <= $Conf::Roles{info},
		view_members		=> $this->{role} <= $Conf::Roles{info},
		browse_persons		=> $this->{role} <= $Conf::Roles{info},
		browse_rooms		=> $this->{role} <= $Conf::Roles{info},

		view_activities		=> $this->{role} <= $Conf::Roles{guest},
		browse_activities	=> $this->{role} <= $Conf::Roles{guest}
	}->{$what};
}


1

package Season;

  #######################################################
 ####  Season -- handling seasons  #####################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create
#  > take
#  > delete
#
#  object data:
#  ~~~~~~~~~~~~
#  > id
#  > name
#  > start
#  > finish
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > start
#  > finish

use strict qw(subs vars);

use GlobDbi;
use GlobUser;


#  create new season
# ~~~~~~~~~~~~~~~~~~~~
sub create {
	error("nemáš právo vytvářet období"), return unless $user && $user->can("edit_seasons");

	# insert into db
	$dbi->beg;
		$dbi->exe("select max(id) from seasons");
		my $id = $dbi->val + 1;
		$dbi->exe("insert into seasons (id) values ($id)");
	$dbi->end;

	take Season $id;
}



# constructor for existing seasons
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $sid) = @_;
	return undef unless defined $sid;

	my $this = {};

	$sid = 0 if $sid eq "season";

	$dbi->exe("select id, name, start, finish from seasons where id = $sid")
		or fatal("takové období neexistuje ($sid)");
	@$this{qw(id name start finish)} = $dbi->row;

	$this->{start} = db_date Time $this->{start};
	$this->{finish} = db_date Time $this->{finish};

	bless $this;
}



# deleting a season
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat období"), return unless $user && $user->can("edit_seasons");
	$dbi->exe("delete from seasons where id = $this->{id}");
}


sub start {
	my $this = shift;

	$this->{start};
}


sub finish {
	my $this = shift;

	$this->{finish};
}


sub name {
	my ($this, $par) = @_;

	my $name = $this->{name};
	$name =~ s/-/--/ if $par->{prrrint};
	$name;
}



1

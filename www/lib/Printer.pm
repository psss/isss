package Printer;

  #######################################################
 ####  Printer -- handling printers  ###################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create
#  > take
#
#  object data:
#  ~~~~~~~~~~~~
#  > id
#  > name
#  > command
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > start
#  > finish
#  > delete

use strict qw(subs vars);

use Aid;


#  create new printer
# ~~~~~~~~~~~~~~~~~~~~
sub create {
	error("nemáš právo vytvářet tiskárny"), return unless $user->can("edit_printers");

	# insert into db
	$dbi->beg;
		$dbi->exe("select max(id) from printers");
		my $id = $dbi->val + 1;
		$dbi->exe("insert into printers (id) values ($id)");
	$dbi->end;

	take Printer $id;
}



# constructor for existing printers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $pid) = @_;
	return undef unless defined $pid;

	my $this = {};

	$dbi->exe("select id, name, command from printers where id = $pid")
		or fatal("taková tiskárna neexistuje ($pid)");
	@$this{qw(id name command)} = $dbi->row;

	bless $this;
}



# deleting a printer
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat tiskárny"), return unless $user->can("edit_printers");
	$dbi->exe("delete from printers where id = $this->{id}")
		or error "tiskárnu nelze smazat -- někdo ji používá";
}


# get printer's name
# ~~~~~~~~~~~~~~~~~~~
sub name {
	my $this = shift;

	$this->{name};
}


# get printer's command
# ~~~~~~~~~~~~~~~~~~~~~~
sub command {
	my $this = shift;

	$this->{command};
}


# print data
# ~~~~~~~~~~
sub prrrint {
	my ($this, $text, $landscape) = @_;

	# if printer is empty -- we're done
	return "ok" unless $this->{command};

	chdir $Conf::PrintDir;

	my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
	my $filename = join '', map { $chars[int rand @chars] } (1..8);
	#$filename = "hu";

	open file, ">$filename.tex"
		or error("nepodařilo se otevřít soubor pro tisk..."), return undef;

	print file "\\input isss.sty\n";
	print file $text;
	print file '\bye';
	close file;

	system "$Conf::PrintCommandTex $filename >>$Conf::PrintLog 2>>$Conf::PrintLog";
	system (($landscape ? $Conf::PrintCommandDvipsLandscape : $Conf::PrintCommandDvips).
			" -f $filename 2>>$Conf::PrintLog ".
			# because of CUPS
			"| sed 's/Orientation: Landscape/Orientation: Portrait/' ".
			"| $this->{command}");

	system "rm -f $filename.*";

	"ok";
}


1

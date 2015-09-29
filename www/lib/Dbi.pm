package Dbi;

  #######################################################
 ####  Dbi -- comfortable database interface  ##########
#######################################################
#
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > new		constructor
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > opendb		connect to db
#  > exe		execute db query, return result
#  > row		return one result row
#  > val		return value -- making sure it's really one and the only
#  > vals		return all values -- assumes's one column result only
#
#  > beg		begin transaction
#  > end		end transaction
#
#  > save		save file into db
#  > cat		get contents of specified saved file
#  > rm			remove file from db
#
#  > random		get random row of a select

use strict;

use Pg;
use Log;
use Query;


# constructor
# ~~~~~~~~~~~
sub new {
	my $this = {};
	#?$this->{connection} = undef;
	#?$this->{result} = undef;
	bless $this;
}


# connect to db
# ~~~~~~~~~~~~~
sub opendb {
	my $this = shift;

	$this->{connection} = Pg::connectdb($Conf::DbInfo);
	if ($this->{connection}->status != PGRES_CONNECTION_OK) {
		&fatal($this->{connection}->errorMessage);
	}
	#logg("connect");
	$this->{connection}->exec("SET client_encoding TO 'latin2';");
	return $this->{connection};
}


# check if the connection is ok
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub check {
	my $this = shift;

	unless ($this->{connection}) {
		$this->opendb;
	}
	#!! not very nice to reset every time!! but how?
#	else {
#		$this->{connection}->reset;
#		unless ($this->{connection}->status == PGRES_CONNECTION_OK) {
#			&fatal($this->{connection}->errorMessage);
#		}
#	}

}





# execute query
# ~~~~~~~~~~~~~
# <<  $query - query to be executed
# <<  $try -- do not panic, when there's an error
# >>  number of result rows when SELECTing
# >>  command status otherwise
sub exe {
	my ($this, $query, $try) = @_;
	#&error("podivný dotaz"), return 0 unless $query;
	#&logg("QUERY: >>$query<<");

	$this->check;
	$this->{result} = $this->{connection}->exec($query);

	# if fatal error, try once to reconnect db
	if ($this->{result}->resultStatus == PGRES_FATAL_ERROR) {
		$this->{connection}->reset;
		$this->{result} = $this->{connection}->exec($query);
	}

	my $selecting = $query =~ /^\s*select/i;

	unless ($this->{result}->resultStatus == ($selecting ? PGRES_TUPLES_OK : PGRES_COMMAND_OK)) {
		if ($try) {
			&logg ("[try] " . $query . ": " . $this->{connection}->errorMessage);
			return undef;
		}
		&fatal ($query . ": " . $this->{connection}->errorMessage);
	}

	return $this->{result}->ntuples if $selecting;
	return $this->{result}->cmdStatus;
}


# return one result row
# ~~~~~~~~~~~~~~~~~~~~~
sub row {
	my $this = shift;

	#?&error("žádný dotaz néní...") unless $this->{result};
	$this->{result}->fetchrow;
}



# return the only result value
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub val {
	my $this = shift;

	#?&error("žádný dotaz néní...") unless $this->{result};
	&error("výsledek nebyla jediná hodnota")
		if ($this->{result}->ntuples != 1 || $this->{result}->nfields != 1);

	($this->{result}->fetchrow)[0];
}


# return all values of the result
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub vals {
	my $this = shift;

	#?&error("žádný dotaz néní...") unless $this->{result};
	#&error("výsledek nebyl jediný sloupec") if $this->{result}->nfields != 1;
	my @vals;
	while (my @row = $this->{result}->fetchrow) {
		push @vals, @row;
	}
	@vals;
}


# start transaction
# ~~~~~~~~~~~~~~~~~
sub beg {
	my $this = shift;
	$this->exe("begin");
}


# commit transaction
# ~~~~~~~~~~~~~~~~~~
sub end {
	my $this = shift;
	$this->exe("end");
}


# remove file from db
# ~~~~~~~~~~~~~~~~~~~
sub rm {
	my ($this, $oid) = @_;

	$this->check;
	$this->beg;

	error "soubor ($oid) se nepodařilo smazat"
		if $this->{connection}->lo_unlink($oid) == -1;

	$this->end;
}


# save a file into db
# ~~~~~~~~~~~~~~~~~~~~
sub save {
	my ($this, $name, $oldoid) = @_;

	$this->check;
	$this->beg;
		my $oid = $this->{connection}->lo_creat(PGRES_INV_WRITE);
		my $dbfd = $this->{connection}->lo_open($oid, PGRES_INV_WRITE | PGRES_INV_SMGRMASK);
		fatal "nepodařilo se otevřít soubor v databázi" if $dbfd == -1;

		# get the fd for the file
		my $fd = qpfile($name);

		# and copyyy!
		my ($buff, $chars, $total);
		while ($chars = read($fd, $buff, 1024)) {
			$this->{connection}->lo_write($dbfd, $buff, $chars);
			$total += $chars;
		}

		$this->{connection}->lo_close($dbfd);

		# if the file was empty then -- remove it
		unless ($total) {
			#error("prázdný soubor");
			$this->rm($oid);
			return undef;
		}
	$this->end;

	# if everything is ok and we got the old oid -- delete old large object
	$this->rm($oldoid) if $oldoid;

	$oid;
}


# import files into db
# ~~~~~~~~~~~~~~~~~~~~~
sub impooort {
	my ($this, $file) = @_;

	$this->check;
	$this->beg;
		my $loid = $this->{connection}->lo_import($file);
	$this->end;

	$loid;
}


# export files from db
# ~~~~~~~~~~~~~~~~~~~~~
sub expooort {
	my ($this, $oid, $file) = @_;

	$this->check;
	$this->beg;
		my $result = $this->{connection}->lo_export($oid, $file);
	$this->end;

	$result != -1;
}


# get contents of specified saved file
# ~~~~~~~~~~~~~~~~~~~~
sub cat {
	my ($this, $oid) = @_;

	$this->check;
	$this->beg;

	my $fd = $this->{connection}->lo_open($oid, PGRES_INV_READ);
	logg("soubor ($oid) neexistuje"), return undef if $fd == -1;

	my $buff;
	while($this->{connection}->lo_read($fd, $buff, 1024)) {
		print $buff;
	}
	$this->{connection}->lo_close($fd);

	$this->end;

	1
}


# return random row of a select
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub random {
	my ($this, $select) = @_;

	$this->exe("$select offset ". int rand $this->exe($select) ." limit 1");
	$this->row;
}

1

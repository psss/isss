package Cleaver;

  #######################################################
 ####  Cleaver -- splitter of long listings  ###########
#######################################################
#
#  used for splitting long listings into small
#  pieces
#
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > array		constructor for arrays
#  > query		constructor for queries
#
#  object data:
#  ~~~~~~~~~~~~
#  > thickness		maximal length of per page listing
#  > slice		which slice shall we cut now? (starting at 1)
#  > loaf		which loaf shall we cut from? (when there are too many items)
#
#  > querying		for distinguishing array/query cleavers
#  > total 		total count of rows/items
#
#  > slices		number of slices we can cut out of $total
#  > loafs		number of loafs we can cut out of $total
#  > offset		first row/item of slice calculated from $thickness & $slice
#  > last		last row/item of current slice
#  > firstslice		first slice showed as button on current screen
#  > lastslice		last slice
#  > slicesizes		array of slices' sizes to choose from
#
#  > db/array		query/array to be returned by next
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > set		set vars from qpars (internal)
#  > next		get next item
#  > control		make control buttons
#  > slice		make slice size selector
#  > info		return small info string (`1 -- 20 z 58')
#  > empty		returns true if there is no item
#
#  ##! are less efficient but clear variants (not clashing db access)
#  ##? are clashing variants

use strict;

use Dbi;
use Conf;
use Html;
use Query;
use Inquisitor;


# set & calculate other data from qpars or defaults
# ~~~~~~~~~~~~~~~~~~~~~~~~~~
sub set {
	my $this = shift;

	# these two indicate whether < > << >> were used
	my ($slicestep, $loafstep);

	# unless slices' sizes are defined set them to default
	$this->{slicesizes} = [
			#-1 => "všechny",
			#2  => 2,
			10  => 10,
			20  => 20,
			50  => 50,
			100 => 100,
			1000 => 1000,
			10000 => 10000
		] unless $this->{slicesizes};

	# thickness (either explicitly set or 2nd value from slicesizes or default)
	$this->{thickness} = abs($qp::cleaverthickness) || $this->{slicesizes}->[2] || $Conf::SliceThickness;

	# current slice
	if ($qp::cleaverslice =~ /<|>/) {
		$this->{slice} = $qp::cleaverlastslice + ($qp::cleaverslice eq "<" ? -1 : 1);
		$slicestep = 1;
	}
	else {
		$this->{slice} = $qp::cleaverslice || $qp::cleaverlastslice || 1;
	}

	# total number of slices
	$this->{slices} = int(($this->{total} - 1) / $this->{thickness} + 1);
	# check range of slice
	$this->{slice} = 1 if $this->{slice} > $this->{slices} or $this->{slice} < 1;

	# current loaf
	if ($qp::cleaverloaf =~ /<<|>>/) {
		$this->{loaf} = $qp::cleaverlastloaf + ($qp::cleaverloaf eq "<<" ? -1 : 1);
		$loafstep = 1;
	}
	else {
		$this->{loaf} = $qp::cleaverlastloaf || 1;
	}

	# total number of loafs
	$this->{loafs} = int(($this->{slices} - 1) / $Conf::SlicesInOneLoaf + 1);
	# check range of loaf
	$this->{loaf} = 1 if $this->{loaf} > $this->{loafs} or $this->{loaf} < 1;

	# where do slices start and end?
	# taking care of jumping across loafs and slices
	do {
		$this->{firstslice} = ($this->{loaf} - 1) * $Conf::SlicesInOneLoaf + 1;
		$this->{lastslice} = $this->{firstslice} + $Conf::SlicesInOneLoaf - 1;
		$this->{lastslice} = $this->{slices} if $this->{lastslice} > $this->{slices};
	} while do {
		if ($slicestep and ($this->{slice} < $this->{firstslice}
				or $this->{slice} > $this->{lastslice})) {
			$this->{loaf} = int(($this->{slice} - 1) / $Conf::SlicesInOneLoaf + 1);
			1;
		}
	};

	# make sure the loafstep haven't jumped out of the range
	# if so, set current slice as first slice in loaf
	$this->{slice} = $this->{firstslice} if $loafstep;


	# offset
	$this->{offset} = ($this->{slice} - 1) * $this->{thickness};

	# last item
	$this->{last} = $this->{offset} + $this->{thickness};
	$this->{last} = $this->{total} if $this->{last} > $this->{total};
}


# constructor for arrays
# ~~~~~~~~~~~~~~~~~~~~~~
# <<  @array - items to be sliced
sub array {
	my ($pack, @array) = @_;

	my $this = {};
	bless $this;

	# set values
	#$this->{querying} = 0;
	$this->{total} = @array;

	# set slice thickness & slice from qpars
	$this->set;

	# cut only what we want to see
	$this->{array} = [ @array[$this->{offset} .. $this->{offset} + $this->{thickness} - 1 ] ];

	$this;
}


# constructor for queries
# ~~~~~~~~~~~~~~~~~~~~~~~
# <<  $query - query to be sliced
sub query {
	my ($pack, $query, $slicesizes) = @_;

	my $this = {};
	bless $this;

	# make our private connection to db
	# (not to clash with the others -- well, maybe it's not necessary)
	$this->{db} = new Dbi;

	# find out total
	#my $count = $query;
	#$count =~ s/select.*?from/select count(*) from/si;
	#$count =~ s/order by.*//si;
	#$this->{db}->exe($count);
	#$this->{total} = $this->{db}->val;
	$this->{total} = $this->{db}->exe($query);

	# maybe set sizes of slices
	$this->{slicesizes} = $slicesizes;

	# set & calculate other data
	$this->set;

	# make limited query (unless slice == 0 ~ everything)
	$this->{db}->exe("$query limit $this->{thickness} offset $this->{offset}");

	# we are querying
	$this->{querying} = 1;

	$this;
}


# get next item/db row
# ~~~~~~~~
sub next {
	my $this = shift;

	$this->{querying} ? $this->{db}->row : shift @{$this->{array}};
}


# make slice size selector
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub slice {
	my $this = shift;
	my $return = "";

	# slice select
	my $slicer = new Inquisitor @{$this->{slicesizes}};

	$return .= $slicer->select("cleaverthickness", $this->{thickness},
			undef);
			#undef, 'onchange="submit();"');
}



# make control buttons
# ~~~~~~~~~~~~~~~~~~~~
sub control {
	my $this = shift;
	my $return = '<span class="cleaver">';

	# which buttons
	if ($this->{total} > $this->{thickness}) {
		$return .= submit "cleaverloaf", "&lt;&lt;" if $this->{loaf} > 1;
		$return .= submit "cleaverslice", "&lt;" if $this->{slice} > 1;
		for ($this->{firstslice} .. $this->{lastslice}) {
			if ($_ == $this->{slice}) {
				$return .= "\n\t\t$_";
			}
			else {
				$return .= submit "cleaverslice", $_;
			}
			#$return .= "<input type=radio name=cleaverslice value=$_" .
				#($_ == $this->{slice} ? " disabled" : "") . ">";
		}
		$return .= submit "cleaverslice", "&gt;" if $this->{slice} < $this->{slices};
		$return .= submit "cleaverloaf", "&gt;&gt;" if $this->{loaf} < $this->{loafs};
		#$return .= "<input type=\"image\" src=\"$Conf::Pics/next.jpg\" name=\"cleaverslice\" value=\"&gt;\" border=0 alt=\"&gt;\">";
	}

	# hide current slice
	$return .= hide "cleaverlastslice", $this->{slice};
	$return .= hide "cleaverlastloaf", $this->{loaf};

	$return. '</span>';
}


# info -- return slice info
# ~~~~
sub info {
	my $this = shift;

	return 0 if $this->empty;
	$this->{offset} + 1 . "-$this->{last} z $this->{total}";
}


# empty -- return true if there is nothing
# ~~~~~
sub empty {
	my $this = shift;

	$this->{total} == 0;
}


# total -- return total number of rows
# ~~~~~~
sub total {
	my $this = shift;

	$this->{total};
}


1

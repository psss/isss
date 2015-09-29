package Ider;

  #######################################################
 ####  Ider -- generating ids  #########################
#######################################################

use strict;

use Log;

# constructor
# -----------------------------------------------------
# args: character that is to be used as delimiter
sub new {
	my ($pack, $char) = @_;
	fatal "jaký oddělovač?" unless $char;

	my $this = {};
	$this->{seq} = 0;
	$this->{delim} = $char;

	bless $this;
}


# return next id with proper sequence and delimiters
sub next {
	my ($this, $id) = @_;
	fatal "ider: chce to id!" unless $id;

	sprintf "$this->{delim}%04i$this->{delim}$id$this->{delim}", $this->{seq}++;
}

1;

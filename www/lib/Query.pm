package Query;

  #######################################################
 ####  Query -- preparing qpars for the others  ########
#######################################################
#
#

use strict qw(subs vars);

use CGI::Fast;
use Log;
use Util;

my $query = undef;

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(
			&qp &qpars &qpfile &qplist &ids &new
		);
}


sub new {
	# delete old qpars
	#$query->delete_all() if $query;
	#map { delete $qp::{$_} } keys %qp::;
	map { ${"qp::$_"} = undef } keys %qp::;
	#%qp:: = ();
	# prepare nice environment for others
	$query = new CGI::Fast;
	#return undef unless defined $query;
	return undef unless $query;

	$query->import_names('qp');
	1;
}


sub qpars {
	$query->param;
}


# used for multivalues
sub qp {
	my $name = shift;

	my @ar = $query->param($name);
}

# return filedescription of uploaded file
sub qpfile {
	my $name = shift;

	my $fd = $query->upload($name);
	fatal "nahrávaný soubor '$name' se nepodařilo otevřít" unless $fd;

	$fd;
}


# list all qpars
sub qplist {
	my $text;

	for my $key (keys %qp::) {
		$text .= "<br/>$key: ". ${"qp::$key"};
	}
	$text;
}


# find out all id's we got as qpars
# (used for checkboxes -- ids look like: q001q15q=on q002q43q=on)
# (but first we look for qpar $qp::qids)
# (the first number is used to get them in the right order)
sub ids {
	# what char is to be used as delimiter?
	my $q = shift;

	# first look for $qp::qids
	if (my @ids = split /\./, ${"qp::${q}ids"}) {
		return grep {defined $_} ck @ids;
	}

	# then for q001q15q=on ...
	#ck ((map {s/($q)\d+\1(\d+)\1/$2/; $_;} sort grep /($q)\d+\1\d+\1/, keys %qp::),
	#grep {defined $_} ck (map {s/($q)\d+\1//; split /$q/} sort grep /($q)\d+\1\d+\1/, keys %qp::);
	#grep {defined $_} ck (map {s/($q)\d+\1//; split /$q/} sort
		#grep { defined ${"qp::$_"} } grep /($q)\d+\1\d+\1/, keys %qp::);
	map {s/($q)\d+\1//; split /$q/} sort grep { defined ${"qp::$_"} } grep /($q)\d+\1\d+\1/, keys %qp::;
}

1

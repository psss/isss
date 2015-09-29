package Util;

  #######################################################
 ####  Util -- useful comfortable gadgets  #############
#######################################################
#
#  few very useful gadgets
#

use strict qw(vars subs);

use Log;
use CGI;
use Conf;
use Encode qw(from_to);


BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(
			&uq &qd &uqq &off &ff &uff &ck
			&infl &ymd &hack &kcah &permute &scrap
			&parse_birth &glimpsie &speak &uniq &uniqs &uniqss
			&urrrl &ascii &encode &mimeq
		);
}

#  double all 's for SQL queries
sub uq {
	my @args = @_;
	for (@args) {
		s/'/''/g;
		s/\\/\\\\/g;
	}

	return $args[0] if @args == 1;
	@args;
}


# quote date / quote digits
# > '2007-07-07' or '7' or null if undef
sub qd {
	my @args = @_;
	for (@args) {
		unless (defined $_) {
			$_ = 'null';
		}
		else {
			$_ = "'$_'";
		}
	}

	return $args[0] if @args == 1;
	@args;
}


# and this one used for html specials
sub uqq {
	my @args = @_;
	for (@args) {
		s/&(?!\w+;)/&amp;/g;
		s/"/&quot;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
	}

	return $args[0] if @args == 1;
	@args;
}


# only fine formatting -- no unquoting...
sub off  {
	my @args = @_;
	for (@args) {
		s/\n\s*\n/\n\n<p>/g;		# paragraph insted of empty line
		#s/\n/<br>/g;			# br instead of new line???
		s/~/&nbsp;/g;			# non breaking space
		s|(?<!\\)___(.*?)(?<!\\)___|<u>$1</u>|sg;	# underline
		s|(?<!\\)__(.*?)(?<!\\)__|<i>$1</i>|sg;		# italics
		s|(?<!\\)_(.*?)(?<!\\)_|<b>$1</b>|sg;		# bold
		#s|---|<img src="$Conf::Url/pics/emdash.jpg" align="absmiddle" alt="---">|g;
		#s|(?<!-)--(?!-)|<img src="$Conf::Url/pics/endash.jpg" align="absmiddle" alt="--">|g;
		s|(?<!\\)\\||sg;			# turn \\ into single \

	}
	return $args[0] if @args == 1;
	@args;
}


# make fine formatting for the users
sub ff {
	return off uqq @_;
}

# unfineformatting
sub uff {
	my @args = @_;
	for (@args) {
		s/~/ /g;				# non breaking space
		s|(?<!\\)___(.*?)(?<!\\)___|$1|sg;	# underline
		s|(?<!\\)__(.*?)(?<!\\)__|$1|sg;	# italics
		s|(?<!\\)_(.*?)(?<!\\)_|$1|sg;		# bold
		s|(?<!\\)\\||sg;			# turn \\ into single \
	}
	return $args[0] if @args == 1;
	@args;
}


# check number
# ~~~~~~~~~~~~
# << (num, num, num,..., text)
sub ck {
	my @args = @_;
	for (@args) {
		unless (/^\s*-?\d+\s*$/) {
			#logg("podivné číslo! >>$_<<");
			return undef;
		}
	}
	return $args[0] if @args == 1;
	@args;
}


# cut string to suitable size -- used for showing scraps
sub scrap {
	my $str = shift;

	if (length($str) > $Conf::ScrapSize) {
		$str = substr $str, 0, $Conf::ScrapSize;
		$str =~ s/\s+\w*$//;
		$str .= "..."
	}
	$str;
}


# inflecting czech language
sub infl {
	my ($count, $one, $four, $more, $two) = @_;

	return $two if $two && $count == 2;
	return ($more || $four) if $count < 1 or $count > 4;
	return $four if $count > 1;
	return $one;
}


# translate postgres' intervals into czech
sub ymd {
	$_ = shift;
	my ($yea) = /(\d+) year/;
	my ($mon) = /(\d+) mon/;
	my ($day) = /(\d+) day/;
	my ($minus) = /^(-)/;
	$yea = "$yea " . infl($yea, "rok", "roky", "roků") if $yea;
	$mon = "$mon " . infl($mon, "měsíc", "měsíce", "měsíců") if $mon;
	$day = "$day " . infl($day, "den", "dny", "dnů") if $day;

	return undef unless $yea || $mon || $day;
	$minus . join ', ', grep {$_} ($yea, $mon, $day);
}


# standard hacking text into pieces
sub hack {
	my $what = shift;
	# huge spaces into single space
	$what =~ s/\s+/ /g;
	# remove trailing spaces
	$what =~ s/^\s*//;
	$what =~ s/\s*$//;

	# / or | as separator?
	my $sep = $what =~ /(?<!\\)\|/ ? '\|' : '\/';
	grep {s/\\\//\//g; s/\\\|/|/g; /\w+/} split m/ *(?<!\\)$sep */, $what;
}


# unhack -- join with |'s
sub kcah {
	join " | ", @_;
}


# random permutation
sub permute {
	my @arr = @_;

	for (1..10) {
		push @arr, splice @arr, int rand @arr, 1;
	}

	@arr;
}

# parse and check birth number
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <  birthnumber
# >  date of birth and sex (m|f|n): ("7. 7. 2007", "m")
# >  undef if the number is not correct
sub parse_birth {
	my $number = shift;

	my ($yea, $mon, $day, $num, $sex);

	if (($yea, $mon, $day, $num) = $number =~ /\s*(\d\d)(\d\d)(\d\d)(\d\d\d\d)\s*/) {
		return undef unless $number % 11 == 0;
		if ($yea >= 54 ) {
			$yea += 1900;
		}
		else  {
			$yea += 2000;
		}
	}
	elsif (($yea, $mon, $day, $num) = $number =~ /\s*(\d\d)(\d\d)(\d\d)(\d\d\d)\s*/) {
		return undef if $yea >= 54;
		$yea += 1900;
	}
	else {
		return undef;
	}

	if ($mon > 12) {
		$mon -= 50;
		$sex = 'f';
	}
	else {
		$sex = 'm';
	}

	(sprintf("%i. %i. %i", $day, $mon, $yea), $sex);
}


# default glimpse behaving
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub glimpsie {
	my ($this, $scrap, $par) = @_;

	my %gl = (
		 id	=> sub { $this->{id} },
		 ($par->{prrrint} # if printing -- no specials
			? ()
		  	: (
				'#'	=> sub { return undef unless $par->{ider};
							"<input class=\"noborder\" type=\"checkbox\" name=\"".
							$par->{ider}->next($this->{id})."\" value=\"yes\"/>"},
				'['	=> sub { "\n\t\t\t<td>" },
				']'	=> sub { "</td>" },
				'{'	=> sub { "\n\t\t<tr>" },
				'}'	=> sub { "\n\t\t</tr>" },
				'\#'	=> sub { "#" },
				'\['	=> sub { "[" },
				'\]'	=> sub { "]" },
				'\{'	=> sub { "{" },
				'\}'	=> sub { "}" },
				'\\\\'	=> sub { '\\' }
			)
		)
	);

	$gl{$scrap} ? &{$gl{$scrap}} : $scrap;
}


# convert numbers into words
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub speak {
	my $number = shift;
	$number =~ s/\..*//;

	return "ani jedna koruna česká :-)" if $number == 0;

	my @words = (
		[ "", qw(jedna dvě tři čtyři pět šest sedm osm devět deset jedenáct dvanáct třináct čtrnáct patnách šestnáct sedmnáct osmnáct devatenáct)],
		[ "", qw(deset dvacet třicet čtyřicet padesát šedesát sedmdesát osmdesát devadesát)],
		[ "", qw(sto dvě_stě tři_sta čtyři_sta pět_set šest_set sedm_set osm_set devět_set)],
		[ "", qw(jeden dva tři čtyři pět šest sedm osm devět deset jedenáct dvanáct třináct čtrnáct patnách šestnáct sedmnáct osmnáct devatenáct)],
	);

	my @words2 = (
			[ "koruna česká", "koruny české", "korun českých" ],
			[ "tisíc", "tisíce", "tisíc" ],
			[ "milión", "milióny", "milónů" ],
			[ "miliarda", "miliardy", "miliard" ],
			[ "bilión", "bilióny", "biliónů" ],
			[ "biliarda", "biliardy", "biliard" ]
	);

	$words[4] = $words[7] = $words[10] = $words[13] = $words[16] = $words[1];
	$words[5] = $words[8] = $words[11] = $words[14] = $words[17] = $words[2];
	$words[6] = $words[12] = $words[3];
	$words[9] = $words[15] = $words[0];

	my @return;
	my @digits = reverse $number =~ /(\d)/g;
	return undef if $#digits > 17;

	for my $digit (0 .. $#digits) {
		# put thousands, milions...
		if ($digit % 3 == 0 && ($digits[$digit] || $digits[$digit+1] || $digits[$digit+2] || ($digit == 0 && $number != 0))) {
			push @return, infl(($digits[$digit+1] == 1).$digits[$digit], @{$words2[$digit/3]});
		}
		# put single digit (and eleven, twelve...)
		if ($digit % 3 == 0 && $digits[$digit+1] == 1) {
			push @return, $words[$digit]["1".$digits[$digit]];
		}
		# single digit (but not teens...)
		elsif ($digit % 3 != 1 || $digits[$digit] != 1) {
			push @return, $words[$digit][$digits[$digit]];
		}
	}
	my $result = join ' ', grep {$_} reverse @return;
	$result =~ s/_/ /g;
	$result;
}

# escape url-dangerous characters
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub urrrl {
	my $what = shift;

	from_to($what, "iso-8859-2", "utf-8");
	$what = CGI::escape($what);
	#s/([^\w\-\.\@])/$1 eq " "?"+":sprintf("%%%2.2x",ord($1))/eg;
	#s/([^\w()'*~!.-])/sprintf '%%%02x', ord $1/eg;
}


# convert to ascii
# ~~~~~~~~~~~~~~~~~
sub ascii {
	my $what = shift;

	$what =~ tr/áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ/acdeeinorstuuyzACDEEINORSTUUYZ/;

	$what;
}


# change encoging
# ~~~~~~~~~~~~~~~~~
sub encode {
	my ($from, $to, $text) = @_;

	from_to($text, $from, $to);

	$text;
}


# quote mime headers
# ~~~~~~~~~~~~~~~~~~~
sub mimeq {
	my $what = shift;

	my $mime = Encode::encode('MIME-Header', Encode::decode($Conf::Charset, $what));

	# because it breaks long lines in the middle of an email address
	# we have to get rid of these new-line-chars
	$mime =~ s/\s*\n\s*//gm;
	$mime;
}


# remove duplicates from an array
sub uniq {
	my %hash;
	@hash{@_} = ();
	keys %hash;
}


# uniq for sorted lists
sub uniqs {
	my (@result, $item, $lastitem);
	while ($item = shift @_) {
		push @result, $item if $item != $lastitem;
		$lastitem = $item;
	}
	@result;
}

# uniq for sorted lists (for strings)
sub uniqss {
	my (@result, $item, $lastitem);
	while ($item = shift @_) {
		push @result, $item if $item ne $lastitem;
		$lastitem = $item;
	}
	@result;
}

1

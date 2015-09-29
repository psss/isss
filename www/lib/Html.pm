package Html;

  #######################################################
 ####  Html -- useful html shortcuts  ##################
#######################################################
#
#  so that we don't have to write all the tr's and
#  td's and so on...
#

use strict qw(vars subs);

use Util;
use Query;

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(

			&br &hr &hrr &div &divv &span &spann &label &labell
			&tab &tabb &row &roww &td &tdd &th &tt &thh
			&submit &checkbox &input &area &radio
			&hide &hideback &sendback
			&checkall
		);
}

sub tab {
	my ($dat, $set) = @_;
	$set = " $set" if defined $set;
	$dat = "$dat\n\t</table>" if defined $dat;
	"\n\n\t<table$set>$dat";
}

sub row {
	my ($dat, $set) = @_;
	$set = " $set" if defined $set;
	$dat = "$dat\n\t\t</tr>" if defined $dat;
	"\n\t\t<tr$set>$dat";
}

sub td {
	my ($dat, $set) = @_;
	$set = " $set" if defined $set;
	$dat = "$dat</td>" if defined $dat;
	"\n\t\t\t<td$set>$dat";
}

sub th {
	my ($dat, $set) = @_;
	$set = " $set" if defined $set;
	$dat = "$dat</th>" if defined $dat;
	"\n\t\t\t<th$set>$dat";
}

# centered th
sub tt {
	my ($dat, $set) = @_;
	th($dat, "$set class=\"centered\"");
}

sub div {
	my ($dat, $set) = @_;
	$set = " $set" if $set;
	$dat = "$dat</div>" if $dat;
	"\n\t\t\t\t<div$set>$dat";
}

sub span {
	my ($dat, $set) = @_;
	$set = " $set" if $set;
	$dat = "$dat</span>" if $dat;
	"\n\t\t\t\t<span$set>$dat";
}


sub label {
	my ($dat, $set) = @_;
	$set = " $set" if $set;
	$dat = "$dat</label>" if $dat;
	"\n\t\t\t\t<label$set>$dat";
}


sub tabb   { "\n\t</table>"; }
sub roww   { "\n\t\t</tr>"; }
sub tdd    { "</td>"; }
sub thh    { "\n\t\t\t</th>"; }
sub divv   { "\n\t\t\t\t</div>"; }
sub spann  { "\n\t\t\t\t</span>"; }
sub labell { "\n\t\t\t\t</label>"; }


# make a brrr!
sub br {
	"<br/>";
}

# make an html <hr>, maybe with some caption
sub hr {
	"\n\n\t<hr width=\"50%\" align=\"left\">\n";
}

sub hrr {
	"\n\n\t<hr width=\"100%\"/>\n";
}


sub submit {
	my ($name, $value, $pars) = @_;
	$pars  = " $pars" if defined $pars;
	"\n\t\t\t<input type=\"submit\" name=\"$name\" value=\"$value\"$pars/>";
}


sub checkbox {
	my ($name, $value, $checked, $pars) = @_;
	$value = "yes" unless defined $value;
	$checked = $checked ? " checked=\"checked\"" : "";
	$pars  = " $pars" if defined $pars;
	"\n\t\t\t<input class=\"noborder\" type=\"checkbox\" name=\"$name\"".
		" value=\"$value\"$checked$pars/>";
}


sub input {
	my ($name, $value, $size, $max, $pars) = @_;
	$name  = " name=\"". uqq($name) ."\"" if defined $name;
	$value = " value=\"". uqq($value) ."\"" if defined $value;
	$size  = " size=\"$size\"" if defined $size;
	$max   = " maxlength=\"$max\"" if defined $max;
	$pars  = " $pars" if defined $pars;
	"\n\t\t\t<input type=\"text\"$name$value$size$max$pars/>";
}


sub area {
	my ($name, $value, $x, $y, $pars) = @_;
	$name = " name=\"". uqq($name) ."\"" if defined $name;
	$x = " cols=\"". uqq($x) ."\"" if defined $x;
	$y = " rows=\"". uqq($y) ."\"" if defined $y;
	$pars  = " $pars" if defined $pars;
	"\n\t\t\t<textarea $name$x$y$pars/>". uqq($value) ."</textarea>";
}


# radio button
sub radio {
	my ($name, $value, $selected) = @_;
	"\n\t\t\t<input type=\"radio\" class=\"noborder\" name=\"$name\" value=\"$value\"" .
			($selected eq $value ? " checked=\"checked\"" : "") . "/>";
}


# set hidden variable for formular
sub hide {
	my ($name, $value) = @_;

	"\n\t\t<input type=\"hidden\" name=\"".uqq($name)."\" value=\"".uqq($value)."\">";
}

# preserve all `back' variables and `return' url in the formular
# (used for interscript communication)
sub hideback {
        for my $par (grep /^back|^return$/, keys %qp::) {
		hide $par, ${"qp::$par"};
	}
}

# un`back' all `back' variables
# (used for sending info back to calling script)
sub sendback {
        for my $par (grep /^back/, keys %qp::) {
		my $cutpar = $par;
		$cutpar =~ s/^back//;
		hide $cutpar, ${"qp::$par"};
	}
}


# checking all checkboxes
sub checkall {
	my ($checkboxname, $formname) = @_;

	$formname = "form" unless $formname;
	$checkboxname = "*" unless $checkboxname;

	"vybrat:
		<a href=\"javascript:checkall('$formname', '$checkboxname', 1)\">všechno</a> /
		<a href=\"javascript:checkall('$formname', '$checkboxname', 0)\">nic</a> /
		<a href=\"javascript:checkall('$formname', '$checkboxname', 2)\">přehodit</a>"
}


## make percent bar for given percentage and width
## <<  ok	precentage
## <<  width	width in pixels
#sub bar {
#	my ($ok, $width) = @_;
#	$width = 100 unless $width;
#	my $ok = int $ok * $width / 100;
#	my $ko = $width - $ok;
#	my $return;
#
#	$return .= "<img src=\"$Conf::Pics/trig.jpg\">";
#	$return .= "<img src=\"$Conf::Pics/yes.jpg\" width=\"$ok\" height=\"10\">"
#		if $ok;
#	#$return .= "<img src=\"$Conf::Pics/trig.jpg\">";
#	$return .= "<img src=\"$Conf::Pics/no.jpg\" width=\"$ko\" height=\"10\">"
#		if $ko;
#	$return .= "<img src=\"$Conf::Pics/trig.jpg\">";
#
#	$return
#}


1

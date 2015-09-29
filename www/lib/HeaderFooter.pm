package HeaderFooter;

  #######################################################
 ####  HeaderFooter -- html head & footer  #############
#######################################################

use strict qw(vars subs);

use Util;
use Html;

my ($form_out, $header_out);

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(
			&header &footer &form &formm
		);

	# we haven't sent any header nor form yet
	$header_out = 0;
	$form_out = 0;
}

sub form {
	my ($what, $formname, $method) = @_;
	&formm if $form_out++ > 0;
	$method = "post" unless $method;
	$formname = "form" unless $formname;

	print "\n\n<form name=\"$formname\" action=\"$what\" method=\"$method\" enctype=\"multipart/form-data\">";
	"";
}


sub formm {
	print "\n</form>";
	$form_out--;
	"";
}


sub header {
	#error("dvojita hlavicka!"), return if $header_out;
	#!return if $header_out;
	my ($heading, $par) = @_;

	if ($par->{redir}) {
		print "Location: $par->{redir}\n\n";
		return;
	}

	print "Pragma: No-cache\nExpires: Fri, 01 Jan 1999 00:00:00 GMT\n".
		"Content-type: text/html; charset=$Conf::Charset\n\n".
		"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"
		\"http://www.w3.org/TR/html4/strict.dtd\">".
		"\n<html>\n<head>\n\t<title>isss - ". lc($heading) ."</title>";

	# base style sheet
	print "\n\t<link rel=\"stylesheet\" href=\"$Conf::CssUrl\" type=\"text/css\">";

	# maybe insert javascript link
	print "\n\t<script type=\"text/javascript\" src=\"$Conf::JavascriptUrl\"></script>" if $par->{javascript};

	my $bodyclass = $par->{body} ? 'class="'. $par->{body} .'"' : 'class="main"';
	my $focus = $par->{nofocus} ? "" :  "onload=\"self.focus();\"";

	print "$par->{head}\n</head>\n<body $bodyclass $focus $par->{bodyattrib}>";

	print div($heading, 'class="heading"') if $heading;
	$header_out++;

	#print join '<br/>', map { "$_ = ". ${"qp::$_"} } keys %qp::;
}


sub header_maybe {
	header unless $header_out;
}


sub footer {
	formm if $form_out > 0;

	print "\n\n</body>\n</html>\n";
	$header_out--;
}

END {
	# if the page is not complete -- place the footer!
	footer if $header_out;
}

1

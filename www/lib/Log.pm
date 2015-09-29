package Log;

  #######################################################
 ####  Log -- logging  #################################
#######################################################
#
#  logging
#

use strict qw(vars subs);

use Conf;
use Time;
##!use Html;

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(
			&logg &error &fatal &message &err &mess &info
		);
}


sub logg {
	my $message = shift;
	$message =~ s/\s+/ /g;

	open LOGFILE, ">>$Conf::Logfile"
		or die "nemuzu otevrit soubor $Conf::Logfile: $!";

	# cut script name
	$0 =~ /([^\/]+$)/;
	my $script = $1;

	printf LOGFILE (current Time)->db_stamp ." [%15s] <%10s> %16s: $message\n",
		$ENV{REMOTE_ADDR}, $ENV{REMOTE_USER}, $script;

	close LOGFILE;
}

sub message {
	my $message = shift;
	print "<span class=\"message\">$message</span>\n";
}


sub error {
	my $message = shift;
	logg($message);
	##!header_maybe;
	print "<span class=\"error\">$message</span>\n";
}


sub fatal {
	error(shift);
	die;
}


sub err {
	my ($message, $text) = @_;
	#logg($message);
	"&nbsp;<span class=\"error\" title=\"$message\">$text!</span>";
}


sub mess {
	my ($message, $text) = @_;
	"&nbsp;<span class=\"message\" title=\"$message\">$text!</span>";
}


sub info {
	my ($message, $text) = @_;
	"&nbsp;<span class=\"info\" title=\"$message\">$text!</span>";
}


1

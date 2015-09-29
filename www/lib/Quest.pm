package Quest;

use HeaderFooter;
use GlobUser;
use GlobDbi;
use Query;
use User;
use Time;
use Conf;
use Log;

use strict;

my $counter;

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(quest);
}

sub quest {
	my $max_repeat = shift || $Conf::FastCgiMaxRepeat;
	my $problem;

	do {
		return undef unless $counter++ < $max_repeat && new Query;

		# set current time
		$now = current Time;

		# set user object
		$user = log_in User $ENV{REMOTE_USER};

		$problem = 0;

		unless ($user) {
			header "sbohem!";
			print "tento uživatel žel v systému neexistuje...";
			logg "uživatel $ENV{REMOTE_USER} v systému neexistuje";
			$problem = 1;
		}

		# if nologin -- we just show the message
		# (except for users who do the administration)
		if (open NOLOGIN, $Conf::NoLoginFile and not grep {$_ eq $ENV{REMOTE_USER}} @Conf::NoLoginUsers) {
			header "moment";
				while (<NOLOGIN>) {
					print;
				}
				close NOLOGIN;
			footer;
			logg "moment...";
			$problem = 1;
		}
	} while $problem;

	$counter;
}

1

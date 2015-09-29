package Aid;

  #######################################################
 ####  Aid -- various comfortable gadgets  #############
#######################################################
#
#  prepares nice, comfortable environment for
#  the others
#

use strict qw(vars subs);

# these are exported globals

use HeaderFooter;
use GlobUser;
use GlobDbi;
use Query;
use Quest;
use Conf;
use Dbi;
use Html;
use Log;
use Util;
use User;
use Time;

BEGIN {
	# do everything around exporting
	use Exporter;
	use vars qw(@EXPORT @ISA);
	@ISA = qw(Exporter);
	@EXPORT = qw(
			$db $dbi $| $user $now

			&header &footer &form &formm &header_maybe
			&br &hr &hrr &div &divv &span &spann &label &labell
			&tab &tabb &row &roww &td &tdd &th &tt &thh
			&submit &checkbox &input &area &radio
			&hide &hideback &sendback

			&logg &error &fatal &message &err &mess &info

			&qp &qpars &qpfile &qplist &ids

			&uq &qd &uqq &off &ff &uff &ck
			&infl &ymd &hack &kcah &permute &scrap
			&glimpsie &parse_birth &speak &uniq &uniqs &uniqss
			&urrrl &ascii &encode &mimeq
			&checkall

			&quest
		);

	# don't hinder output
	$| = 2;
}

1

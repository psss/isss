package GlobDbi;

  #######################################################
 ####  GlobDbi -- global database objects  ############
#######################################################
#
#  provides global variables $db & $dbi containing
#  providing comfortable access to database
#

use strict qw(vars subs);

use Dbi;

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA $db $dbi $now);
	@ISA = qw(Exporter);
	@EXPORT = qw($db $dbi $now);

	# database connection
	$db = new Dbi;		# to be used in page generating scripts
	$dbi = new Dbi;		# to be used only in libraries
}

1

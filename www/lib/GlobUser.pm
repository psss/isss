package GlobUser;

  #######################################################
 ####  GlobUser -- info about current user  ############
#######################################################
#
#  provides global object $user containing
#  information and useful functions for
#  current user
#

use strict qw(vars subs);

BEGIN {
	use Exporter;
	use vars qw(@EXPORT @ISA $user);
	@ISA = qw(Exporter);
	@EXPORT = qw($user);
}

1

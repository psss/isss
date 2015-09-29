#!/usr/bin/perl

use strict;
use lib 'lib';
use Aid;

while (quest) {
	header undef, {
		body => "panel setup",
		nofocus => "yes",
		head => "<meta http-equiv=\"Refresh\" content=\"$Conf::PanelSetupFrameReload; URL=setup.pl\">" };

		print "
			<form action=\"setup.pl\" method=\"post\" target=\"setup\">
				". $user->setup ."
			</form>";

	footer;
}

#!/usr/bin/perl

use lib '../lib';
use Aid;
use Conf;
use Time;
use GlobDbi;
use Activity;
use Register;
use HeaderFooter;

while (quest) {
	header "Systémová správa";

		# first back up the database
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~

		# shift existing backups
		for my $i (reverse (0 .. $Conf::BackLevels - 1)) {
			my $oldfile = "$Conf::BackFileName." . sprintf("%03i", $i) . ".$Conf::BackFileSuffix";
			my $newfile = "$Conf::BackFileName." . sprintf("%03i", $i + 1) . ".$Conf::BackFileSuffix";

			rename $oldfile, $newfile if -e $oldfile;
		}

		# do a full backup? (with large objects/photos?)
		my $command = $ARGV[0] eq 'fullback' ? $Conf::BackCommandFull : $Conf::BackCommand;
		my $file = "$Conf::BackFileName.000.$Conf::BackFileSuffix";
		system "$command > $file";

		# delete old nonconfirmed registrations
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		sweep Register;

		# now vacuuuuuuum
		# ~~~~~~~~~~~~~~~~
		$dbi->exe("vacuum full analyze seasons");
		$dbi->exe("vacuum full analyze printers");
		$dbi->exe("vacuum full analyze roles");
		$dbi->exe("vacuum full analyze users");
		$dbi->exe("vacuum full analyze categories");
		$dbi->exe("vacuum full analyze fields");
		$dbi->exe("vacuum full analyze types");
		$dbi->exe("vacuum full analyze persons");
		$dbi->exe("vacuum full analyze rooms");
		$dbi->exe("vacuum full analyze activities");
		$dbi->exe("vacuum full analyze cards");
		$dbi->exe("vacuum full analyze lead");
		$dbi->exe("vacuum full analyze placed");
		$dbi->exe("vacuum full analyze registrations");
		$dbi->exe("vacuum full analyze payments");

		# delete empty person, rooms & activities

		# update free activities
		list Activity;

	print "ok";

	footer;
}

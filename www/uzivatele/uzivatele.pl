#!/usr/bin/perl

use lib '../lib';
use strict;

use Aid;
use Ider;
use User;

while (quest) {
	my %do;				# what are we to do
	my @uids = ids "u";		# with what shall we do it
	my $action = $qp::action || $qp::defaultaction || 'náhled';


	SWITCH: {
		if ($action =~ /přidat|create/) {
			# let's create it
			@uids = ((create User)->id);

			header "Nový uživatel";
			# and rest is the same as edit
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /upravit|edit|uložit/) {
			header "Upravit uživatele";
			$do{edit} = 1;
			last SWITCH;
		}
		if ($action =~ /smazat|delete/) {
			header infl scalar @uids, "Smazání uživatele", "Smazání uživatelů";
			$do{delete} = 1;
			last SWITCH;
		}
		#if ($action =~ /náhled|preview/) {
			header infl scalar @uids, "Náhled uživatele", "Náhledy uživatelů";
			$do{preview} = 1;
		#	last SWITCH;
		#}
	}


	error "chtělo by to vybrat aspoň jednoho uživatele..." unless @uids;
	form "uzivatele.pl";

	for my $uuuid (@uids) {
		my $uuuser = take User $uuuid;

		SWITCH: {
			if ($do{edit}) {
				$uuuser->edit;
				last SWITCH;
			}
			if ($do{delete}) {
				$uuuser->delete;
				last SWITCH;
			}
			#if ($do{preview}) {
				$uuuser->show;
			#	last SWITCH;
			#}
		}
	}


	# what next?
	unless ($do{delete} or !@uids) {
		# make buttons
		for (($do{edit} ? "uložit" : "upravit"), qw(náhled smazat)) {
			print submit "action", $_;
		}
		print " anebo ", submit(qw(action přidat)), " nového uživatele?";

		# hide useful info
		print hide "defaultaction", "uložit" if $do{edit};
		print hide "uids", join '.', @uids;

	}

	footer;
}

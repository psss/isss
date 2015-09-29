#!/usr/bin/perl

use strict;
use lib '../lib';
use Aid;
use Conf;

while (quest $Conf::FastCgiMaxRepeatForPhotos) {
	if ($qp::id) {
		print "content-type: image/jpeg\n\n";
		unless ($db->cat($qp::id)) {
			system "cat $Conf::NoPhotoFile";
		}
	}
	else {
		header "Nesprávné zadání";
		error "je třeba zadat číslo";
		footer;
	}
}

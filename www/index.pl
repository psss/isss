#!/usr/bin/perl

use lib 'lib';
use strict;

use Aid;

while (quest) {
	print 'Content-type: text/html


	<html>
	<head>

		<title>isss</title>

	</head>
	<frameset cols="*,150">
		<frame src="main.pl" name="main" frameborder="0">
		<frame src="panel.pl" name="panel" frameborder="0">
	</frameset>
	</html>
	';
}

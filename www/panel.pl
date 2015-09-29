#!/usr/bin/perl

use strict;
use lib 'lib';
use Aid;

while (quest) {
	header undef, { body => "panel", javascript => "yes", nofocus => "yes", bodyattrib => 'onload="clock();"' };

	# generate tooltip help for shortcuts according to user permissions
	my $direct_persons =
		($user->can("view_persons") && " náhled?").
		($user->can("edit_persons") && " upravit!").
		($user->can("view_registrations") && " registrace+").
		($user->can("view_payments") && " platby-").
		($user->can("view_cards") && " karty*").
		($user->can("view_persons") && " rozvrh=").
		($user->can("prrrint") && " tisk/").
		($user->can("send_messages") && " zprávy:");

	my $direct_activities =
		($user->can("view_activities") && " náhled?").
		($user->can("edit_activities") && " upravit!").
		($user->can("view_registrations") && " registrace+").
		($user->can("view_members") && " členové-").
		($user->can("prrrint") && " tisk/");

	my $direct_rooms =
		($user->can("view_rooms") && " náhled?").
		($user->can("edit_rooms") && " upravit!").
		($user->can("view_rooms") && " rozvrh=").
		($user->can("prrrint") && " tisk/");

	# print main panel
	print
		# isss heading
		"<span class=\"isss\"><a href=\"$Conf::Url/\" target=\"_top\">i</a><a href=\"main.pl\" target=\"main\" accesskey=\"i\">sss</a></span>

		<hr/> ".

		# persons search field
		($user->can("view_persons") && "
			<form action=\"lidi/index.pl\" method=\"post\" target=\"main\">
				<div>
					<a href=\"lidi/\" target=\"main\" title=\"přehled všech lidí\">lidi</a>
					". ($user->can("edit_persons") && "<a href=\"lidi/lidi.pl?action=create\" target=\"main\" title=\"přidat nového človíčka\">+</a>"). "
				</div>
				<input name=\"search\" type=\"text\" accesskey=\"l\" size=\"12\" max=\"77\" title=\"hledat lidi (rovnou:$direct_persons)\"/>
			</form>
		").

		# activities search field
		"<form action=\"aktivity/index.pl\" method=\"post\" target=\"main\">
			<div>
				<a href=\"aktivity/?open=0&pub=0&free=0\" target=\"main\" title=\"přehled všech aktivit\">aktivity</a>
				". ($user->can("edit_activities") && "<a href=\"aktivity/aktivity.pl?action=create\" target=\"main\" title=\"přidat novou aktivitu\">+</a>"). "
			</div>
			<input name=\"search\" type=\"text\" accesskey=\"a\" size=\"12\" max=\"77\" title=\"hledat aktivity (rovnou:$direct_activities)\"/>
			<input name=\"open\" type=\"hidden\" value=\"0\"/>
			<input name=\"pub\" type=\"hidden\" value=\"0\"/>
			<input name=\"free\" type=\"hidden\" value=\"0\"/>
		</form> ".

		# rooms search field
		($user->can("view_rooms") && "
			<form action=\"mistnosti/index.pl\" method=\"post\" target=\"main\">
				<div>
					<a href=\"mistnosti/\" target=\"main\" title=\"přehled všech místností\">místnosti</a>
					". ($user->can("edit_rooms") && "<a href=\"mistnosti/mistnosti.pl?action=create\" target=\"main\" title=\"přidat novou místnost\">+</a>") ."
				</div>
				<input name=\"search\" type=\"text\" accesskey=\"m\" size=\"12\" max=\"77\" title=\"hledat místnosti (rovnou: $direct_rooms)\"/>
			</form>
		").

		# registrations link
		($user->can('browse_registrations') && "<div><a href=\"registrace/\" target=\"main\">registrace</a></div>").

		# users link
		($user->can('edit_users') && "<div><a href=\"uzivatele/\" target=\"main\">uživatelé</a></div>").

		# cards link
		($user->can('prrrint_cards') && "<div><a href=\"tisk/karty.pl?pendingonly=yes&photoonly=yes&payedonly=yes\" target=\"main\">kartičky</a></div>").

		# payments link
		($user->can('browse_payments') && "<div><a href=\"platby/\" target=\"main\">platby</a></div>").

		# system administration link
		($user->can('do_system_stuff') && "<div><a href=\"sys/\" target=\"main\">sys</a></div>").

		# printer, season, username, date and time
		"<hr/>

		<iframe name=\"setup\" src=\"setup.pl\" width=\"100%\" height=\"$Conf::PanelSetupFrameHeight\" scrolling=\"no\" frameborder=\"0\"></iframe>

		<hr/>

		<p>". $user->name ."</p>

		<p>", $now->user_date_long("yes we want a year!"), "<br/><span id=\"clock\"></span></p>";

	footer;
}

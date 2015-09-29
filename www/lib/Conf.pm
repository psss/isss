package Conf;
#
# various useful constants used throughout the scripts
#

# system paths
#$Path = "/home/www/html/interni/isss";
#$Url = "/interni/isss";
$Path = "/home/www/html/interni/isss";
$Url = "/interni/isss";

$Pics = "$Url/pics";
$EntireUrl = "http://is.brno.sdb.cz$Url";

# cascading style sheets & javascript
$CssUrl = "$Url/css/isss.css";
$JavascriptUrl = "$Url/js/base.js";

# default charset
$Charset = "ISO-8859-2";

# printing
$PrintDir = "$Path/tex";
$PrintLog = "/dev/null";
#$PrintLog = "$Path/tex/error";
$PrintCommandTex = 'etex';
$PrintCommandDvips = 'dvips -t a4';
$PrintCommandDvipsLandscape = 'dvips -t a4 -t landscape';
$PrintCommandConvert = 'convert';
$PrintExtraRows = 3;

# messaging
$MessageSmsCommand = 'wget --no-check-certificate -qO -';
$MessageSmsUrl = 'https://www.dreamcom.cz/poslisms.php?jmeno=isss&heslo=heslo&skript=smscz';
$MessageSmsMaxLength = 160;
$MessageEmailFrom = 'Salesiánské středisko <info@brno.sdb.cz>';
#$MessageEmailFrom = '=?ISO-8859-2?Q?Informa=E8n=ED_syst=E9m_salesi=E1nsk=E9ho_st=F8ediska?= <isss@brno.sdb.cz>';
$MessageEmailContentType = 'text/plain; charset='. $Charset .'';

$UrlPhoto = "$Url/fotky/?id=";
$UrlNoPhoto = "$Url/fotky/kdopak.jpg";
$NoPhotoFile = "$Path/fotky/kdopak.jpg";

$UrlPersons = "$Url/lidi/lidi.pl";
$UrlPersonsIndex = "$Url/lidi/";

$UrlActivitiesIndex = "$Url/aktivity/";
$UrlActivities = "$Url/aktivity/aktivity.pl";

$UrlRoomsIndex = "$Url/mistnosti/";
$UrlRooms = "$Url/mistnosti/mistnosti.pl";

$UrlUsersIndex = "$Url/uzivatele/";
$UrlUsers = "$Url/uzivatele/uzivatele.pl";


# online map url
$UrlMap = 'http://mapy.cz/?fr=';

# database login info in postgres format
$DbName = 'isss';
$DbUser = 'isss';
$DbPassword = 'password';
$DbInfo = "dbname=$DbName user=$DbUser password=$DbPassword";

# max repeat from fast cgi scripts
$FastCgiMaxRepeat = 33;
$FastCgiMaxRepeatForPhotos = 2000;

# backing
$BackFileName = "/home/stredisko/back/$DbName";
$BackFileSuffix = "tar.bz2";
$BackCommand = "PGPASSWORD='$Conf::DbPassword' /usr/bin/pg_dump -Ft -U $DbUser $DbName | bzip2";
$BackCommandFull = "PGPASSWORD='$Conf::DbPassword' /usr/bin/pg_dump -Ft -b -U $DbUser $DbName | bzip2";
$BackLevels = 0;

# logfile location
$Logfile = "$Path/error.log";

# if this file is present -- user's won't be allowed to
# access the system -- instead its contents will be displayed to them
$NoLoginFile = "$Path/nologin";
# and users to be excluded from this
@NoLoginUsers = ('psss');

# settings for setup frame (season and printer setting)
$PanelSetupFrameHeight = 120;
$PanelSetupFrameReload = 77; # time in seconds to reload (get actual season & printer)

# how scraps should be long (shortening for listings)
$ScrapSize = 30;

# default slice & loaf thickness for long listings
# (default maximum number of listed items)
$SliceThickness = 20;
$SlicesInOneLoaf = 10;
$SliceSizesGreat = [ 10, "10", 100, "100" ]; # used for greater direct multi-choose in browse (e.g. activity///)

# table settings
$TabTask = 'cellpadding="20" border="0" width="60%"';
$TabScraps = 'class="scraps"';
$TabSheet = 'cellpadding="10" class="sheet" width="100%"';
$TabShade = 'class="shade" border="0"';

# activity types
$ActivityTypeOneTime = 1;
$ActivityTypeRegular = 2;
$ActivityTypeOther   = 3;

# input sizes
$TimeSize = 5;
$TimeMax = 5;
$DateSize = 12;
$DateMax = 12;
$DescSize = 55;
$DescMax = 128;
$OthSize = 20;
$OthMax = 40;
$PriceSize = 5;
$PriceMax = 5;

$InputSelectSize = 7;

@InputDate = (12, 12);
@InputDateShort = (10, 12);
@InputTime = (5, 5);
@InputStamp = (21, 21);
@InputPrice = (4, 5);
@InputName = (20, 55);
@InputTel = (12, 12);
@InputEmail = (20, 60);
@InputAge = (3, 3);
@InputCondition = (40, 120);
@InputNote = (40, 128);
@InputSms = (20, 13);
@InputEmailMessage = (55, 10);
@InputEmailSubject = (55, 80);

# after how many days should be not-payed registrations removed?
$DefaultRegistrationsConfirmTime = "7";
# round size (the smallest amount of money to care about)
$DefaultRoundRate = 10;

# default values for category & field
$DefaultCategory = 99;
$DefaultField = 9000;

# roles
%Roles = (
	admin		=> 0,
	editor		=> 1,
	register	=> 2,
	viewer		=> 3,
	info		=> 4,
	guest		=> 5
);

# ranks
%Ranks = (
	coordinator	=> 0,
	leader		=> 1,
	assistant	=> 2
);

# number of digits to use in paymenet & card numbers
$PaymentZeroes = 7;
$RegistrationZeroes = 7;
$CardZeroes = 7;

# schedule sizes
$ScheduleHourWidth = 55;
$ScheduleHourHeight = 77;

$ScheduleStart = 9;
$ScheduleFinish = 21;
$ScheduleCut = 1;

$ScheduleWidth = $Conf::ScheduleHourWidth * (1 + $Conf::ScheduleFinish - $Conf::ScheduleStart);
$ScheduleHeight = $Conf::ScheduleHourHeight * 7;

# special keywords to be highlighted in the note section of registration
@NoteKeywords = ("modrý papír", "dluh", "přefotit");

# load "hafo" size (maximum member count)
$LoadHafo = '300';

# various ages (used when searching for children, deciding which contact should be used)
$FamilyAge = 20;
$GravidityAge = 16;
$AdultAge = 18;

# maximal number of ids put into an url
$MaxUrlIdsCount = 777;

# settings for generating free activites
$FreeActivitiesFilename = '/home/www/html/aktivity/volne.html';
$FreeActivitiesHeader = '
<html>
	<head>
		<meta content="text/html; charset='. $Charset .'" http-equiv="Content-Type">
		<title>Seznam volných aktivit</title>
		<link rel="stylesheet" href="/css/isss.css" type="text/css">
		<link rel="icon" href="/iko/ikonka.png" type="image/png">
		<link rel="home" href="/" title="úvodní stránka střediska">
	</head>

	<body class="volne">
		<a href="http://brno.sdb.cz/" title="na úvodní stránku"><img src="/iko/logo.bile.gif"></a>
		<h1>Salesiánské středisko mládeže Brno-Žabovřesky</h1>
';

$FreeActivitiesFooter = '
		<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
		</script>
		<script type="text/javascript">
			_uacct = "UA-303389-1";
			_udn="brno.sdb.cz";
			urchinTracker();
		</script>
	</body>
</html>
';

1

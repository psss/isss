package Message;

  #######################################################
 ####  Message -- sending messages  ####################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > sms		create sms message
#  > email		create email message
#
#  object data:
#  ~~~~~~~~~~~~
#  > type		sms/email
#  > message		message text
#  > subject		email subject
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > send

use strict qw(subs vars);

use Aid;
use Mail::Sendmail;
use Encode qw(from_to);


#  create email message
# ~~~~~~~~~~~~~~~~~~~~~~
sub email {
	my ($pack, $subject, $message, $from) = @_;

	# check for rights
	error("nemáš právo posílat emaily"), return unless $user->can("send_email");

	# no message -> no email
	return unless $message;

	my $this = {};

	$this->{type} = 'email';
	$this->{message} = $message;
	$this->{subject} = $subject;
	$this->{from} = $from || $Conf::MessageEmailFrom;

	bless $this;
}



#  create sms message
# ~~~~~~~~~~~~~~~~~~~~~~
sub sms {
	my ($pack, $message) = @_;

	# check for rights
	error("nemáš právo posílat smsky"), return unless $user->can("send_sms");

	# no message -> no sms
	return unless $message;

	my $this = {};

	$this->{type} = 'sms';
	$this->{message} = $message;

	# get rid of newlines (they make sms longer then 160 chars)
	$this->{message} =~ s/\s+/ /g;
	#print length $this->{message};
	#print join ')(', split //, $this->{message};

	bless $this;
}


# send message
# ~~~~~~~~~~~~~
# >> undef if no problem
# >> error message otherwise
sub send {
	my ($this, $contact) = @_;

	# check for rights
	return err("nemáš právo posílat zprávy") unless $user->can("send_messages");

	# sending email
	if ($this->{type} eq 'email') {
		# check email address
		return err("nesprávný tvar emailové adresy ($contact)", "adresa")
			unless $contact =~ /\S+\@\S+/;

		# set email
		my %mail = (
			'To'		=> mimeq($contact),
			'From'		=> mimeq($this->{from}),
			'Content-Type'	=> $Conf::MessageEmailContentType,
			'Subject'	=> mimeq($this->{subject}),
			'Message' 	=> $this->{message}
		);

		# send it
		return undef if sendmail(%mail);

		# if problem -- show it
		return err('problém při posílání emailu ('. $Mail::Sendmail::error .')', 'chybka');
	}
	# sending sms
	else {
		# escape the message
		my $zprava = urrrl(ascii($this->{message}));

		# check the number (9 digits and first must be 6 or 7)
		my $tel = join '', $contact =~ /(\d)/g;
		return err("podivný formát čísla ($contact)", "číslo") unless $tel =~ /^[67]\d{8}$/;

		# construct the command
		my $command = "$Conf::MessageSmsCommand '$Conf::MessageSmsUrl&tel=$tel&zprava=$zprava'";

		# execute command and get result codes
		open (WGET, "$command|") or return err("chyba při spojení s bránou ($!)", "chybka");
			my $result = <WGET>;
			my $resulttext = <WGET>;
			my $credit = <WGET>;
		close(WGET);

		# a little enhancements
		chomp ($result, $resulttext, $credit);
		$resulttext = encode('windows-1250', 'iso-8859-2', $resulttext);

		return err("chyba při odesílání sms přes bránu ($resulttext)", "chybka") if $result != 0;

		undef;
	}
}


1

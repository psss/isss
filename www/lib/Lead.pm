package Lead;

  #######################################################
 ####  Lead -- handling leaders  ######################
#######################################################
#
#  class methods:
#  ~~~~~~~~~~~~~~
#  > create		create new leading
#  > take		constructor (takes person activity)
#  > delete		delete a user
#
#  object data:
#  ~~~~~~~~~~~~
#  > leader		person's id
#  > activity		activity's id
#  > rank		person's rank (0 - coordinator, 1 - leader, 2 - assistant)
#
#  object methods:
#  ~~~~~~~~~~~~~~~
#  > glimpse
#
#  > edit		make formular for editing
#  > show		show leading info
#  > save		maybe save some more information -- reserved for future

use strict qw(subs vars);

use Aid;
use Person;
use Activity;
use Inquisitor;


#  create new leading
# ~~~~~~~~~~~~~~~~~~~~
sub create {
	my ($pack, $leader, $rank, $activity) = @_;
	fatal "je třeba zadat vedoucího, aktivitu a pozici"
		unless defined($leader) && defined($rank) && defined($activity);

	# insert into db
	$dbi->beg;
		# delete possible old duplicates
		$dbi->exe("delete from lead where leader = $leader and activity = $activity");
		# coordinator can be just one
		$dbi->exe("delete from lead where rank = $Conf::Ranks{coordinator} and activity = $activity")
			if $rank == $Conf::Ranks{coordinator};
		# insert new leading
		$dbi->exe("insert into lead (leader, rank, activity) values ($leader, $rank, $activity)");
	$dbi->end;

	take Lead $leader, $activity;
}



# constructor for existing leadings
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# <<  pid
sub take {
	my ($pack, $pid, $aid) = @_;
	return undef unless defined $pid && defined $aid;

	my $this = {};

	$dbi->exe("select leader, rank, activity from lead where leader = $pid and activity = $aid")
		or fatal("takové vedení neexistuje ($pid)");
	@$this{qw(leader rank activity)} = $dbi->row;

	bless $this;
}




# deleting a leading
# ~~~~~~~~~~~~~~~~~~~~~
sub delete {
	my $this = shift;

	error("nemáš právo mazat vedení"), return unless $user->can("edit_lead");
	$dbi->exe("delete from lead where leader = $this->{leader} and activity = $this->{activity}");
}




# make formular for editing
# ~~~~~~~~~~~~~~~~~~~~~~~~~
sub edit {
        my $this = shift;

        # make sure user can edit this leading
        error("nemáš právo upravovat vedení"), $this->show, return
		unless $user->can("edit_lead");

	my %err;

	# if updating leaders
	if (defined ${"qp::lead$this->{leader}lead$this->{activity}delete"}) {
		# remove if checked to delete
		$this->delete, return "" if ${"qp::lead$this->{leader}lead$this->{activity}delete"};
	};

#	# simple select box for coordinator --- too perplexed
#	# if updating coordinator
#	if (defined ${"qp::lead$this->{activity}coordinator"}) {
#		$this->create(${"qp::lead$this->{activity}coordinator", $Conf::Ranks{coordinator}, $this->{activity});
#	}
#
#	# make select box for coordinator (can be just one)
#	if ($this->{rank} == $Conf::Ranks{coordinator}) {
#		my $animatorer = animator Inquisitor;
#		'<span title="změnit koordinátora">'.
#			$animatorer->select("lead$this->{activity}coordinator", $this->{leader}, " ").
#		'</span>'
#	}
#	# for regular leadear checkboxes for removing
#	else {
		'<span style="white-space: nowrap">'.
			checkbox("lead$this->{leader}lead$this->{activity}delete", undef, undef, 'title="odebrat vedoucího"').
			(take Person $this->{leader})->glimpse("name").
		'</span>'
#	}
}


# show short leading info
# ~~~~~~~~~~~~~~~~~~~~~~~~
sub show {
	my $this = shift;

	(take Person $this->{leader})->glimpse("[name]");
}



#  get activity's leaders
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub leaders {
	my ($pack, $activity, $rank) = @_;
	fatal "potřebuju id aktivity" unless defined $activity;

	my $condition;
	$condition = "and rank = $rank" if defined $rank;

	$dbi->exe("select p.id
			from lead l join persons p on l.leader = p.id
			where l.activity = $activity $condition order by p.surname, p.name"
	);
	$dbi->vals;
}


#  get activities for a leader
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub activities {
	my ($pack, $leader, $public, $rank) = @_;
	fatal "potřebuju id vedoucího" unless defined $leader;

	my $condition;
	$condition = "" if $public eq "all";
	$condition = " and pub" if $public eq "public" || !defined $public;
	$condition = " and not pub" if $public eq "internal";
	$condition .= " and rank = $rank" if defined $rank;

	$dbi->exe("select a.id
			from lead l
			join activities a
				on l.activity = a.id
			left outer join placed p
				on p.activity = a.id
			where l.leader = $leader
			  and a.season = ". $user->season ."
			  $condition
			order by a.name, a.season, p.day, p.start"
	);
	uniqs $dbi->vals;
}



# get short statistics
sub stats {
	my ($this, $what) = @_;

	$dbi->exe("select count(*) from persons where animator");
	my $animators = $dbi->val;

	$dbi->exe("select count(distinct l.leader) from
			lead l join activities a on l.activity = a.id
			where season = ". $user->season);
	my $active = $dbi->val;

	return "$animators ". infl($animators, qw(animátor animátoři animátorů)).
		", $active ". infl($active, qw(aktivní aktivní aktivních));
}



1

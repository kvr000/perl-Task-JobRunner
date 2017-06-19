package Task::JobRunner;

use strict;
use warnings;

sub new
{
	my $ref = shift;
	my $class = ref($ref) || $ref;

	return bless {
		tasks                           => [],
	}, $class;
}

sub launch
{
}


package Task::JobRunner::Requirements;

use strict;
use warnings;

sub new
{
	my $ref = shift;
	my $class = ref($ref) // $ref;

	return bless {
		requirements                    => [],
	}, $class;
}


package Task::JobRunner::JobGraph;

use strict;
use warnings;

sub new
{
	my $ref = shift;
	my $class = ref($ref) // $ref;

	return bless {
		tasks                           => [],
	}, $class;
}

sub addTask
{
	my $self = shift;
	my ( $taskName, $task, $requirements ) = @_;
}


package Task::JobRunner::Task;

use strict;
use warnings;

use Carp;

sub new
{
	my $ref = shift;
	my $class = ref($ref) // $ref;

	my $self = bless {
		@_
	}, $class;
	$self->validate();

	return $self;
}

sub validate
{
	my $self = shift;
}

sub launch
{
	carp "Abstract, must be overridden by child";
}


package Task::JobRunner::TaskRunner;

use strict;
use warnings;

use Carp;

sub new
{
	my $ref = shift;
	my $class = ref($ref) // $ref;

	my $self = bless {
		@_
	}, $class;
	$self->validate();

	return $self;
}

sub stop
{
	my $self = shift;
	my ( $finished ) = @_;

	carp "method stop must be overriden";
}


package Task::JobRunner::ProcessTask;

use strict;
use warnings;

use Carp;
use Proc::Background;

use base "Task::JobRunner::Task";

sub launch
{
	my $self = shift;
	my ( $eventLoop, $finishedCb ) = @_;

	my $run = Proc::Background("$self->{command}");

	return Task::JobRunner::ProcessTask::Runner->new($self, $eventLoop, $finishedCb, $run->pid());
}

sub validate
{
	my $self = shift;

	carp "command is not defined" unless (defined $self->{command});
}


package Task::JobRunner::ProcessTask::Runner;

use strict;
use warnings;

use POSIX;

use base "Task::JobRunner::TaskRunner";

sub new
{
	my $class = shift;
	my ( $eventLoop, $finishedCb, $pid ) = @_;

	my $self = $class->SUPER::new(@_);

	$self->{finishedCb} = $finishedCb;
	$self->{pid} = $pid;
	$self->{finished} = undef;

	$eventLoop->child(pid => $pid, cb => sub {
			my ( $pid, $status ) = @_;
			$self->processFinished($status);
		}
	);
}

sub stop
{
	my $self = shift;
	my ( $eventLoop ) = shift;

	kill(SIGTERM, $self->{pid});

	$eventLoop->timer(after => 5, cb => sub {
			return if (defined $self->{finished});
			kill(SIGKILL, $self->{pid});
		}
	);
}

sub processFinished
{
	my $self = shift;
	my ( $status ) = @_;

	$self->{finished} = $status;
	&{$self->{finishedCb}}($status);
}


1;

# vim: set noet sw=8 ts=8 smarttab autoindent cindent:

package AnyEvent::FileWatch::KQueue;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;
use IO::KQueue;

sub new {
	my ($class, $paths) = @_;

	Carp::croak("require path list") if !$paths || ref($paths) ne 'ARRAY';

	my $kq = IO::KQueue->new;

    my $self = bless {
        _files    => {},
        _kqueue   => $kq,
        _callback => sub {}
    }, $class;

	$self->_scan($_, 1) for @$paths;

    $self->{_watcher} = AE::io $$kq, 0, sub {
		if (my @events = $kq->kevent) {
			$self->_scan($_->[KQ_UDATA], 1) for @events;
			$self->{_callback}->(@events);
		}
    };

	return $self;
}

sub _scan {
	my ($self, $path, $recursive) = @_;

	# from Filesys::Notify::KQueue
	$self->{_files}{$path} ||= do {
        open(my $fh, '<', $path) or die("Can't open '$path': $!");
        die "Can't get fileno '$path'" unless defined fileno($fh);

        # add to watch
        $self->{_kqueue}->EV_SET(
            fileno($fh),
            EVFILT_VNODE,
            EV_ADD | EV_CLEAR,
            NOTE_DELETE | NOTE_WRITE | NOTE_RENAME | NOTE_REVOKE,
            0,
            $path,
        );

        $fh;
	};

	my $status = 'modify';

	unless (-e $path) {
		close $self->{_files}{$path};
		delete $self->{_files}{$path};
		$status = 'delete';
	}
	else {
		if ($recursive) {
			return {
				status => $status,
				paths  => [ map { $self->_scan($_) } File::Zglob::zglob($path.'/**/*') ]
			};
		}
	}

	return {
		status => $status,
		paths  => [ $path ]
	};
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

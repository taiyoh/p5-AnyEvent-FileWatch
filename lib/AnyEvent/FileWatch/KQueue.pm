package AnyEvent::FileWatch::KQueue;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;
use IO::KQueue;

sub new {
    my ($class, $paths) = @_;

    croak "require path list" if !$paths || ref($paths) ne 'ARRAY';

    my $kq = IO::KQueue->new;

    my $self = bless {
        _sys      => {},
        _kqueue   => $kq,
        _callback => sub {}
    }, $class;

    $self->_scan(Cwd::abs_path($_)) for @$paths;

    $self->{_watcher} = AE::io $$kq, 0, sub {
        my @events = $kq->kevent or return;
        my %uniq;
        my @path = grep !$uniq{$_}++, map { $_->[KQ_UDATA] } @events;
        my $path = $path[0];
        my $old_fs = $self->{_sys}{$path}{files};
        my $new_fs = scan_files(@path);
        my @evs;
        compare_fs($old_fs, $new_fs, sub {
            my ($status, $path, $stat) = @_;
            push @evs, AnyEvent::FileWatch::Event->new({
                status => $status,
                path   => $path,
                stat   => $stat
            });
        });
        $self->{_callback}->(@evs) if @evs;
        $self->{_sys}{$path}{files} = $new_fs;
    };

    return $self;
}

sub _scan {
    my ($self, $path) = @_;

    # from Filesys::Notify::KQueue
    $self->{_sys}{$path} ||= do {
        open(my $fh, '<', $path) or croak("Can't open '$path': $!");
        croak "Can't get fileno '$path'" unless defined fileno($fh);

        # add to watch
        $self->{_kqueue}->EV_SET(
            fileno($fh),
            EVFILT_VNODE,
            EV_ADD | EV_CLEAR,
            NOTE_DELETE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_WRITE | NOTE_RENAME | NOTE_REVOKE,
            0,
            $path,
        );

        +{
            filehandle => $fh,
            files => scan_files($path)
        };
    };
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

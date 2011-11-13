package AnyEvent::FileWatch::Inotify;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;
use Linux::Inotify2;

sub new {
    my $class = shift;
    my $paths = shift;

    croak "require path list" if !$paths || ref($paths) ne 'ARRAY';

    my $in = Linux::Inotify2->new;

    my $self = bless {
        _sys => {},
        _inotify => $in,
        _callback => sub {}
    }, $class;

    $self->_scan(Cwd::abs_path($_)) for @$paths;

    $self->{_watcher} = AE::io $in->fileno, 0, sub {
        my @events = $in->read or return;
        my %uniq;
        my @path = grep !$uniq{$_}++, map { $_->fullname } @events;
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

    $self->{_sys}{$path} ||= do {
        $self->{_inotify}->watch($path, IN_MODIFY | IN_CREATE | IN_DELETE);

        +{
            files => scan_files($path)
        };
    };
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

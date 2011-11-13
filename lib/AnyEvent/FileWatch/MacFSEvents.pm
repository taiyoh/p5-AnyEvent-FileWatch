package AnyEvent::FileWatch::MacFSEvents;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;
use Mac::FSEvents;

sub new {
    my ($class, $paths, $latency) = @_;

    croak "require path list" if !$paths || ref($paths) ne 'ARRAY';

    my $self = bless {
        _sys      => {},
        _callback => sub {},
        _latency  => $latency || 0
    }, $class;

    $self->_scan(Cwd::abs_path($_)) for @$paths;

    return $self;
}

sub _scan {
    my ($self, $path) = @_;

    $self->{_sys}{$path} ||= do {

        my $fs = Mac::FSEvents->new({
            path => $path,
            latency => $self->{_latency}
        });

        my $w = AE::io $fs->watch, 0, sub {
            my @events = $fs->read_events or return;
            my %uniq;
            my @path = grep !$uniq{$_}++, map { $_->path } @events;
            my @evs;
            my $old_fs = $self->{_sys}{$path}{files};
            my $new_fs = scan_files(@path);
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

        +{
            fsevents => $fs,
            watcher  => $w,
            files    => scan_files($path)
        };
    };
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

package AnyEvent::FileWatch::Timer;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;

sub new {
    my ($class, $paths, $interval) = @_;

    croak "require path list" if !$paths || ref($paths) ne 'ARRAY';

    my $self = bless {
        _sys => {},
        _callback => sub {}
    }, $class;

    $self->_scan(Cwd::abs_path($_)) for @$paths;

    $interval ||= 1;

    $self->{_watcher} = AE::timer $interval, $interval, sub {
        for my $path (@$paths) {
            my $old_fs = $self->{_sys}{$path}{files};
            my $new_fs = scan_files($path);
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
        }
    };

    return $self;
}

sub _scan {
    my ($self, $path) = @_;
    $self->{_sys}{$path} ||= { files => scan_files($path) };
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

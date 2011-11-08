package AnyEvent::FileWatch::MacFSEvents;

use strict;
use warnings;

use AnyEvent::FileWatch::Util;
use Mac::FSEvents;

sub new {
    my $class = shift;
    my $paths = shift;

    croak "require path list" if !$paths || ref($paths) ne 'ARRAY';

    my $self = bless {
        _files  => {},
        _callback => sub {}
    }, $class;

    $self->_scan(Cwd::abs_path($_), 1) for @$paths;

    return $self;
}

sub _scan {
    my ($self, $path, $recursive) = @_;

    $self->{_files}{$path} ||= do {

        my $fs = Mac::FSEvents->new({
            path => $path,
            latency => 0
        });

        my $w = AE::io $fs->watch, 0, sub {
            if (my @events = $fs->read_events) {
                $self->_scan($_->path, 1) for @events;
                $self->{_callback}->(@events);
            }
        };

        +{
            fsevents => $fs,
            watcher  => $w
        };
    };

    my $status = 'modify';

    unless (-e $path) {
        $self->{_files}{$path}{fsevents}->stop;
        delete $self->{_files}{$path}{watcher};
        delete $self->{_files}{$path};
        $status = 'delete';
    }
    else {
        if ($recursive) {
            return {
                status => $status,
                paths  => [ map { $self->_scan($_) } zglob($path.'/**/*') ]
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

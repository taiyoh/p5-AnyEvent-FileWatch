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
        _files => {},
        _inotify => $in,
        _callback => sub {}
    }, $class;

    $self->_scan(Cwd::abs_path($_), 1) for @$paths;

    $self->{_watcher} = AE::io $in->fileno, 0, sub {
        if (my @events = $in->read) {
            $self->{_callback}->(@events);
        }
    };

    return $self;
}

sub _scan {
    my ($self, $path, $recursive) = @_;

    $self->{_files}{$path} ||= do {
        $self->{_inotify}->watch($path, IN_MODIFY | IN_CREATE | IN_DELETE);
        1;
    };

    if ($recursive) {
        map { $self->_scan($_) } zglob($path.'/**/*');
    }
}

sub wait { $_[0]->{_callback} = $_[1] }

1;

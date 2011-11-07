package AnyEvent::FileWatch::Util;

use Cwd ();
use Carp ();
use File::Zglob ();

package AnyEvent::FileWatch::Event;

use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub id { shift->{id} }

sub path { shift->{path} }

sub status { shift->{status} }

1;

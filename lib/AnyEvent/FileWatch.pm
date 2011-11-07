package AnyEvent::FileWatch;
use strict;
use warnings;
our $VERSION = '0.000000001';

# from Filesys::Notify::Simple
use constant NO_OPT => $ENV{PERL_FNS_NO_OPT};

use AnyEvent;

sub new {
	my $pkg = shift;
	return _init()->new(@_);
}

# from Filesys::Notify::Simple
sub _init {
    local $@;
    if ($^O eq 'linux' && !NO_OPT && eval { require AnyEvent::FileWatch::Inotify; 1 }) {
        return "AnyEvent::FileWatch::Inotify";
    } elsif ($^O eq 'darwin' && !NO_OPT && eval { require AnyEvent::FileWatch::MacFSEvents; 1 }) {
        return "AnyEvent::FileWatch::MacFSEvents";
    } elsif ($^O eq 'freebsd' && !NO_OPT && eval { require AnyEvent::FileWatch::KQueue; 1 }) {
		return "AnyEvent::FileWatch::KQueue";
    } else {
        die "sorry... not implemented.";
    }
}


1;
__END__

=head1 NAME

AnyEvent::FileWatch -

=head1 SYNOPSIS

  use AnyEvent::FileWatch;

=head1 DESCRIPTION

AnyEvent::FileWatch is

=head1 AUTHOR

Taiyoh Tanaka E<lt>sun.basix@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

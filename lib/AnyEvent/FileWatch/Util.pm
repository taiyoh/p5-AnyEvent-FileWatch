package AnyEvent::FileWatch::Util;

use parent 'Exporter';

use Cwd ();

use Carp;
use File::Zglob;

our @EXPORT = qw/croak carp scan_files compare_fs/;

# from Filesys::Notify::Simple
sub fw_stat {
    my $path = shift;
    my @stat = stat $path;
    return {
        path   => $path,
        mtime  => $stat[9],
        size   => $stat[7],
        is_dir => -d _
    };
}

sub scan_files {
    my %path_map;
    for my $path (@_) {
        if (-d $path) {
            for my $p (zglob($path.'/**/*')) {
                my $st = fw_stat($p);
                $path_map{$p} ||= $st if $st;
            }
        }
        else {
            my $st = fw_stat($path);
            $path_map{$path} = $st if $st;
        }
    }
    return \%path_map;
}

# from Filesys::Notify::Simple
sub compare_fs {
    my($old, $new, $cb) = @_;

    for my $path (keys %$old) {
        if (!exists $new->{$path}) {
            $cb->('deleted', $path, $old->{$path}); # deleted
        } elsif (!$new->{$path}{is_dir} &&
                 ( $old->{$path}{mtime} != $new->{$path}{mtime} ||
                   $old->{$path}{size}  != $new->{$path}{size})) {
            $cb->('updated', $path, $new->{$path}); # updated
        }
    }

    for my $path (keys %$new) {
        if (!exists $old->{$path}) {
            $cb->('created', $path, $new->{$path}); # new
        }
    }
}

package AnyEvent::FileWatch::Event;

use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub stat { shift->{stat} }

sub path { shift->{path} }

sub status { shift->{status} }

1;

#!perl -w

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/";

use AnyEvent::FileWatch;
use Data::Dumper;

my $filepath = shift or die;

my $cv = AE::cv;

my $fw = AnyEvent::FileWatch->new([$filepath]);

$fw->wait(sub {
    warn Dumper(\@_);
});

$cv->recv;

use strict;
use Test::More;

$ENV{PERL_AF_NO_OPT} = 1;
require AnyEvent::FileWatch;

my $fs = AnyEvent::FileWatch->new(["/xxx/nonexistent"]);

my $cv = AnyEvent->condvar;

$SIG{ALRM} = sub { $cv->send(1) };
alarm 1;
$fs->wait(sub {});

ok $cv->recv, "Alarm\n";

done_testing;

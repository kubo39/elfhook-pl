use strict;
use warnings;

use lib './lib';
use lib './blib/arch/auto/Httphead';

use lib '../lib';
use lib '../blib/arch/auto/Elfhook';

use Coro;
use Coro::EV; # ??

use Httphead;
use Elfhook;



my $ r = Elfhook::patch("/home/hiroki.noda/dev/dlang/elfhook/test/blib/arch/auto/Httphead/Httphead.so");
print $r . "\n";


my @stack = ();

sub c_http_header_check {
    my ($host, $port) = @_;
    push(@stack, "header begin");
    print "head begin.\n";
    my $ret = Httphead::http_head($host, $port);
    print "head end.\n";
    push(@stack, "header end");
    return $ret;
}

sub sleeper {
    push(@stack, "begin sleeper");
    print "sleeper begun.\n";
    sleep 1;
    push(@stack, "end sleeper");
}

my @test_sites = (
    ["localhost", 9999],  # fake slow server.
    ["msn.com", "80"],
    ["tumblr.com", "80"],
);

my @coros;
foreach my $addr (@test_sites) {
    push @coros, async {
        c_http_header_check(@{$addr});
    };
}

$_->join for @coros;

use lib './lib';
use lib './blib/arch/auto/Elfhook';
use Coro;
use Elfhook;

my $retval = Elfhook::patch("/lib64/libmemcached.so.11");
print "$retval \n";

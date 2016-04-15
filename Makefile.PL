use 5.014001;
use ExtUtils::MakeMaker;

my %wm = (
    NAME              => 'Elfhook',
    VERSION_FROM      => 'lib/Elfhook.pm',
    PREREQ_PM         => {
        Coro             => 6.49,
        EV               => 4.22,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Elfhook.pm',
       AUTHOR         => 'kubo39') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => 'Elfhook.o delfhook.o'
    );

if (eval "require EV::MakeMaker; require Coro::MakeMaker; 1") {
    %wm = Coro::MakeMaker::coro_args (EV::MakeMaker::ev_args (%wm));
} else {
    print "There's no ev.\n";
}

WriteMakefile %wm;

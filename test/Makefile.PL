use 5.014001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Httphead',
    VERSION_FROM      => 'lib/Httphead.pm',
    PREREQ_PM         => {
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Httphead.pm',
       AUTHOR         => 'kubo39') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => ''
    );

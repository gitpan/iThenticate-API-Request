use 5.008008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'iThenticate-API-Request',
    VERSION_FROM  => 'lib/iThenticate/API/Request.pm',                     # finds $VERSION
    PREREQ_PM     => { 'RPC::XML' => 1.36, },
    ABSTRACT_FROM => 'lib/iThenticate/API/Request.pm',                     # retrieve abstract from module
    AUTHOR        => 'Fred Moyer<fred@(?:redhotpenguin|turnitin).com>',    # no critic
);

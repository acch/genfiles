# Genfiles

[![GitHub Issues](https://img.shields.io/github/issues/acch/genfiles.svg)](https://github.com/acch/genfiles/issues) [![GitHub Stars](https://img.shields.io/github/stars/acch/genfiles.svg?label=github%20%E2%98%85)](https://github.com/acch/genfiles/) [![License](https://img.shields.io/github/license/acch/genfiles.svg)](LICENSE)

Tool for generating files with random content for test / demonstration purposes. The script is written in Perl and should run on any system which has Perl installed.

## Requirements

The Perl script requires:
- Perl [Config::General](https://metacpan.org/pod/Config::General) Module

On RedHat based systems install `perl-Config-General`. For RHEL7 this package is available from [EPEL](http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/p/).

The pre-compiled binaries do not require any additional libraries other than Perl itself.

## Components

File | Description
--- | ---
genfiles.pl | The Perl script to generate files
genfiles.conf | The configuration file defining file types which are generated
genfiles | Pre-combiled binary to generate files

## Copyright and license

Copyright 2015 Achim Christ, released under the [MIT license](LICENSE).

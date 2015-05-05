# Genfiles

Tool for generating files with random content for test / demonstration purposes. The script is written in Perl and should run on any system which has Perl installed.

## Requirements

The Perl script requires:
- Perl [Config::General](https://metacpan.org/pod/Config::General) Module

On RedHat based systems install `perl-Config-General`.

The pre-compiled binaries do not require any additional libraries other than Perl itself.

## Components

File | Description
--- | ---
genfiles.pl | The Perl script to generate files
genfiles.conf | The configuration file defining file types which are generated
genfiles.RHEL6, genfiles.RHEL7, etc. | Pre-combiled binaries to generate files

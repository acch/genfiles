#!/usr/bin/perl

=head1 genfiles.pl

==========================================================================
  Genfiles v1.0
  https://github.com/acch/genfiles
==========================================================================
  Copyright 2015 Achim Christ
  Licensed under MIT (https://github.com/acch/genfiles/blob/master/LICENSE)
==========================================================================

=cut

use strict;
use warnings;

use feature "say"; # say()

use Getopt::Std "getopts";
use File::Path "make_path";
use Config::General; # Config::General->getall()

# default options
use constant {
  VERSION => "1.0",
  DEBUG => 0,
  CONFIG_FILE => "genfiles.conf",
  DEFAULT_NUMBER => 100,
  DEFAULT_TYPE => "tmp",
  DEFAULT_FORMAT => 1 # ascii text
};

################################################################################
# GLOBALS
################################################################################

my $buffer = "";

################################################################################
# FUNCTIONS
################################################################################

# --version message
sub VERSION_MESSAGE {
  say STDERR "Genfiles version ".&VERSION;
}

# --help message
sub HELP_MESSAGE {
  say STDERR "Usage: ".$0." [-n <number_of_files>] [-t <file_type>] <directory>";
  say STDERR "       -n number";
  say STDERR "           Number of files to generate (default = ".&DEFAULT_NUMBER.")";
  say STDERR "       -t type";
  say STDERR "           Type of files to generate (default = ".&DEFAULT_TYPE.")";
  say STDERR "           File types are defined in ".&CONFIG_FILE;
  say STDERR "       directory";
  say STDERR "           The absolute path of the directory in which files will be generated";
  say STDERR "           Directory will be created if it does not exist";
}

# generate buffer
# parameters:
# 1. format of the buffer (0 = binary, 1 = ascii)
# 2. size of the buffer
sub genbuffer {
  if ($_[0] == 0) {
    # generate binary data buffer
    for (my $i = 0; $i < $_[1]; $i++) {
      # generate random byte
      $buffer .= chr(int(rand(256)))
    }
  } else { # $_[0] == 1
    # generate ascii text buffer
    for (my $i = 0; $i < $_[1]; $i++) {
      # generate random ascii character
      $buffer .= chr(32 + int(rand(127 - 32)));
    }
  }
}

################################################################################
# CHECK COMMANDLINE OPTIONS
################################################################################

# declare commandline options
our($opt_n, $opt_t);

# read commandline options
$Getopt::Std::STANDARD_HELP_VERSION = 1;
unless (getopts('n:t:')) {
  HELP_MESSAGE();
  exit 1;
}

# directory must be given and must be absolute path
unless ($ARGV[0] && File::Spec->file_name_is_absolute($ARGV[0])) {
  HELP_MESSAGE();
  exit 1;
}

# use commandline options or default
my $out_directory = $ARGV[0];
my $out_number = $opt_n || &DEFAULT_NUMBER;
my $out_type = $opt_t || &DEFAULT_TYPE;

if (&DEBUG) {
  say "d: ".$out_directory;
  say "n: ".$out_number;
  say "t: ".$out_type;
}

################################################################################
# READ CONFIG FILE
################################################################################

# compute full path to config file
my ($script_vol, $script_path) = File::Spec->splitpath($0);
$script_path = File::Spec->catpath($script_vol, $script_path, undef);
my $config_file_path = File::Spec->catfile($script_path, &CONFIG_FILE);

# check config file
(-f $config_file_path)
  or die("Config file not found: ".$config_file_path."\n");

# read config file
my $config_file = Config::General->new(
  -ConfigFile => $config_file_path,
  -LowerCaseNames => 1);
my %config = $config_file->getall();

# check if requested file type is defined in config file
my $out_type_config = $config{filetype}{$out_type}
  or die("Type ".$out_type." not defined in config file: ".$config_file_path."\n");

# read options from config file
my $buffer_size = $config{buffersize} * 1024 || 0;
my $out_suffix = ${$out_type_config}{suffix};
my $out_min_size = ${$out_type_config}{minsize} || 0;
my $out_off_size = (${$out_type_config}{maxsize} || 0) - $out_min_size;
my $out_format = ${$out_type_config}{format};
defined($out_format) or $out_format = &DEFAULT_FORMAT;

# check plausability of options
(($out_min_size >= 0) &&
  ($out_off_size >= 0) &&
  ($out_min_size + $out_off_size > 0) &&
  ($out_format == 0) || ($out_format == 1))
  or die("Invalid options detected for type ".$out_type." in config file: ".$config_file_path."\n");

################################################################################
# CREATE DIRECTORY
################################################################################

# create directory if it does not exist
unless (-d $out_directory) {
  make_path($out_directory)
    or die("Can't create ".$out_directory.": ".$!."\n");
}

################################################################################
# GENERATE BUFFER
################################################################################

# make STDOUT handle hot
# so that messages are written during script execution (and not afterwards)
select((select(STDOUT), $|=1)[0]);

# check if pre-generation of buffer is requested
if ($buffer_size) {
  say "Generating buffer of size ".($buffer_size/1024)." KB...";

  # generate buffer of fixed size
  genbuffer($out_format, $buffer_size);

  say "...done!";
}

################################################################################
# GENERATE FILES
################################################################################

# position in buffer
my $buffer_offset = 0;

say "Generating ".$out_number." files of random size in ".$out_directory." with suffix ".$out_suffix."...";

# process files
for (my $i = 0; $i < $out_number; $i++) {
  # compute file name
  my $out_name = File::Spec->catfile($out_directory, "file_".$i.$out_suffix);

  # compute file size
  my $out_size = ($out_min_size + int(rand($out_off_size))) * 1024;

  # check if buffer was already pre-generated
  unless ($buffer_size) {
    # generate buffer for this file
    genbuffer($out_format, $out_size);
  }

  # open file
  open(FH, ">", $out_name)
    or die("Can't open ".$out_name.": ".$!."\n");

  # write buffer to file
  print(FH substr($buffer, $buffer_offset, $out_size))
    or die ("Can't write to ".$out_name.": ".$!."\n");

  # check if pre-generated buffer is used
  if ($buffer_size) {
    # increment position by requested file size
    $buffer_offset += $out_size;

    # check if we've reached end of buffer
    if ($buffer_offset == $buffer_size) {
      # reset position
      $buffer_offset = 0;
    } else {
      # check if we've already gone beyond end of buffer
      while ($buffer_offset > $buffer_size) {
        # write remaining data from beginning of buffer
        print(FH substr($buffer, 0, $buffer_offset - $buffer_size))
          or die ("Can't write to ".$out_name.": ".$!."\n");
        # decrement position by actual buffer size
        $buffer_offset -= $buffer_size;
      }
    }
  }

  # close file
  close(FH);
}

say "...done! Exiting.";

#!/usr/bin/perl

use strict;
use warnings;

use feature "say"; # say()

#use Cwd; # cwd()
use Getopt::Std; # getopts()
use Config::General; # Config::General->getall()

# default options
use constant {
  DEBUG => 1,
  CONFIG_FILE => "genfiles.conf",
  DEFAULT_NUMBER => 100,
  DEFAULT_TYPE => "tmp"
};

# --version message
sub VERSION_MESSAGE {
  say STDERR "Genfiles Version 0.1";
}

# --help message
sub HELP_MESSAGE {
  say STDERR "Usage: $0 [-n <number_of_files>] [-t <file_type>] <directory>";
  say STDERR "       -n number";
  say STDERR "           Number of files to generate (default = ".&DEFAULT_NUMBER.")";
  say STDERR "       -t type";
  say STDERR "           Type of files to generate (default = ".&DEFAULT_TYPE.")";
  say STDERR "           File types are defined in ".&CONFIG_FILE;
  say STDERR "       directory";
  say STDERR "           The absolute path of the directory in which files will be generated";
  say STDERR "           Directory will be created if it does not exist";
}

################################################################################
# CHECK COMMANDLINE OPTIONS
################################################################################

# declare commandline options
our($opt_d, $opt_n, $opt_t);

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
my %out_type_config = %config{filetype}{$out_type}
  or die("Type ".$out_type." not defined in config file: ".$config_file_path."\n");

# read options from config file
my $buffer_size = $config{buffersize} * 1024 || 0;
my $out_suffix = $out_type_config{suffix};
my $out_min_size = $out_type_config{minsize} || 0;
my $out_off_size = ($out_type_config{maxsize} || 0) - $out_min_size;

# TODO: check that min_size < max_size

################################################################################
# CREATE DIRECTORY
################################################################################

# create directory if it does not exist
unless (-d $out_directory) {
  mkdir($out_directory)
    or die("Can't create $out_directory: $!");
}

################################################################################
# GENERATE BUFFER
################################################################################

# make STDOUT handle hot
# so that messages are written during script execution (and not afterwards)
select((select(STDOUT), $|=1)[0]);

say "Generating buffer of size ".($buffer_size/1024)." KB...";

# initialize buffer
my $buffer = "";
for (my $i = 0; $i < $buffer_size; $i++) {
  # generate random ascii character
  $buffer .= chr(32 + int(rand(128 - 32)));
}
my $buffer_offset = 0; # position in buffer

# TODO: add option to create binary data

################################################################################
# GENERATE FILES
################################################################################

say "Generating $out_number files of random size in $out_directory with suffix $out_suffix...";

# process files
for (my $i = 0; $i < $out_number; $i++) {
  # compute file name
	my $out_name = File::Spec->catfile($out_directory, "file_".$i.$out_suffix);

	# compute file size
	my $out_size = ($out_min_size + int(rand($out_off_size))) * 1024;

# TODO: if ($buffer_size == 0) generate buffer on the fly
	# generate buffer
#	my $outBuf = "";
#	for (my $j = 0; $j < $size; $j++) {
		# generate random byte
#		$outBuf .= chr(int(rand(256)));
#	}

	# open file
	open(FH, ">", $out_name)
		or die("Can't open $out_name: $!");

	# write buffer to file
	print(FH substr($buffer, $buffer_offset, $out_size))
    or die ("Can't write to $out_name: $!");
  $buffer_offset += $out_size; # increment position by requested file size

  # check to see if we've reached end of buffer
  if ($buffer_offset == $buffer_size) {
    $buffer_offset = 0; # reset position
  } else {
    # check to see if we've already gone beyond end of buffer
    while ($buffer_offset > $buffer_size) {
      # write remaining data from beginning of buffer
      print(FH substr($buffer, 0, $buffer_offset - $buffer_size))
        or die ("Can't write to $out_name: $!");
      $buffer_offset -= $buffer_size; # decrement position by actual buffer size
    }
  }

	# close file
	close(FH);
}

say "...done! Exiting.";

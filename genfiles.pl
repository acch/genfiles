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

# 1 mandatory commandline parameters
if (@ARGV < 1) {
  HELP_MESSAGE();
  exit 1;
}

# declare commandline parameters
our($opt_d, $opt_n, $opt_t);

# read commandline parameters
$Getopt::Std::STANDARD_HELP_VERSION = 1;
unless (getopts('n:t:')) {
  HELP_MESSAGE();
  exit 1;
}

# directory must begin with /
unless ($ARGV[0] && $ARGV[0] =~ "^/") {
  HELP_MESSAGE();
  exit 1;
}

# read options or use default
my $out_directory=$ARGV[0];
my $out_number=$opt_n||&DEFAULT_NUMBER;
my $out_type=$opt_t||&DEFAULT_TYPE;

if (&DEBUG) {
  say "d: ".$out_directory;
  say "n: ".$out_number;
  say "t: ".$out_type;
}

# compute full path to config file
my ($script_vol, $script_path) = File::Spec->splitpath($0);
$script_path = File::Spec->catpath($script_vol, $script_path, undef);
my $config_file_path = $script_path.&CONFIG_FILE;

# check config file
(-f $config_file_path)
  or die("Config file not found: ".$config_file_path."\n");

# read config file
my $config_file = Config::General->new(
  -ConfigFile => $config_file_path,
  -LowerCaseNames => 1);
my %config = $config_file->getall();

# read options from config file
my $out_suffix = $config{filetype}{$out_type}{suffix};
my $out_min_size = $config{filetype}{$out_type}{minsize}||0;
my $out_off_size = ($config{filetype}{$out_type}{maxsize}||0) - $out_min_size;

# make STDOUT handle hot
# so that messages are written during execution (not afterwards)
select((select(STDOUT), $|=1)[0]);

exit 0;
########################################

# process directories
for (keys $config{directory}) {
  # read options from config file
  my $dir = $_;
  my $num_files = $config{directory}{$dir}{count};
  my $suffix = $config{directory}{$dir}{suffix};
  $suffix or $suffix = &DEFAULT_SUFFIX;
  my $min_size = $config{directory}{$dir}{minsize};
  my $off_size = $config{directory}{$dir}{maxsize} - $min_size;

  print "Generating $num_files files of random size in $dir with suffix $suffix...\n";

  # create directory if it does not exist
  unless (-d $dir) {
    mkdir($dir)
      or die("Can't create $dir: $!");
  }

  # process files
  for (my $i = 0; $i < $num_files; $i++) {
  	# compute buffer size
  	my $size = $min_size;
  	$size += int(rand($off_size));
    $size *= 1024;

  	# compute filename
  	my $name = "file_".$i.$suffix;

  	# generate buffer
  	my $outBuf = "";
  	for (my $j = 0; $j < $size; $j++) {
  		# generate random byte
  		$outBuf .= chr(int(rand(256)));
  	}

  	# open file
  	open(FH, ">", $dir."/".$name)
  		or die("Can't open $dir.$name: $!");

  	# write buffer to file
  	print(FH $outBuf);

  	# close file
  	close(FH);
  }
};

print "...done! Exiting.\n";

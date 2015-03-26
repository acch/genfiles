#!/usr/bin/perl

use strict;
use warnings;

# default options
use constant {
  DEFAULT_CONFIG_FILE => "genfiles.conf",
  DEFAULT_SUFFIX => ".tmp"
};

# make STDOUT handle hot
select((select(STDOUT), $|=1)[0]);

# check number of commandline parameters
(@ARGV <= 1)
  or die("Usage: $0 [<config_file>]\n");

# read parameters or use default
my $config_file = $ARGV[0];
$config_file or $config_file = &DEFAULT_CONFIG_FILE;

# check config file
(-f $config_file)
  or die("Config file not found: $config_file\n");

# read config file
use Config::General;
my $conf = Config::General->new(
  -ConfigFile => $config_file,
  -LowerCaseNames => 1);
my %config = $conf->getall;

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

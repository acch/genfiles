#!/usr/bin/perl

use strict;
use warnings;

die("Usage: $0 <directory> <number_of_files> [<name_suffix>]\n")
  unless (@ARGV == 2) || (@ARGV == 3);

die("Config file not found: genfiles.conf\n")
  unless (-f "genfiles.conf");

use Config::General;
my $conf = Config::General->new(
  -ConfigFile => "genfiles.conf",
  -LowerCaseNames => 1);
my %config = $conf->getall;

my($dir, $num_files, $suffix) = @ARGV;
$suffix or $suffix = ".tmp";

# set min size in KB
my $min_size = 100;
# set max offset size in KB
my $off_size = 1000;

print "Generating $num_files files, at random size in $dir with suffix $suffix...\n";

# check to see if directory exists
unless (-d $dir) {
  mkdir $dir
    or die("Can't create $dir: $!");
}

for(my $i = 0; $i < $num_files; $i++) {
	# compute buffer size
	my $size = $min_size * 1024;
	$size += int(rand($off_size)) * 1024;

	# compute filename
	my $name = "file_$i$suffix";

	# generate buffer
	my $outBuf = "";
	for(my $j = 0; $j < $size; $j++) {
		# generate random character
		$outBuf .= chr(int(rand(256)));
	}

	# open file
	open(FH, ">", $dir.$name)
		or die("Can't open $dir.$name: $!");

	# write buffer to file
	print(FH $outBuf);

	# close file
	close(FH);
}

print "...done! Exiting.\n";

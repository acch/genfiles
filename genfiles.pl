#!/usr/bin/perl

die("usage: $0 <directory> <number_of_files> [<name_suffix>]\n")
  unless (@ARGV == 2) || (@ARGV == 3);

my($dir, $num_files, $suffix) = @ARGV;
$suffix or $suffix = ".tmp";

#set min size in KB
$min_size = 100;
# set max offset size in KB
$off_size = 1000;

print "Generating $num_files files, at random size in $dir with suffix $suffix.\n";

for($i = 0; $i < $num_files; $i++) {
	# Compute buffer size
	$size = $min_size * 1024;
	$size += int(rand($off_size)) * 1024;

	# Compute filename
	my $name = "file_$i$suffix";

	# Generate buffer
	$outBuf = "";
	for($j = 0; $j < $size; $j++) {
		# Generate random character
		$outBuf .= chr(int(rand(256)));
	}

	# Open file
	open(FH, ">", $dir.$name)
		or die("Can't open $dir.$name: $!");

	# Write buffer to file
	print(FH $outBuf);

	# Close file
	close(FH);
}

print "...done! Exiting.\n";

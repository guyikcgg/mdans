#!/usr/bin/perl

# Libraries
use Getopt::Long;

# Global variables
my $imgpath = "img";
my $allpaths = "";

# Usage
sub Usage {
	print 
"Usage:\n
\t$0 [--img-path\t<path to img directory (relative to .tex file)>] TeXfile\n";
}

# Get the options
#    img-path      path to img directory (relative to .tex file)
GetOptions("img-path=s" => \$path) 
or die Usage();

# Read `filename` parameter
my $filename = @ARGV[0] 
or die "No input file was specified\n";

# Open the file into `MYINPUTFILE`
open(MYINPUTFILE, "<$filename")
or die "Couldn't open '$filename' for input. Is it a valid file?\n";

# Read file into list
my(@lines) = <MYINPUTFILE>;

# Get a string including the complete path of every line in the file
# containing the 'path to img directory' indicated in the parameters
foreach(@lines) {
	# Get the current line
	my $img = $_;
	# Check that the current line contains `imgpath`
	if ($img =~ /$imgpath/) {
		# Trim line. Get only the part after 'filename' (Only for LyX)
		if ($img =~ m/filename.(.*)/) {
			# Get the string in the first group defined in the regular expression above (.*) i.e. the rest of the line.
			my $path = $1;
			# Concatenate the selected string into `allpaths` variable
			$allpaths = $allpaths . " " . $path;
		}
	}
}

# Print `allpaths` to STDOUT
print "$allpaths";

# Close the file
close(MYINPUTFILE);

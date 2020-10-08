#!usr/bin/perl
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;


##############################
# By Matt Cannon
# Date:
# Last modified:
# Title: .pl
# Purpose:
##############################

##############################
# Options
##############################


my $verbose;
my $help;
my $namesFile;
my $fastaFile;
my $cutoff = 1;
my $output = "filterMotherOut";

# This script takes the output from mothur and screens out any reads with less than X total occurences. 
# syntax should be perl filterMothurByCount.pl 10 file.fa.gz file.names.gz > output.fa


# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
	    "names=s"           => \$namesFile,
	    "fasta=s"           => \$fastaFile,
	    "cutoff=i"          => \$cutoff,
	    "output=s"          => \$output

      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %namesHash;
$fastaFile =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;
$namesFile =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;

##############################
# Code
##############################


##############################
### Stuff
### More stuff

open INPUTFILE, "$namesFile" or die "$OS_ERROR Could not open names input\nWell, crap\n";
while (my $input = <INPUTFILE>){
    chomp $input;
    my (undef, $namesList) = split "\t", $input;
    my @names = split ",", $namesList;
    if(scalar(@names) > $cutoff) {
        $namesHash{$names[0]}=$input;
    }
}
close INPUTFILE;



##prep the files for writing out
my $r2fileName = $output . "Unique.filtered.fa";
my $r1fileName = $output . "Filtered.names";

open my $r1File, '>', "$r1fileName";
open my $r2File, '>', "$r2fileName";

local $/ = "\n>"; #change the input delimiter to \n> so the script pulls in the whole fasta entry

open INPUTFILE2, "$fastaFile" or die "$OS_ERROR Could not open fasta input\nWell, crap\n";
while (my $input = <INPUTFILE2>){
    chomp $input;
    my ($header,$sequence) = split "\n", $input;
    if(exists($namesHash{$header})) {
        print $r2File ">".$input,"\n";
	print $r1File $namesHash{$header}, "\n";
    }
}

close INPUTFILE2;



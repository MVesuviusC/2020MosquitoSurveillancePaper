#!/usr/bin/perl
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
# Purpose: #this script takes in a list of primers in the format primerName ForwardPrimer ReversePrimer (on each line) and a number denoting how much of the 3' end to use for matching, then it takes in a fastq file and cuts off any primers 
#the program should be run like: perl CutOffSequencFromFastqV1.pl 10 primerlist.txt sampleID-SE[1or2].fastq.gz > output.txt
#the output is a fastq file with the sequence and quality trimmed and the sample ID (from file name) and primer added to the header
#    ## You will want to screen out hits with "noPrimer" in the primer slot of the header afterwards.

##############################

##############################
# Options
##############################


my $verbose;
my $help;
my $lengthOfPrimerToMatch = 15;
my $primerFile;
my $fastqIn;
my $label = "MattRocks";

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
	    "matchLen=i"        => \$lengthOfPrimerToMatch,
	    "primers=s"         => \$primerFile,
	    "fastq=s"           => \$fastqIn,
	    "label=s"           => \$label,

      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################

my %primerHash;
my %degeneratehash = ( #hash of arrays - degenerate bases with matching bases
		       W => "[AT]",
		       S => "[CG]",
		       M => "[AC]",
		       K => "[GT]",
		       R => "[AG]",
		       Y => "[CT]",
		       B => "[CGT]",
		       D => "[AGT]",
		       H => "[ACT]",
		       V => "[ACG]",
		       I => "[ACGT]",
		       N => "[ACGT]"
		       );


##############################
### Go through the primer, and find any degenerate bases
### and replace with regex

if($verbose) {
    print STDERR "Parsing primer input\n";
}

open PRIMERFILE, "$primerFile" or die "$OS_ERROR Could not open primer input\nWell, crap\n";
while (my $input = <PRIMERFILE>){
    chomp $input;
    my ($primerName, $primerF, $primerR) = split " ", $input;
    dealWithDegenerates($primerF, $primerName);
    dealWithDegenerates($primerR, $primerName);
}

sub dealWithDegenerates {
    my $primer = $_[0];
    my $primerName = $_[1];

    my $primerLength = length($primer);

    # trim primer
    if(length($primer) > $lengthOfPrimerToMatch) {
	$primer = substr($primer, 0, $lengthOfPrimerToMatch);
    }

    if($primer =~ /[WSMKRYBDHVIN]/) { #if the primer has any degenerate bases, deconvolute those and add the subsequent primers to the hash
	my @primerArray = split "", $primer; #make an array containing the degenerate primer
	for(my $i = 0; $i < scalar(@primerArray); $i++) { # sort through primerArray
	    if($primerArray[$i] =~ /[WSMKRYBDHVIN]/) { 
		$primerArray[$i] = $degeneratehash{$primerArray[$i]};
	    } 
	}
	$primer = join("", @primerArray);
    }
    $primerHash{$primer}{primerName} = $primerName;
    $primerHash{$primer}{length} = $primerLength;
}

if($verbose) {
    for my $primerSeq (keys %primerHash) {
	print STDERR join("\t", $primerSeq, $primerHash{$primerSeq}{primerName}, $primerHash{$primerSeq}{length}) . "\n";
    }
}

close PRIMERFILE;

##############################
### Now, pull in the fastq 

$fastqIn =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;

my $line = 1;
my $storage;

open FASTQINPUTFILE, "$fastqIn" or die "$OS_ERROR Could not open fastq input\nWell, crap\n";
while (my $input = <FASTQINPUTFILE>){
    chomp $input;
    if($line == 1) {
	$storage = $input;
    } elsif($line < 4) {
	$storage = join("\t", $storage, $input);
    } elsif($line == 4) {
	$storage = join("\t", $storage, $input);
	trimSequence($storage);
	$line = 0;
    }
    $line++;
}

sub trimSequence {
    my $fastq = shift;
    my ($header, $sequence, $header2, $quality) = split "\t", $fastq;
    my @trimmedSeqPrimerQual = searchSequenceForPrimer($sequence, $quality);
    my $newHeader = $header;
    $newHeader = $newHeader . "|" . $trimmedSeqPrimerQual[1] . "|" . $label;
    my $newfastq = join("\n", $newHeader, $trimmedSeqPrimerQual[0], "+", $trimmedSeqPrimerQual[2]);
    print $newfastq, "\n";
}

sub searchSequenceForPrimer {
    my $sequence = shift;
    my $qual = shift;
    my $trimSeq;
    my $trimQual;
    my $primerHit = "noPrimer";
    my @returnValue; 
    for my $primerSeq (keys %primerHash) {
	my $revCompSeq = revComp($sequence);
	if($sequence =~ /^$primerSeq/) {
	    $trimSeq = substr($sequence, $primerHash{$primerSeq}{length});
	    $trimQual = substr($qual, $primerHash{$primerSeq}{length});
	    $sequence = $trimSeq;
	    $qual = $trimQual;
	    $primerHit = $primerHash{$primerSeq}{primerName};
	    
	} elsif($revCompSeq =~ /^$primerSeq/) {
	    $trimSeq = substr($sequence, 0, -1 * $primerHash{$primerSeq}{length});
	    $trimQual = substr($qual, 0, -1 * $primerHash{$primerSeq}{length});
	    $sequence = $trimSeq;
	    $qual = $trimQual;
	    $primerHit = $primerHash{$primerSeq}{primerName};
	}
    }
    @returnValue = ($sequence, $primerHit, $qual);
    return @returnValue;
}

sub revComp{
    my $seq = shift;
    $seq =~ tr/ACGTacgt/TGCAtgca/;
    reverse($seq);
}


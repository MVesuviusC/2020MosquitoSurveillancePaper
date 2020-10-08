#!/usr/bin/perl
use warnings;
use strict;
use English;

##format should be perl parseBlastWithNameFile.pl file.names file.blast.tab.gz > outputfile.txt

my %readNameHash;
my %readLengthHash;
my $newRead;
my $maxBitscore;

@ARGV = map { s/(.*\.gz)\s*$/gzip -dc < $1|/;$_ } @ARGV;

my $inputFileName = shift;
open INPUTFILE, "$inputFileName" or die "$OS_ERROR Could not open first input\nWell, crap\n";
while (my $input = <INPUTFILE>){
    chomp $input;
    countReadsPerLine($input);
}
close INPUTFILE;

$inputFileName = shift;
open INPUTFILE, "$inputFileName" or die "$OS_ERROR Could not open first input\nWell, crap\n";
local $/ = "\n>"; #change the input delimiter to > so the script pulls in the whole fasta entry
while (my $input = <INPUTFILE>){
    chomp $input;
    my ($readName, $sequence) = split "\n", $input;
    $readName =~ s/>//;
    $readName =~ s/:1\|.+/:1/; # cut off sample info
    $readLengthHash{$readName} = length($sequence);
}
close INPUTFILE;

local $/ = "\n";
print "#primerSample\tcount\tgi\tblastedReadName\tidentity\talignmentlength\tmismatches\tgapopens\tqstart\tqend\tsstart\tsend\tevalue\tbitscore","\n"; #header

my $inputFile2Name = shift;
open INPUTFILE2, "$inputFile2Name" or die "$OS_ERROR Could not open second input\nWell, crap\n";
while (my $input = <INPUTFILE2>){
    chomp $input;
    goThroughBlast($input);
}
close INPUTFILE2;

sub countReadsPerLine {
    my ($firstRead, $theRest) = split "\t", $_[0];
    $firstRead =~ s/:1\|.+/:1/;
    my @readNameArray = split ",", $theRest;
    for(@readNameArray) {
        s/^.+?\|//;
    } 
    for(my $i = 0; $i < @readNameArray; $i++){
        $readNameHash{$firstRead}{$readNameArray[$i]}++;
    }
}

sub goThroughBlast {
    if($_[0] =~ /^\#/){
        $newRead = 1;
    } else {
        processBlast($_[0]);
    }
}

sub processBlast {
    if($newRead == 1) {
        processFirstRead($_[0]);
    } else {
        processOtherReads($_[0]);
    }
}

sub processFirstRead {
    my ($queryid, $subjectid, $identity, $alignmentlength, $mismatches, $gapopens, $qstart, $qend, $sstart, $send, $evalue, $bitscore) = split "\t", $_[0];
    $maxBitscore = $bitscore;
    $queryid =~ s/:1\|.+/:1/;
    $subjectid =~ s/gi\|//;
    $subjectid =~ s/\|.+//;
    $identity = ((($qend - $qstart +1) - $mismatches - $gapopens)/ $readLengthHash{$queryid}) * 100;
    printHit($queryid, $subjectid, join("\t", $identity, $alignmentlength, $mismatches, $gapopens, $qstart, $qend, $sstart, $send, $evalue, $bitscore)); 
    $newRead = 0;
}

sub processOtherReads {
    my ($queryid, $subjectid, $identity, $alignmentlength, $mismatches, $gapopens, $qstart, $qend, $sstart, $send, $evalue, $bitscore) = split "\t", $_[0];
    if($bitscore == $maxBitscore) {
    $queryid =~ s/:1\|.+/:1/;
    $subjectid =~ s/gi\|//;
    $subjectid =~ s/\|.+//;
    $identity = ((($qend - $qstart +1) - $mismatches - $gapopens)/ $readLengthHash{$queryid}) * 100;
    printHit($queryid, $subjectid, join("\t", $identity, $alignmentlength, $mismatches, $gapopens, $qstart, $qend, $sstart, $send, $evalue, $bitscore)); 
    }
}

sub printHit {
    for my $primerSample (keys %{$readNameHash{$_[0]}}) {
        print join("\t", $primerSample, $readNameHash{$_[0]}{$primerSample}, $_[1], $_[0], $_[2]) . "\n";
    }
}


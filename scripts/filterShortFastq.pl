#!usr/bin/perl
use strict;
use warnings;
use English;

#this script takes in a fastq file and removes any entries where the sequnce length is less than the given cutoff 
##usage should be perl filterShortFastq.pl 50 file_SE1.fastq.gz 


my $line =1;
my $storage;

my $minLength = shift;

while (my $input = <>){
    chomp $input;
    if($line==1) {
        $storage=$input;
    } elsif($line<4) {
        $storage = join("\n",$storage, $input);
    } elsif($line==4) {
        $storage = join("\n",$storage, $input);
        printGoodLines($storage);
        $line=0;
    }
    $line++;
}


sub printGoodLines {
    my $fastq = shift;
    my ($header, $sequence, $header2,$quality) = split "\n", $fastq;
    if(length($sequence)>=$minLength) {
        print $fastq, "\n";
    }
}

exit;

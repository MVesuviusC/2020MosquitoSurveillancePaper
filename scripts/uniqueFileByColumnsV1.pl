#!/usr/bin/perl
use strict;
use English;
use warnings;

# This script takes in a list of columns (WITH NO SPACES) and a file, and keeps one of each occurence of the combination of the value of those columns. It always keeps the first occurence. 
# Syntax should be perl uniqueFileByColumnsV1.pl 1,3,5-10 fileIn.txt > fileOut.txt
# Note that the list of columns is separated by columns, and can include ranges if they are separated by a "-".

my %columnsHash;
my $cutcolumns = shift;
my @selectionColumns = split ",", $cutcolumns;

my @tempArray;
for(my $i=0;$i<@selectionColumns;$i++) {
    if($selectionColumns[$i] =~ /-/){
        my ($start,$stop) = split "-", $selectionColumns[$i];
        for(my $j=$start;$j<=$stop;$j++) {
            push(@tempArray,$j);
        }
    } else {
        push(@tempArray,$selectionColumns[$i]); 
    }
    
}
@selectionColumns=@tempArray;


@ARGV = map { s/(.*\.gz)\s*$/gzip -dc < $1|/;$_ } @ARGV;

my $inputFileName2 = shift;

open INPUTFILE2, "$inputFileName2" or die "$OS_ERROR Could not open first input\nWell, crap\n";
while (my $input = <INPUTFILE2>){
    chomp $input;
    my $hashKey="";
    my @columns = split "\t", $input;
    for(@selectionColumns){
        $hashKey = join("",$hashKey,$columns[$_-1]);
    }
    if(!exists($columnsHash{$hashKey}) ) {
        print $input, "\n";
        $columnsHash{$hashKey}=1;
    }
}

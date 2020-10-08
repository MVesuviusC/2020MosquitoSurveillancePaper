#!/usr/bin/perl
use strict;
use warnings;

## This script takes in the blast results from 

my %storagehash;

while(my $input = <>) {
    chomp $input;
    if($input =~ /^#/) {
       print $input, "\n";
   } else {
       my @columns = split "\t", $input;
       my $readname = $columns[2];
       my $sample = $columns[0];
       if(exists $storagehash{join("",$readname,$sample)}) {
	   $input=concatenateDifferences($input); #compare the stored information, and add any differences to the line, adding a "/" between
	   $storagehash{join("",$readname,$sample)}=$input;
       } else {
	   $storagehash{join("",$readname,$sample)}=$input;
       }
   }
}

PrintSingleLevelHash(%storagehash);

sub concatenateDifferences {
    my $data=shift;
    my @columnsToAdd = split "\t", $data;
    my $readname = $columnsToAdd[2];
    my $sample = $columnsToAdd[0];
    my @columnsInHash = split "\t", $storagehash{join("", $readname, $sample)};
    for(my $i = 0; $i < scalar(@columnsToAdd); $i++){
        if($columnsInHash[$i] !~ /\Q$columnsToAdd[$i]\E/) {
            $columnsInHash[$i] = join("/", $columnsInHash[$i], $columnsToAdd[$i]);
        }
    }
    return join("\t", @columnsInHash);
}

sub PrintSingleLevelHash {
    my %hash = @_;
    for my $keys (keys %hash) {
        print $hash{$keys} . "\n";
    }
}

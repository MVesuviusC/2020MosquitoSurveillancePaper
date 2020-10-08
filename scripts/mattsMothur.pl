#!/usr/bin/perl
use strict;
use warnings;

local $/ = "\n>"; #change the input delimiter to > so the script pulls in the whole fasta entry

#This script takes in fasta files and keeps one unique sequence 
#Outputs files identical to Mothur's unique.seqs: .names and .unique.fasta

my %storageHash;
my %headerStorage;
my $counter=0;
my $uniqueCounter=0;

my $FileName = shift;

if($FileName eq "--help") { #ha!
    die "What, do you need me to hold your hand?!?!?!?!\nJust give me a damn fasta file!\n";
} elsif($FileName eq "--version") {
    die "It's rude to ask someone's age.\n"
}

open FILE, "$FileName" or die "Could not open $FileName\nWell, crap.....\n";

while(my $file = <FILE>){
    $counter++;
    chomp $file;
    my ($header,$seq)=split "\n", $file,2;
    $header =~ s/^>//;
    die "Duplicate fasta headers detected\n" if exists($headerStorage{$header});
    $headerStorage{$header}=1;
    $seq =~ s/\n//g; #get rid of extra newlines in sequence
    if( !exists($storageHash{$seq}) & !exists($storageHash{revcomp($seq)}) ) { 
	$storageHash{$seq}=$header;
	$uniqueCounter++;
    } elsif( exists($storageHash{$seq}) ) {
	$storageHash{$seq}=join("\t",$storageHash{$seq},$header);
    } elsif( exists( $storageHash{revcomp($seq)} ) ) {
	$storageHash{$seq}=join("\t",$storageHash{revcomp($seq)},$header);
    }
    #print STDERR "\e[JSequences analyzed:\t",commify($counter),"\tUnique Sequences:\t",commify($uniqueCounter),"\r";
}

$FileName =~ s/\.fasta//;
$FileName =~ s/\.fa//;
open my $fastaOutputFile, ">", join(".",$FileName,"unique.fasta");
open my $namesOutputFile, ">", join(".",$FileName,"names");

#print STDERR "Printing output\n";

for my $sequence (keys %storageHash) {
    my $firstHeader = $storageHash{$sequence};
    $firstHeader =~ s/\t.+//;
    print $fastaOutputFile ">",$firstHeader,"\n",$sequence,"\n";
    print $namesOutputFile $firstHeader,"\t", join(",", split("\t", $storageHash{$sequence}) ),"\n";
}

#print STDERR "Done!\nSequences analyzed:\t",commify($counter),"\tUnique Sequences:\t",commify($uniqueCounter),"\n";

sub revcomp {
    my $seq = shift;
    $seq =~ tr/ATGCatgc/TACGtacg/;
    my $seqOut = reverse($seq);
    return $seqOut;
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text
}

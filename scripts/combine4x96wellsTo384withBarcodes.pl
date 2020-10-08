#!/usr/bin/perl
use warnings;
use strict;
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
my $p1;
my $p2;
my $p3;
my $p4;
my $bcInfo;
my $plateMap384 = "";


# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "P1=s"		=> \$p1,
            "P2=s"		=> \$p2,
            "P3=s"		=> \$p3,
            "P4=s"		=> \$p4,
            "barcodes=s"	=> \$bcInfo,
	    "plateMap384=s"     => \$plateMap384
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my $row = 1;
my %plate;
my %bcHash;

##############################
# Code
##############################


##############################
### Read in plates
### there is probably a smarter way to do than than copying and pasting but meh

#### plate 1 -- row -> X2 -1     column -> X2 - 1
open PLATE1FILE, "$p1" or die "Could not open first plate\nWell, crap\n";
while (my $input = <PLATE1FILE>){
    chomp $input;
    my $plateRow = ($row * 2) - 1;
    my @columns = split "\t", $input;
    for (my $i = 0; $i < scalar(@columns); $i++) {
        my $plateCol = (($i + 1) * 2) - 1;
        $plate{$plateRow}{$plateCol} = $columns[$i];
    }
    $row++;
}
close PLATE1FILE;
$row = 1;

#### plate 2 -- row -> X2 -1     column -> X2
open PLATE2FILE, "$p2" or die "Could not open second plate\nWell, crap\n";
while (my $input = <PLATE2FILE>){
    chomp $input;
    my $plateRow = ($row * 2) - 1;
    my @columns = split "\t", $input;
    for (my $i = 0; $i < scalar(@columns); $i++) {
        my $plateCol = ($i + 1) * 2;
        $plate{$plateRow}{$plateCol} = $columns[$i];
    }
    $row++;
}
close PLATE2FILE;
$row = 1;

#### plate 3 -- row -> X2     column -> X2 - 1
open PLATE3FILE, "$p3" or die "Could not open third plate\nWell, crap\n";
while (my $input = <PLATE3FILE>){
    chomp $input;
    my $plateRow = $row * 2;
    my @columns = split "\t", $input;
    for (my $i = 0; $i < scalar(@columns); $i++) {
        my $plateCol = (($i + 1) * 2) - 1;
        $plate{$plateRow}{$plateCol} = $columns[$i];
    }
    $row++;
}
close PLATE3FILE;
$row = 1;

#### row -> X2     column -> X2
open PLATE4FILE, "$p4" or die "Could not open fourth plate\nWell, crap\n";
while (my $input = <PLATE4FILE>){
    chomp $input;
    my $plateRow = $row * 2;
    my @columns = split "\t", $input;
    for (my $i = 0; $i < scalar(@columns); $i++) {
        my $plateCol = ($i + 1) * 2;
        $plate{$plateRow}{$plateCol} = $columns[$i];
    }
    $row++;
}
close PLATE4FILE;
$row = 1;

##############################
### Read in barcode plate
### 

open BARCODEFILE, "$bcInfo" or die "Could not open barcode file\nWell, crap\n";
while (my $input = <BARCODEFILE>){
    chomp $input;
    my ($rowBcName, $rowBc, $colBcName, $colBc) = split "\t", $input;
    if($row <= 16) {
        $bcHash{row}{$row} = $rowBc;
    }
    $bcHash{column}{$row} = $colBc;
    $row++;
}
close BARCODEFILE;

##############################
### Print out everything
### 
if($plateMap384 ne "") {
    open PLATEMAP384, ">", $plateMap384 or die "Could not write to plateMap384 file\nWell, crap\n";
}


for my $row (1..16) {
    for my $column (1..24) {
        print $plate{$row}{$column}, "\t", $bcHash{column}{$column}, "\t", $bcHash{row}{$row}, "\n";
	if($plateMap384 ne "") {
	    print PLATEMAP384 $plate{$row}{$column}, "-", $bcHash{row}{$row}, "-", $bcHash{column}{$column}, "\t";
	}
    }
    print PLATEMAP384 "\n";
}


#open R1OUTFILE, ">", $outputNameStub . "_R1.fastq";

##############################
# POD
##############################

#=pod
    
=head SYNOPSIS

Summary:    
    
    xxxxxx.pl - generates a consensus for a specified gene in a specified taxa
    
Usage:

    perl xxxxxx.pl [options] 


=head OPTIONS

Options:

    --verbose
    --help

=cut

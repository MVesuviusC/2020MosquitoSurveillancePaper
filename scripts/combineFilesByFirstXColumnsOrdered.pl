#!/user/bin/perl
use strict;
use warnings;
use English;

###this script takes files and combines them by the first X tab separated columns.
###the first file should be the smaller of the two, or the file with single combination of the first X columns
###Assumes that the combination of the first X columns for each row are unique for the first file.
###usage is: perl combineFilesByFirstXColumns.pl 3 file.txt file2.txt > output.txt

my %methHash;

my %rows;
my $fileNumber = 1;
my @fileArray;
my $ncol=shift;
my $totalNcol;

@ARGV = map { s/(.*\.gz)\s*$/gzip -dc < $1|/;$_ } @ARGV;
my @files = @ARGV;

my $InputFile = shift;
open INPUT, "$InputFile" or die "$OS_ERROR Could not open $InputFile\nWell, crap\n";
while (my $input=<INPUT>) {
    chomp $input;
    my @columns = split("\t", $input);
    $totalNcol=scalar(@columns);
    my $reference = join("\t",@columns[0..($ncol-1)]);
    $rows{$reference}=join("\t",@columns[$ncol..(scalar(@columns)-1)]);
}
close INPUT;

$InputFile = shift;
open INPUT, "$InputFile" or die "$OS_ERROR Could not open $InputFile\nWell, crap\n";
while (my $input=<INPUT>) {
    chomp $input;
    my @columns = split("\t",$input);
    $totalNcol=scalar(@columns);
    my $reference = join("\t",@columns[0..($ncol-1)]);
    if(exists($rows{$reference})){
	print join("\t",$input,$rows{$reference})."\n";
    } #else {
#	print "\tNA" x ($totalNcol-$ncol);
#    }
}



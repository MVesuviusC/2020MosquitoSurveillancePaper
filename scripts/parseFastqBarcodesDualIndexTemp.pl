#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;

##############################
# By Matt Cannon
# Date: 05/10/2017
# Last modified: 05/10/2017
# Title: parseFastqBarcodesDualIndex.pl
# Purpose: Parse fastq files to separate files by barcodes
##############################

##############################
# Options
##############################


my $verbose;
my $help;
my $keyFile;
my $R1;
my $R2;
my $I5;
my $I7;
my $outdir = "parsedFastqFiles";
my $errors = 0;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "keyFile=s"         => \$keyFile,
            "R1=s"              => \$R1,
            "R2=s"              => \$R2,
            "I5=s"              => \$I5,
            "I7=s"              => \$I7,
            "outdir=s"          => \$outdir,
	    "errors=i"          => \$errors
            )
or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);

##############################
# Global variables
##############################
my %barcodeHash;
my %barcodeCountHash;
my %outputFileHash;
my $counter = 1;
my $foundCounter = 0;
my %linesToPrint;

##############################
# Code
##############################

##############################
### Let the script read in gzipped files
$R1 =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;
$R2 =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;
$I5 =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;
$I7 =~ s/(.*\.gz)\s*$/gzip -dc < $1|/;

##############################
### Make the output folder

if($verbose) {
    print STDERR "\n\nOutput files will be written to $outdir\n";
    print STDERR "Make sure you have deleted any previously parsed files, as this script will simply append the new parse to the old one\n";
}

mkdir $outdir; #output folder

##############################
### Read in key file and create hash of barcodes with output file as value
### This information should be tab delimited, with sample\tRevComplBarcodeI5\tRevComplBarcodeI7
if($verbose) { 
    print STDERR "Reading key file\n";
}
open KEYFILE, $keyFile or die "Could not open sample-barcode key file\nWell, crap\n";
while (my $input = <KEYFILE>){
    chomp $input;
    my ($sampleID, $barcodeI5, $barcodeI7) = split "\t", $input;
    if($errors > 0) {
	my @I5array = ($barcodeI5);
	my @I7array = ($barcodeI7);
	for(my $i = 0; $i < $errors; $i++) {
	    @I5array = oneOff(@I5array);
	    @I7array = oneOff(@I7array);
	}

	for my $I5current (@I5array) {
	    for my $I7current (@I7array) {
		$barcodeHash{$I5current . $I7current} = $sampleID;
	    }
	}
    } else {
	$barcodeHash{$barcodeI5 . $barcodeI7} = $sampleID;
    }
}
close KEYFILE;
$barcodeHash{"unknownunknown"} = "unknownBarcodes";

##############################
### Make up a hash of data to print
if($verbose) { 
    print STDERR "Prepping output files\n";
}

for my $barcode (keys %barcodeHash) {
    @{ $linesToPrint{$barcode}{R1} } = ();
    @{ $linesToPrint{$barcode}{R2} } = ();
}
@{ $linesToPrint{unknownunknown}{R1} } = ();
@{ $linesToPrint{unknownunknown}{R2} } = ();

##############################
### Open the fastq files and print out output files
if($verbose) {
    print STDERR "Parsing fastq files\n";
}

open my $I5FILE, $I5 or die "Could not open I5 file\n";
open my $I7FILE, $I7 or die "Could not open I7 file\n";
open my $R1FILE, $R1 or die "Could not open R1 file\n";
open my $R2FILE, $R2 or die "Could not open R2 file\n";

#Go through the I files and pull in the matching R1 and R2 entries
while (my $iFileLine = <$I5FILE>) { 
    my @i5Lines = getThreeLines($I5FILE); #get the next three I5 lines
    unshift(@i5Lines, $iFileLine); # put all the I5 lines together
    chomp @i5Lines;
    my $I5barcode = $i5Lines[1];
    my @i7Lines = getFastq($I7FILE);
    my $I7barcode = $i7Lines[1];
    my @r1Lines = getFastq($R1FILE);
    my @r2Lines = getFastq($R2FILE);
    if(checkHeaders($i5Lines[0], $i7Lines[0], $r1Lines[0], $r2Lines[0]) == 1) { #Check to be sure that I5, I7, R1 and R2 all are the same read
        print STDERR "Your files are not sorted properly, I need the headers for I5, I7, R1 and R2 to be in an identical order\n";
        die; 
    }
    $r1Lines[0] = join(":", $r1Lines[0], $I5barcode, $I7barcode);
    $r2Lines[0] = join(":", $r2Lines[0], $I5barcode, $I7barcode);
    if(exists($barcodeHash{$I5barcode . $I7barcode})) { #write the read out to a file with the sample name if the barcode exists in the input list
        printLines($I5barcode, $I7barcode, "R1", join("\n", @r1Lines));
        printLines($I5barcode, $I7barcode, "R2", join("\n", @r2Lines));
        $barcodeCountHash{$barcodeHash{$I5barcode . $I7barcode}}++;
	$foundCounter++;
    } else { #write the read out to an "unknownBarcode" file if the barcode is missing from the input list
        printLines("unknown", "unknown", "R1", join("\n", @r1Lines));
        printLines("unknown", "unknown", "R2", join("\n", @r2Lines));
        $barcodeCountHash{unknown}++; 
    }
    if($verbose) {
	if($counter % 10000 == 0) {
	    print STDERR commify($counter), " fastq entries processed. ", commify($foundCounter), " barcodes matched                             \r";
	}
	$counter++;
    }
}
print STDERR "Printing out final reads                                  \n";
close $I5FILE;
close $I7FILE;
close $R1FILE;
close $R2FILE;

# Print out the last of the lines
for my $barcode (keys %linesToPrint) {
    if(scalar(@{ $linesToPrint{$barcode}{R1} }) > 0) {
	open OUTPUTR1, '>>', $outdir . "/" . $barcodeHash{$barcode} . "R1.fastq";
	open OUTPUTR2, '>>', $outdir . "/" . $barcodeHash{$barcode} . "R2.fastq";
	print OUTPUTR1 join("\n", @{ $linesToPrint{$barcode}{R1} }),"\n";
	print OUTPUTR2 join("\n", @{ $linesToPrint{$barcode}{R2} }),"\n";
	close OUTPUTR1;
	close OUTPUTR2;
    }
}

if($verbose) {
    print STDERR "Printing out summary log file              \n";
}
# Print out summary
open my $barcodeLogFile, '>', $outdir . "/barcodeSummaryLog.txt";
for my $barcode (sort { $barcodeCountHash{$b} <=> $barcodeCountHash{$a} } keys %barcodeCountHash) {
    if(exists($barcodeHash{$barcode})) {
        print $barcodeLogFile $barcode, "\t", $barcodeHash{$barcode}, "\t", $barcodeCountHash{$barcode}, "\n";
    } else {
        print $barcodeLogFile $barcode, "\tUnknownSample\t", $barcodeCountHash{$barcode}, "\n";
    }
    
}
close $barcodeLogFile;

sub oneOff {
    my @bcArray = @_;
    my @newBCArray = @bcArray;
    my @baseArray = ("A", "T", "C", "G");
    for(my $i = 0; $i < scalar(@bcArray); $i++) {
	for(my $j = 0; $j < length($bcArray[$i]); $j++) {
	    my @currentBC = split "", $bcArray[$i];
	    for my $base (@baseArray) {
		if($base ne $currentBC[$j]) {
		    $currentBC[$j] = $base;
		    push @newBCArray, join("", @currentBC);
		}
	    }
	}
    }
    return @newBCArray;
}

sub getThreeLines {
    my $fh = shift;
    my @storage;
    for(my $i = 0; $i < 3; $i++){
        my $nextLine = <$fh>;
        push(@storage, $nextLine);
    }
    chomp @storage;
    return @storage;
}

sub getFastq {
    my $fh = shift;
    my @storage;
    for(my $i = 0; $i < 4; $i++) {
        my $nextLine = <$fh>;
        push(@storage, $nextLine);
    }
    chomp @storage;
    return @storage;
}

sub checkHeaders {
    my ($header1, $header2, $header3, $header4) = (@_);
    $header1 =~ s/\s.+//;
    $header2 =~ s/\s.+//;
    $header3 =~ s/\s.+//;
    $header4 =~ s/\s.+//;
    if($header1 ne $header2 | $header1 ne $header3 | $header1 ne $header4) {
        return 1;
    } else {
        return 0;
    }
}

sub printLines {
    my ($I5barcode, $I7barcode, $R1or2, $lines) = (@_);
    push @{ $linesToPrint{$I5barcode . $I7barcode}{$R1or2} }, $lines;
    if(scalar( @{ $linesToPrint{$I5barcode . $I7barcode}{$R1or2} } ) == 10000) {
	open OUTPUT, '>>', $outdir . "/" . $barcodeHash{$I5barcode . $I7barcode} . $R1or2 . ".fastq";
	print OUTPUT join("\n", @{ $linesToPrint{$I5barcode . $I7barcode}{$R1or2} }),"\n";
        @{ $linesToPrint{$I5barcode . $I7barcode}{$R1or2} } = ();
	close OUTPUT;
    }
}

sub commify { # function stolen from web
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}


##############################
# POD
##############################

=pod

=head NAME

parseFastqBarcodesDualIndex.pl - generates a consensus for a specified gene in a specified taxa

=head SYNOPSIS

perl parseFastqBarcodesDualIndex.pl [options] --keyFile <keyfile.csv> --I5 <I5.fastq.gz> --I7 <I7.fastq.gz> --R1 <R1.fastq.gz> --R2 <R2.fastq.gz>

=head OPTIONS

This script uses I5 and I7 fastq files to parse out R1 and R2 fastq files. A key file is also provided as input. The output is written to 
"parsedFastqFiles/" unless the user provides another output directory. B<Be careful when using this script. If files with the same name are
in the output directory the data will be appended to the end of those files instead of overwriting them. So if you rerun this script you can 
duplicate your reads accidentaly.> 

Options:

=over 4

=item B<--verbose>

    Provide detailed progress summary.

=item B<--help>

    This stuff.

=item B<--keyFile>

    Required. Tab delimited file with three columns. The first is the sample ID. The next two are the I5 and I7 barcodes for that sample. 

=item B<--R1>

    Required. R1 file. Can be gzipped.

=item B<--R2>

    Required. R2 file. Can be gzipped.

=item B<--I5>

    Required. I5 file. Can be gzipped.

=item B<--I7>

    Required. I7 file. Can be gzipped.

=item B<--outdir> ("parsedFastqFiles")

    Output directory. 

=item B<--errors> (0)

    Number of mismatches allowed within each barcode.

=back

=cut

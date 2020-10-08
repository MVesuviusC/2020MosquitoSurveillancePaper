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
my $sampleInfo;
my $data;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "sampleInfo=s"	=> \$sampleInfo,
            "data=s"		=> \$data
            
      )
 or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %sampleHash;
my %resultsHash;

##############################
# Code
##############################


##############################
### Stuff
### More stuff

open my $sampleInfoFH, "$sampleInfo" or die "Could not open sample info input\nWell, crap\n";
while (my $input = <$sampleInfoFH>){
    chomp $input;
    my ($oldName, $newName) = split "\t", $input;
    $sampleHash{$oldName} = $newName;
}

##############################
### Stuff
### More stuff

open my $dataFH, "$data" or die "Could not open data input\nWell, crap\n";
while (my $input2 = <$dataFH>){
    chomp $input2;
    if($input2 !~ /^Primer/) {
	my ($primer, $sample, $species, $kingdom, $phylum, $class, $order, 
	    $family, $count, $maxIdent, $maxAlignLen, $minSeqLength ) 
            = split "\t", $input2;
	
	$sample =~ s/.fastq.gz//;
	
	# Get rid of low and poorly identified stuff
	if($count >= 10 && $maxIdent >= 70) {
	    # get rid of positive and negative controls
	    if($sampleHash{$sample} !~ /negative/ && 
	       $sampleHash{$sample} !~ /ParasitePool/ && 
	       $sampleHash{$sample} !~ /H20/ && 
	       $sampleHash{$sample} !~ /Positive/ && 
	       $sampleHash{$sample} !~ /neg/ && 
	       $sampleHash{$sample} !~ /water/ ) {
		
		# assign group
		my $group;
		if($sample =~ /^DB/) {
		    $group = "Maryland";
		} elsif($sample =~ /^DNA/) {
		    $group = "Africa";
		} elsif($sample =~ /^Further/ || $sample =~ /^St-Laurent/) {
		    $group = "Cambodia";
		}
		
		my @genusArray = split "\/", $species;
		my %hitsHash;
		for my $element (@genusArray) {
		    $element =~ s/ .+//;
		    $hitsHash{$element} = 1;
		} 
		my @elementArray = sort keys %hitsHash;
		# make sure something is put in here to figure out which target this is from

		if($phylum eq "NA") {
		    $phylum = $order;
		    if($phylum eq "NA") {
		        $phylum = $family;
		    }
		    if($phylum eq "NA") {
		        $phylum = $primer;
		    }
		}
		
		$resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{samples}{$group}{$sample} = 1;
		
		if(defined($resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{max})) {
                    if($maxIdent > $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{max}) {
                        $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{max} = $maxIdent;
                    } 
                    if($maxIdent < $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{min}) {
                        $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{min} = $maxIdent;
                    }
                } else {
                    $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{max} = $maxIdent;
                    $resultsHash{genus}{$phylum . "\t" . join("/", @elementArray)}{min} = $maxIdent;
                }
	    }
	}
    }
}

##############################
### Stuff
### More stuff

print "0Primer\tGenus\tMaryland Samples\tMaryland Pools\tAfrica\tCambodia\tIdentity\n";

#for my $phylum (keys %{ $resultsHash{phylum} } {
#    for my $group ("Maryland", "Africa", "Cambodia") {
#	print $phylum "\t-\t", $resultsHash{phylum}{$phylum}{$group}, "\n";
#    }
#}
my %phylumHash;

for my $line (keys %{ $resultsHash{genus} }) {
    print $line;
    for my $group ("Maryland", "Africa", "Cambodia") {
        if(exists($resultsHash{genus}{$line})) {
            my @sampleList = keys %{ $resultsHash{genus}{$line}{samples}{$group} };
            print "\t", scalar(@sampleList);

	    my $phylum = $line;
	    $phylum =~ s/\t.+//;

	    for my $sample (@sampleList) {
		$phylumHash{$phylum}{$group}{$sample} = 1;
	    }

            if($group eq "Maryland") {
                my %tempHash;
                s/DB_C/DB_/ for @sampleList;
                for(@sampleList) {
                    $tempHash{$_} = 1;
		    $phylumHash{$phylum}{Pool}{$_} = 1;
                }
                my @poolList = keys %tempHash;
                print "\t", scalar(@poolList);
            }
        } else {
            print "\t0";
            if($group eq "Maryland") {
                print "\t0";
            }
        }
    }
    if($resultsHash{genus}{$line}{min} == $resultsHash{genus}{$line}{max}) {
        print "\t", sprintf("%.2f", $resultsHash{genus}{$line}{min}), "\%\n";
        if($resultsHash{genus}{$line}{min} == 0) {
            print STDERR "wtf\t$line\n";
            print STDERR $resultsHash{genus}{$line}{min}, "\t", $resultsHash{genus}{$line}{min}, "\n";
        }
    } else {
        print "\t", sprintf("%.2f", $resultsHash{genus}{$line}{min}), "\%-", sprintf("%.2f", $resultsHash{genus}{$line}{max}), "\%\n";
    }
}

for my $phylum (keys %phylumHash) {
    print $phylum, "\t-";
    for my $group ("Maryland", "Pool", "Africa", "Cambodia") {
	my @sampleList = keys %{ $phylumHash{$phylum}{$group} };
	print "\t", scalar(@sampleList);
	
    }
    print "\t-\n";
}


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

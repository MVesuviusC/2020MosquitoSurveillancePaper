#!/bin/bash
#$ -cwd
#$ -P dserre-lab
#$ -o PsQsubStdOut.txt
#$ -e PsQsubStdErr.txt
#$ -l mem_free=5G
#$ -q threaded.q
#$ -pe thread 15
#$ -sync y

parallel -j 10 'name={}; reverse=${name%%R1.fastq.gz}R2.fastq.gz; output=${name%%R1.fastq.gz}.fastq; output=${output##*/}; nice pandaseq -l 100 -t 0.2 -O 600 -F -L 500 -B -T 5 -f {} -r ${reverse} 2> output2/pandaseqd/${output}Log.txt | gzip > output2/pandaseqd/${output}.gz' :::: misc/inputFiles.txt
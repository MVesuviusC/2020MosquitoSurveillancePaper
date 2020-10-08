#!/bin/bash
#$ -cwd
#$ -P dserre-lab
#$ -o blastQsubStdOut.txt
#$ -e blastQsubStdErr.txt
#$ -l mem_free=10G
#$ -q threaded.q
#$ -pe thread 30
#$ -N blast
#$ -sync y
#$ -t 1-11
#$ -tc 5


fileList=(output2/blast/inputFiles/merged_products_*.fa)

for i in "${!fileList[@]}"; do 
  fileList[$i]="${fileList[$i]##*/}"
done

/usr/local/packages/ncbi-blast+-2.7.1/bin/blastn \
      -task blastn \
      -negative_gilist ~/SerreDLab-3/cannonm3/unculturedOrgs_8_16_18.gi \
      -db ~/SerreDLab-3/databases/blast/nt \
      -query output2/blast/inputFiles/${fileList[${SGE_TASK_ID} - 1]} \
      -num_threads 29 \
      -outfmt "7 qseqid sgi pident length mismatch gapopen qstart qend sstart send evalue bitscore" \
    | gzip \
    > output2/blast/output/${fileList[${SGE_TASK_ID} - 1]%Unique.filtered.fa}blastResults2.txt.gz



#!/usr/bin/env bash

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
genome=${subdir}/1_protein.coding.exons.gtf
countdir=${subdir}/2a_exoncounts

outfile1=${subdir}/2b_used.exons.txt
outfile2=${subdir}/2b_used.exons.gtf


# make list of used exons
cat ${countdir}/*.csv | sort -u > $outfile1
# filter the GTF file for lines with these exon ids
grep -Fwf $outfile1 $genome > $outfile2

#remove intermediate files
rm $outfile1

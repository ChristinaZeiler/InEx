#!/usr/bin/env bash

source config_bash.sh

#input_gtf="<your Ensembl GTF file>"
#dir="<your directory>"
subdir=${dir}/genome
outfile=${subdir}/1_protein.coding.exons.gtf

#create genome subdirectory in case it does not exist
mkdir -p $subdir

# Use awk to filter for protein_coding transcripts
awk -F '\t' 'BEGIN {OFS="\t"}
	($3=="exon" &&
	($9 ~ /"protein_coding"/ ||
	 $9 ~ /"protein_coding_LoF"/))' \
	$input_gtf > $outfile


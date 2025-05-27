#!/usr/bin/env bash

module load bedtools

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
exons=${subdir}/2f_exp.TVs.exons.gtf
exons_bed=${subdir}/4_exp.TVs.exons.bed
exons_unamb=${subdir}/4_unamb.exons.bed
introns=${subdir}/3_exp.TVs.introns.gtf
introns_bed=${subdir}/4_exp.TVs.introns.bed
introns_unamb=${subdir}/4_unamb.introns.bed

#Step 4a: convert GTF files to BED files and sort them by position
# exon annotations
awk -F'\t' 'BEGIN { OFS="\t" }
{
    split($9, a, "[ ;]");
    for (i = 1; i <= length(a); i++) {
    	if (a[i] == "gene_id") {
          gene_id = a[i+1];
          break;
          }
    }
    print $1, $4-1, $5, gene_id, ".", $7, "."
}' $exons | sort -k1,1 -k2,2n > $exons_bed
# intron annotations
awk -F'\t' 'BEGIN { OFS="\t" }
{
    split($9, a, "[ ;]");
    for (i = 1; i <= length(a); i++) {
    	if (a[i] == "gene_id") {
          gene_id = a[i+1];
          break;
          }
    }
    print $1, $4-1, $5, gene_id, ".", $7, "."
}' $introns | sort -k1,1 -k2,2n > $introns_bed


#Step 4b: remove overlapping parts between exon and intron annotations (ambiguous)
# remove overlapping parts from exon annotations
bedtools subtract -a $exons_bed -b $introns_bed -s > $exons_unamb
# remove overlapping parts from intron annotations
bedtools subtract -a $introns_bed -b $exons_bed -s > $introns_unamb


#Step 4c: count the lines to check the number of annotations in each of these files
line_count=$(wc -l < $exons)
echo "Number of lines in exons gtf file: $line_count"
line_count=$(wc -l < $exons_bed)
echo "Number of lines in exons bed file: $line_count"
line_count=$(wc -l < $exons_unamb)
echo "Number of lines in unambiguous exons bed file: $line_count"

line_count=$(wc -l < $introns)
echo "Number of lines in introns gtf file: $line_count"
line_count=$(wc -l < $introns_bed)
echo "Number of lines in introns bed file: $line_count"
line_count=$(wc -l < $introns_unamb)
echo "Number of lines in unambiguous introns bed file: $line_count"



#remove intermediate files
rm $exons_bed
rm $introns_bed

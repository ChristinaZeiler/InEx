#!/usr/bin/env bash

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
#input files
exons_unamb=${subdir}/4_unamb.exons.bed
introns_unamb=${subdir}/4_unamb.introns.bed
#intermediate files
exons_sorted=${subdir}"/5_unamb.ex.sort.bed"
introns_sorted=${subdir}"/5_unamb.in.sort.bed"
exons_col=${subdir}"/5_col.ex.bed"
introns_col=${subdir}"/5_col.in.bed"
exons_col_gtf=${subdir}"/5_col.ex.gtf"
introns_col_gtf=${subdir}"/5_col.in.gtf"
#output file
outfile=${subdir}/5_annotations.gtf


#Step 5:
# sort the BED files by position before collapsing
sort -k1,1 -k2,2n $exons_unamb > $exons_sorted
sort -k1,1 -k2,2n $introns_unamb > $introns_sorted


# collapse each BED file
bedtools merge -s -c 4,6,7 -o distinct,distinct,distinct -i $exons_sorted > $exons_col
bedtools merge -s -c 4,6,7 -o distinct,distinct,distinct -i $introns_sorted > $introns_col


# filter out lines from > 1 gene + convert back to GTF file:
awk -F'\t' -v OFS='\t' '!($4 ~ /,/) {
          print $1, ".", "exon", $2 + 1, $3 , ".", $5, ".", "gene_id "$4
}' $exons_col > $exons_col_gtf

awk -F'\t' -v OFS='\t' '!($4 ~ /,/) {
          print $1, ".", "intron", $2 + 1, $3 , ".", $5, ".", "gene_id "$4
}' $introns_col > $introns_col_gtf


#merge into one GTF file
cat $exons_col_gtf $introns_col_gtf > $outfile


#count the lines to check the number of annotations in each of these files
line_count=$(wc -l < $exons_unamb)
echo "Number of lines in unambiguous exons file: $line_count"
line_count=$(wc -l < $exons_sorted)
echo "Number of lines in sorted unambiguous exons file: $line_count"
line_count=$(wc -l < $exons_col)
echo "Number of lines in collapsed unambiguous exons bed file: $line_count"
line_count=$(wc -l < $exons_col_gtf)
echo "Number of lines in collapsed unambiguous exons gtf file: $line_count"

line_count=$(wc -l < $introns_unamb)
echo "Number of lines in unambiguous introns file: $line_count"
line_count=$(wc -l < $introns_sorted)
echo "Number of lines in sorted unambiguous introns file: $line_count"
line_count=$(wc -l < $introns_col)
echo "Number of lines in collapsed unambiguous introns bed file: $line_count"
line_count=$(wc -l < $introns_col_gtf)
echo "Number of lines in collapsed unambiguous introns gtf file: $line_count"

line_count=$(wc -l < $outfile)
echo "Number of lines in combined annotations file: $line_count"

#remove intermediate files
rm $exons_sorted
rm $introns_sorted
rm $exons_col
rm $introns_col
rm $exons_col_gtf
rm $introns_col_gtf

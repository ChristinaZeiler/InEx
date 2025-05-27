#!/usr/bin/env bash

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
#input
annotations=${subdir}/5_annotations.gtf
#intermediate
ann_sort=${subdir}/6_sorted.annotations.gtf
#output
in_ex_len=${subdir}/6_intron_exon_length.csv


#Step 6: saving the total lengths of all exons/introns for each gene
#sort by geneID and then in positional order
sort -t $'\t' -k9 -k4n $annotations > $ann_sort


# determine intron and exon length
awk 'BEGIN {FS="\t"; OFS=","; gene_id = ""}
    { current_gene_id = $9
      #strip ‘geneID "’ and ‘"’ to keep just the ID itself 
      gsub(/^gene_id "/, "", current_gene_id);  
      gsub(/"$/, "", current_gene_id);          
      if (current_gene_id != gene_id) {
	# when transitioning to next gene, print the values
          if (gene_id != "") {
		print gene_id, in_length, ex_length 
          } else { # print headers in first row 
                print "gene_id","in_length","ex_length" 
          }
          # calculate length of the first annotation of a gene
          gene_id = current_gene_id
          in_length= 0
          ex_length= 0
          if ($3 == "intron") {
              in_length=$5 - $4 +1
          } else if ($3 == "exon") {
              ex_length=$5 - $4 +1
          }
      } else if ($3 == "intron") {
	# while staying within the same gene: add exon/intron length to previous values
          in_start=$4
          in_end=$5
          in_length=in_length + in_end - in_start + 1
      } else if ($3 == "exon") {
          ex_start=$4
          ex_end=$5
          ex_length=ex_length + ex_end - ex_start + 1
      }
   }
   END { # print last gene
      if (gene_id != "") {
          print gene_id, in_length, ex_length
      }
}' $ann_sort > $in_ex_len


gene_nr=$(awk -F'\t' '{ seen[$9]++ } END { print length(seen) }' $ann_sort)
echo "Number of genes in annotation file: $gene_nr"

line_count=$(wc -l < $in_ex_len)
echo "Number of lines in intron exon lengths file including header: $line_count" 


#removing intermediate files
rm $ann_sort

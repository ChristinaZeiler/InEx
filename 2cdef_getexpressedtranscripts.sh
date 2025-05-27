#!/usr/bin/env bash

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
all_exons=${subdir}/1_protein.coding.exons.gtf
all_exons_sorted=${subdir}/2c_exons.sorted.gtf
all_exons_count=${subdir}/2d_exons.count.csv
used_exons=${subdir}/2b_used.exons.gtf
used_exons_sorted=${subdir}/2c_used.exons.sorted.gtf
used_exons_count=${subdir}/2d_used.exons.count.csv
used_TVs=${subdir}/2e_used.TVs.txt
outfile=${subdir}/2f_exp.TVs.exons.gtf



#Step 2c: sorting both GTF files by transcript ID and chromosomal position
# protein coding exons file
awk -F'\t' 'BEGIN { OFS=FS }
	# adding a column with transcript ID
  { split($9, a, "[ ;]");
	#split column 9 by ; and extract transcript ID
    for (i = 1; i <= length(a); i++) {
    	if (a[i] == "transcript_id") {
          transcript_ID = a[i+1];
          break;
          }
    }
    print $0, transcript_ID
	#print original line plus transcript ID
  }' $all_exons | sort -t$'\t' -k10,10 -k4,4n > $all_exons_sorted

# used exons file
awk -F'\t' 'BEGIN { OFS=FS }
	# adding a column with transcript ID
  { split($9, a, "[ ;]");
	#split column 9 by ; and extract transcript ID
    for (i = 1; i <= length(a); i++) {
    	if (a[i] == "transcript_id") {
          transcript_ID = a[i+1];
          break;
          }
    }
    print $0, transcript_ID
	#print original line plus transcript ID
  }' $used_exons | sort -t$'\t' -k10,10 -k4,4n > $used_exons_sorted



#Step 2d: count exons per transcript ID and put output in CSV files
# for used exons
awk 'BEGIN {FS="\t"; OFS=","; transcript_ID = ""}
    { current_transcript_ID = $10
      if (current_transcript_ID != transcript_ID){
	# when encountering a new transcript ID
    	  if (transcript_ID != "") {
	  # and it’s not the first line, print the exon count for the previous transcript ID
          	print transcript_ID, exon_count
          } else { # if it is the first print a header
                print "transcript_ID", "exon_count"
          }
	  # after having printed the previous define this new transcript ID as the one to be counted and set the count to 1
          transcript_ID = current_transcript_ID
          exon_count= 1
      } else { # if it’s not a new ID: add 1 to the count
          exon_count++
      }
}' $used_exons_sorted > $used_exons_count
# same for all exons
awk 'BEGIN {FS="\t"; OFS=","; transcript_ID = ""}
    {current_transcript_ID = $10
     if (current_transcript_ID != transcript_ID){
    	if (transcript_ID != "") {
              print transcript_ID, exon_count
        } else {
              print "transcript_ID", "exon_count"
        }
        transcript_ID = current_transcript_ID
        exon_count= 1
     } else {
          exon_count++
     }
}' $all_exons_sorted > $all_exons_count


#Step 2e: create a list of fully expressed (used exons count = total exon count) transcripts
awk -F, '
	# saving exon counts for each transcript ID from first file 
	FNR==NR {exon[$1]=$2; next} 
	# if the count in second file is the same as in first file print transcript ID to text file
	FNR>1 {if (exon[$1]==$2) print $1}
' $all_exons_count $used_exons_count > $used_TVs


#Step 2f: create a GTF file with exon annotations of fully expessed transcripts
grep -Fwf $used_TVs $all_exons_sorted > $outfile


#remove intermediate files
rm $all_exons_sorted
rm $all_exons_count
rm $used_exons_sorted
rm $used_exons_count
rm $used_TVs

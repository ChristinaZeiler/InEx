#!/usr/bin/env bash

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
exons=${subdir}/2f_exp.TVs.exons.gtf
introns=${subdir}/3_exp.TVs.introns.gtf


awk 'BEGIN {FS="\t"; OFS="\t"}
    { current_transcript_ID = $10;
      if (current_transcript_ID != transcript_ID) {
          #when encountering a new TV, no intron will be saved (this is only the first exon) -> only save the end position of this exon + 1 as the start position of the next intron
          transcript_ID = current_transcript_ID; 
          prev_end = $5+1;
      } else {
          # if this is not a new TV and the position of this exon is further downstream than the previous one (which should be the case due to the sorting) -> print an entry for the intron defined as the sequence between the two exons
          if (prev_end && $4 > prev_end) {
              print $1, "calculated", "intron", prev_end, $4-1, $6, $7, $8, $9, transcript_ID
          }
       prev_end = $5+1;
    }
}' $exons > $introns

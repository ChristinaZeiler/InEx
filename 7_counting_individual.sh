#!/usr/bin/env bash

module load htseq

source config_bash.sh

#dir="<your directory>"

#input
genome=${dir}/genome/5_annotations.gtf
#BAMdir="<your BAM directory>" #path to your name-sorted BAM files
  #BAM files must be name-sorted!!
cd ${BAMdir}
#output
subdir=${dir}/counts
mkdir -p $subdir

#getting the BAM file name from command line argument position 1
bam="${BAMdir}/$1"

intron_tsv=${subdir}/7a_${bam//.bam/_intron.tsv}
exon_tsv=${subdir}/7b_${bam//.bam/_exon.tsv}
exon_strict_tsv=${subdir}/7c_${bam//.bam/_exon.strict.tsv}
# count fragments overlapping for each exon
htseq-count -f bam $bam \
      -t intron -i gene_id -m union --nonunique all --order=name -s reverse \
      ${genome} -c ${intron_tsv}
htseq-count -f bam ${bam} \
      -t exon -i gene_id -m union --nonunique all --order=name -s reverse \
      ${genome} -c ${exon_tsv}
htseq-count -f bam ${bam} \
      -t exon -i gene_id -m intersection-strict --nonunique all --order=name -s reverse \
      ${genome} -c ${exon_strict_tsv}


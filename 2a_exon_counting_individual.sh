#!/usr/bin/env bash

module load htseq

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
#input files
#BAMdir="<your BAM directory>" #directory with your NAME SORTED BAM files
#getting the BAM file name from command line argument position 1
bam="${BAMdir}/$1" 
genome=${subdir}/1_protein.coding.exons.gtf

#output file folder
countdir=${subdir}/2a_exoncounts
mkdir -p $countdir
out_tsv=${countdir}/2a_${bam//.bam/exoncounts.tsv}
out_csv=${countdir}/2a_${bam//.bam/.usedexons.csv}

# count fragments overlapping for each exon
htseq-count -f bam $bam \
    -t exon -i exon_id -m union --nonunique all \
    --order=name -s reverse \
    $genome \
    -c ${out_tsv}

# now get exon IDs with counts > 0
awk -F'\t' '$1 !~ /^__/ && $2 > 0 {
    print $1
}' ${out_tsv} > ${out_csv}


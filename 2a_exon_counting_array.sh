#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1G
#SBATCH --array=1-6
#SBATCH --job-name=htseq_exons
#SBATCH --output=htseq_exons_%a.out
#SBATCH --error=htseq_exons_%a.err
#SBATCH --time=00:30:00

module load htseq

source config_bash.sh

#dir="<your directory>"
subdir=${dir}/genome
#input
genome=${subdir}/1_protein.coding.exons.gtf
#BAMdir="<your BAM directory>" # directory containing your name sorted BAM files
  #BAM files must be name-sorted!!
cd ${BAMdir}
file=$(ls *.bam | sed -n ${SLURM_ARRAY_TASK_ID}p)

#output
countdir=${subdir}/2a_exoncounts
mkdir -p $countdir
out_tsv=${countdir}/2a_${file//.bam/.exoncounts.tsv}
out_csv=${out_tsv//.tsv/.usedexons.csv}

echo ${file}

#counting reads in exons, exon-exon junctions and exon-intron boundaries
htseq-count -f bam ${file} \
	-t exon -i exon_id -m union --nonunique all --order=name -s reverse \
	${genome} -c ${out_tsv}

# now get exon IDs with counts > 0
awk -F'\t' '$1 !~ /^__/ && $2 > 0 {
      print $1
}' ${out_tsv} > ${out_csv}



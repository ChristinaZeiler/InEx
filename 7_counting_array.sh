#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1G
#SBATCH --array=1-6
#SBATCH --job-name=htseq
#SBATCH --output=htseq_%a.out
#SBATCH --error=htseq_%a.err
#SBATCH --time=01:30:00

module load htseq

source config_bash.sh

#dir="<your directory>"

#input
genome=${dir}/genome/5_annotations.gtf
#BAMdir="<your BAM directory>"
  #BAM files must be name-sorted!!
cd ${BAMdir}
file=$(ls *.bam | sed -n ${SLURM_ARRAY_TASK_ID}p)

#output
subdir=${dir}/counts
mkdir -p $subdir
intron_tsv=${subdir}/7a_${file//.bam/_intron.tsv}
exon_tsv=${subdir}/7b_${file//.bam/_exon.tsv}
exon_strict_tsv=${subdir}/7c_${file//.bam/_exon.strict.tsv}

echo ${file}

#counting reads in introns and exon-intron boundaries
htseq-count -f bam ${file} \
	-t intron -i gene_id -m union --nonunique all --order=name -s reverse \
	${genome} -c ${intron_tsv}

htseq-count -f bam ${file} \
        -t exon -i gene_id -m union --nonunique all --order=name -s reverse \
        ${genome} -c ${exon_tsv}

htseq-count -f bam ${file} \
        -t exon -i gene_id -m intersection-strict --nonunique all --order=name -s reverse \
        ${genome} -c ${exon_strict_tsv}


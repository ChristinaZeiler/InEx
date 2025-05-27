#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --mem=2G
#SBATCH --array=1-6
#SBATCH --job-name=coverage_tracks
#SBATCH --output=coverage_tracks_%a.out
#SBATCH --error=coverage_tracks_%a.err
#SBATCH --time=04:00:00

module load samtools
module load deeptools

source config_bash.sh

#directory of name sorted BAM files
#BAMdir="<your BAM directory>"
#directory for position sorted BAM files
BAMdirpos=${BAMdir}"/pos"
#directory for coverage tracks
#dir="<your directory>"
subdir=${dir}/coverage_tracks

#make intermediate file directory
mkdir -p $BAMdirpos
#make output file directory
mkdir -p $subdir


#input files = name-sorted BAM files
#if position-sorted BAM files are already available exchange next line for cd $BAMdirpos
cd $BAMdir
file=$(ls *.bam | sed -n ${SLURM_ARRAY_TASK_ID}p)


echo ${file}

#comment these lines if position sorted BAM files are already available
samtools sort ${file} -o ${BAMdirpos}/${file}
samtools index ${BAMdirpos}/${file}


bamCoverage \
    --bam ${BAMdirpos}/${file} \
    --outFileName ${subdir}/${file//.bam/.fwd.bw} \
    --binSize 1 \
    --numberOfProcessors 16 \
    --filterRNAstrand forward \
    --normalizeUsing CPM

bamCoverage \
    --bam ${BAMdirpos}/${file} \
    --outFileName ${subdir}/${file//.bam/.rev.bw} \
    --binSize 1 \
    --numberOfProcessors 16 \
    --filterRNAstrand reverse \
    --normalizeUsing CPM

#optional: remove directory with intermediate files
rm -r $BAMdirpos

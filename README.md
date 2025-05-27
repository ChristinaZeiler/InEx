STAR Protocol InEx README

The repository contains two config files and BASH and R scripts for the entire protocol. Script names have a prefix corresponding to the numbered step, e.g. Script "1_filterproteincoding.sh" codes for the filtering performed in step 1 of the protocol. 0_covertracks.sh is a script that creates coverage tracks (mentioned in preparation, used for troubleshooting throughout the protocol). 

Similarly, output files contain a prefix corresponding to the step they were created in. This helps keep an overview of the order in which files are created and where files came from that are used in subsequent processing steps. 

We highly recommend running at least some of the bash scripts on a high performance cluster, submitting them as jobs to to a job scheduler. 
Specifically, 0_covertracks.sh, 2a_exon_counting_array.sh and 7_counting_array.sh require high computational resources. These scripts contain headers for submission to SLURM as array jobs (running the scripts for all samples in parallel) which drastically speeds up the analysis. Computational resources specified in the header greatly depend on sequencing depth, so make sure to adjust them accordingly. Also adjust the array number (currently 1-6) to your sample number. 
In case such resources are not available, we provide alternative scripts for steps 2a and 7 that run for individual files (2a_exon_counting_individual.sh and 7_counting_individual.sh). The user has to provide the filename (without directory path) as the first command line argument (see below). Calculations for 2a and 7 take ~ 0.5h and 1.5h to run per sample, respectively. 

Some scripts contain lines for removing intermediate files to save storage space (always at the end of the script). For troubleshooting, comment these lines to get the intermediate files. 

How to run this pipeline: 
1. create a directory where you want all your output from this analysis saved (scripts will create subdirectories automatically) 
2. specify the path to this directory in config_bash.sh and config_R.R (can also copy the directory in case R scripts are run locally, in that case specify that path in config_R.R) and the path to the directory of your name-sorted BAM files and to your input Ensembl genome GTF file in config_bash.sh  
3. run bash scripts
	sbatch 0_covertracks.sh

	bash 1_filterproteincoding.sh

	sbatch 2a_exon_counting_array.sh
	alternative:
	bash 2a_exon_counting_individual.sh BAMfilename.bam 

	bash 2b_getusedexons.sh

	bash 2cdef_getexpressedtranscripts.sh

	bash 3_getintrons.sh

	bash 4_removeambiguous.sh

	bash 5_collapse.sh

	bash 6_intronexonlength.sh

	sbatch 7_counting_array.sh
	alternative:
	bash 7_counting_individual.sh BAMfilename.bam 

4. run R scripts: Scripts contain commented lines that help with troubleshooting & checking correctness of calculations (highly recommended). 

	Option1: open scripts in R Studio and run individual parts 
	make sure working directory is the directory of the scripts prior to running each script, otherwise config_R.R cannot be sourced

	Option2: running the R scripts in Linux
	Rscript 8-11_normalization_and_filtering.R
	Rscript 12-15_enrichment_analysis.R
	Rscript 16-17_InEx.R


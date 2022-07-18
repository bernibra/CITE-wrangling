#!/bin/bash

#SBATCH --chdir=/work/PRTNR/CHUV/DIR/rgottar1/citeseq/CITE-wrangling/
#SBATCH --account rgottar1_citeseq
#SBATCH --time 00-12:00:00
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 1
#SBATCH --mem 10G
#SBATCH -o /scratch/bbramonm/output_%j.txt
#SBATCH -e /scratch/bbramonm/errors_%j.txt

module load singularity

export SINGULARITY_BINDPATH="/users,/scratch,/work"

singularity run ~/CITE-wrangling/R-4.2.1-cite.sif Rscript ~/CITE-wrangling/main.R


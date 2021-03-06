#!/bin/bash -l
#PBS -N 01-fastqc
#PBS -r n
#PBS -m abe
#PBS -M pcrisp@umn.edu

######################
set -xeuo pipefail

echo working dir is $PWD

#cd into work dir
echo changing to PBS_O_WORKDIR
cd "$PBS_O_WORKDIR"
echo working dir is now $PWD

mkdir -p logs

######################

# Quality control on raw reads was performed with FASTQC v.0.11.5 (Andrews 2014)
# fastqc from RNAseq pipeline
# default is running 12 cores

module load parallel
module load fastqc

bash ~/gitrepos/NGS-pipelines/RNAseqPipe3/01-runner.sh $threads $reads_dir

# to run
# qsub ~/gitrepos/NGS-pipelines/RNAseqPipe3/01-runner_qsub.sh

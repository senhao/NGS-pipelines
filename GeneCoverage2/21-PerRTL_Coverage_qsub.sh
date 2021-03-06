#!/bin/bash
#set -xe
set -xeuo pipefail

usage="USAGE:
bash PerGeneCoverage_qsub.sh <sample_list.txt> <library_layout> <beds_folder>"

#define stepo in the pipeline - should be the same name as the script
step=21-PerRTL_Coverage

######### Setup ################
sample_list=$1
library_layout=$2
beds_folder=$3
if [ "$#" -lt "3" ]
then
echo $usage
exit -1
else
echo "Submitting samples listed in '$sample_list' for coverage analysis"
cat $sample_list
fi

#number of samples
number_of_samples=`wc -l $sample_list | awk '{print $1}'`
if [[ "$number_of_samples" -eq 1 ]]
then
qsub_t=1
else
qsub_t="1-${number_of_samples}"
fi
echo "argument to be passed to qsub -t is '$qsub_t'"

#find script to run, makes it file system agnostic
if
[[ $OSTYPE == darwin* ]]
then
readlink=$(which greadlink)
scriptdir="$(dirname $($readlink -f $0))"
else
scriptdir="$(dirname $(readlink -f $0))"
fi

########## Run #################

#make log and analysis folders
#make logs folder if it doesnt exist yet
mkdir -p logs

timestamp=$(date +%Y%m%d-%H%M%S)

#make logs folder, timestamped
log_folder=logs/${timestamp}_${step}
mkdir $log_folder

#script path and cat a record of what was run
script_to_qsub=${scriptdir}/${step}.sh
cat $script_to_qsub > ${log_folder}/script.log
cat $0 > ${log_folder}/qsub_runner.log

#submit qsub and pass args
#-o and -e pass the file locations for std out/error
#-v additional variables to pass to the qsub script including the PBS_array list and the dir structures
qsub -t $qsub_t \
-o ${log_folder}/${step}_o \
-e ${log_folder}/${step}_e \
-v LIST=${sample_list},library_layout=$library_layout,beds_folder=$beds_folder \
$script_to_qsub

# to run
# bash /home/springer/pcrisp/gitrepos/ngs-pipelines/GeneCoverage2/PerGeneCoverage_qsub.sh <sample_list.txt> <library_layout> <beds_folder>
# eg
# bash /home/springer/pcrisp/gitrepos/ngs-pipelines/GeneCoverage2/PerGeneCoverage_qsub.sh samples.txt stranded tdf_for_igv_coverage_beds_full

###
#code to make it work on osx and linux
if
[[ $OSTYPE == darwin* ]]
then
readlink=$(which greadlink)
scriptdir="$(dirname $($readlink -f $0))"
else
scriptdir="$(dirname $(readlink -f $0))"
fi
###

usage="USAGE:
04-runner.sh <number of threads>"

######### Setup ################
threads=$1
# kefile format: (tab seperated)
#Ordinal Sample <factor1_name> [<factor2_name>]
if [ "$#" -lt "1" ]
then
echo $usage
exit -1
else
echo "initiating $1 parallel fastQC jobs on no-adapter-quality-trimmed reads"
fi
########## Run #################
#user defined variables that could be changed:
workingdir=./
script=$scriptdir/04-fastqc.sh
outdir=reads_noadapt_trimmed_fastqc
###

function findSamples () {
find reads_noadapt_trimmed/ -mindepth 1 -maxdepth 1 -type d  -exec basename {} \;| tr ' ' '\n'
}

mkdir ${outdir}
timestamp=$(date +%Y%m%d-%H%M%S)

logdir="./logs/${outdir}.${timestamp}"
mkdir $logdir

cat $script > "$logdir/script.log"
cat $0 > "$logdir/runner.log"
cat $script

findSamples | parallel -j $threads bash $script {} \>logs/${outdir}.${timestamp}/{}.log 2\>\&1

#To run:
#bash ~/path_to/01-runner.sh

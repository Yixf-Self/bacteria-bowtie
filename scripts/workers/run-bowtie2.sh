#!/usr/bin/env bash

#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l select=1:ncpus=12:mem=25gb
#PBS -l walltime=3:00:00
#PBS -l cput=36:00:00
#PBS -M scottdaniel@email.arizona.edu
#PBS -m bea

cd $PBS_O_WORKDIR

set -u

echo "Started at $(date) on host $(hostname)"

COMMON="$WORKER_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

bowtie2 -p 12 \
    --very-sensitive-local \
    --no-unal \
    -k 1 \
    -x $BT2 \
    -1 $(cat $LEFT_FASTQ) \
    -2 $(cat $RIGHT_FASTQ) \
    -U $(cat $UNPAIRED) \
    -S $OUT/$SAMPLE.sam

echo "Done at $(date)"


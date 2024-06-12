#!/bin/bash

merged_filfile=`ls -tr merged*.fil | tail -1`
if [[ -n "$1" && "$1" != "-" ]]; then
   merged_filfile="$1"
fi

merged_candfile=${merged_filfile%%fil}cand

echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 4096 -d 16384 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile} -A 5 -P 5 -O 50 > fredda_totalpower_4sec.out 2>&1"
/usr/local/bin//cudafdmt ${merged_filfile} -t 4096 -d 16384 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile} -A 5 -P 5 -O 50 > fredda_totalpower_4sec.out 2>&1


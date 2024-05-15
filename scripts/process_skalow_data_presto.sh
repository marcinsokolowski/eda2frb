#!/bin/bash

template="ch???_16ch/dynspec_avg7_i.fil"
if [[ -n "$1" && "$1" != "-" ]]; then
   template="$1"
fi

object=J0835-4510
if [[ -n "$2" && "$2" != "-" ]]; then
   object="$2"
fi

n_coarse_channels=1000000
if [[ -n "$3" && "$3" != "-" ]]; then
   n_coarse_channels=$3
fi

merged_filfile="merged_all_channels_oversampled.fil"
if [[ $n_coarse_channels -lt 1000000 ]]; then
   merged_filfile="merged_${n_coarse_channels}_channels_oversampled.fil"
fi
if [[ -n "$4" && "$4" != "-" ]]; then
   merged_filfile="$4"
fi

presto_subbands=16
if [[ -n "$5" && "$5" != "-" ]]; then
   presto_subbands=$5
fi

run_fredda=0
if [[ -n "$6" && "$6" != "-" ]]; then
   run_fredda=$6
fi

echo "#####################################"
echo "PARAMETERS:"
echo "#####################################"
echo "run_fredda = $run_fredda"
echo "merged_filfile = $merged_filfile"
echo "#####################################"


ls $template > fil_list_all
fil_merge_list=`cat fil_list_all | head --lines=${n_coarse_channels} | awk '{printf("%s,",$1);}'`

# WARNING : for fredda it may required -s -1 !!!
echo "merge_coarse_channels ${fil_merge_list} ${merged_filfile} -o"
merge_coarse_channels ${fil_merge_list} ${merged_filfile} -o 

echo "presto_fold.sh ${merged_filfile} ${object} - - ${presto_subbands}"
presto_fold.sh ${merged_filfile} ${object} - - ${presto_subbands}

if [[ $run_fredda -gt 0 ]]; then
   # compilation:
   # LAPTOP : ~/github/fredda/branches/main/fredda/src/cudafdmt
   # aavs2-server : /home/msok/install/fredda/src/
   merged_candfile=${merged_filfile%%fil}cand
   
   echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}"
   /usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}

   subdir=${merged_filfile%%.fil}
   echo "For viewing FREDDA FRB candidates use:"
   echo "showcand_merged.sh $merged_filfile 10"
   echo "or"
   echo "showcand_all.sh $subdir 10"
   echo "or"
   echo "cd $subdir"
   echo "showcand.sh FIL_FILE 10" 
else
   echo "WARNING : running fredda is not required"
fi

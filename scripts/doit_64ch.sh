#!/bin/bash

object=J0835-4510
if [[ -n "$1" && "$1" != "-" ]]; then
   object="$1"
fi

start_ux=-1
if [[ -n "$2" && "$2" != "-" ]]; then
   start_ux=$2
fi

total_power_threshold=5
if [[ -n "$3" && "$3" != "-" ]]; then
   total_power_threshold=$3
fi

start_channel=256
if [[ -n "$4" && "$4" != "-" ]]; then
   start_channel=$4
fi

gpu=0
if [[ -n "$5" && "$5" != "-" ]]; then
   gpu=$5
fi

gpu_blocks=14
if [[ -n "$6" && "$6" != "-" ]]; then
   gpu_blocks=$6
fi


export PATH=/home/msok/github/eda2frb/scripts/:/home/msok/github/mwafrb/scripts/:/home/msok/github/mwafrb/src/:$PATH

echo "----------------------------------------------"
echo "PARAMETERS:"
echo "----------------------------------------------"
echo "gpu = $gpu ( options : -x $gpu_blocks )"
echo "gpu_blocks = $gpu_blocks"
echo "----------------------------------------------"

path=`pwd`

# if [[ $gpu -gt 0 ]]; then
#   echo "INFO : using experimemntal GPU version"
#   echo "/home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch_TEST.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} >  msok_ch64.out 2>&1"
#   /home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch_TEST.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} >  msok_ch64.out 2>&1   
#else
echo "INFO : using standard CPU version"
echo "/home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} - ${gpu} ${gpu_blocks} >  msok_ch64.out 2>&1"
/home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} - ${gpu} ${gpu_blocks} >  msok_ch64.out 2>&1
# fi   

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


export PATH=/home/msok/github/eda2frb/scripts/:/home/msok/github/mwafrb/scripts/:/home/msok/github/mwafrb/src/:$PATH

path=`pwd`
echo "/home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} >  msok_ch64.out 2>&1"
/home/msok/github/eda2frb/scripts/process_skalow_data_frbsearch.sh $path 14 - 1 filterbank_msok_64ch 1 ${object} 0 ${start_channel} ${start_ux} ${total_power_threshold} >  msok_ch64.out 2>&1

#!/bin/bash

dataset=$1
type=`echo $dataset | cut -b 12-14`

echo "INFO : $dataset / $type"

export PATH=~/github/eda2frb/scripts/:~/github/mwafrb/scripts/:/opt/pi/ext/src/root/build_new/bin/:$PATH 

# ssh aavs2 "ls -d /data/${dataset}/${type}*/256/filterbank_msok_64ch/"
subdir=`ssh aavs2 "cd /data/${dataset}/;ls -d ${type}*/256/filterbank_msok_64ch/" | tail -1`

echo "/home/msok/github/eda2frb/scripts/auto_copy_frb_data.sh ${dataset} ${subdir} `pwd` 0 2"
/home/msok/github/eda2frb/scripts/auto_copy_frb_data.sh ${dataset} ${subdir} `pwd` 0 2 

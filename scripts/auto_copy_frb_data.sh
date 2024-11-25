#!/bin/bash

dateset=2024_11_23_FRB2024114A
if [[ -n "$1" && "$1" != "-" ]]; then
   dataset="$1"
fi

remote_subdirs=FRB20240114_flagants_ch40_ch256/256/filterbank_msok_64ch/
remote_dir=/data/${dataset}/${remote_subdirs}/
if [[ -n "$2" && "$2" != "-" ]]; then
   remote_dir="$2"
fi

local_dir=/data/sdhav2/FRB20240114
if [[ -n "$3" && "$3" != "-" ]]; then
   local_dir="$3"
fi

echo "########################################"
echo "PARAMETERS:"
echo "########################################"
echo "dataset = $dataset"
echo "remote_dir = $remote_dir"
echo "local_dir = $local_dir"
echo "########################################"

if [[ -d ${local_dir} ]]; then
   cd ${local_dir}
   mkdir -p ${dateset}/${remote_subdirs}
   cd ${dateset}/${remote_subdirs}
   echo "/home/msok/github/eda2frb/scripts/scp.sh ${remote_dir}" > scp!
   chmod +x scp!
   
   date
   
   echo "./scp!"
   ./scp!
   
else
   echo "ERROR : local directory does not exist"
fi

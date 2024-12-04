#!/bin/bash

remote_server=aavs2
remote_drive="/data/"

# dataset=2024_11_23_FRB2024114A
# dataset_fullpath=`ssh ${remote_server} "ls -d /data/202?_??_??_FRB* | tail -1"`
# echo "DEBUG : the latest FRB observation on ${remote_server} is ${dataset_fullpath}"
# dataset=`basename $dataset_fullpath`
# if [[ -n "$1" && "$1" != "-" ]]; then
#   dataset="$1"
# fi

template="202[4,5,6,7,8,9]_??_??_FRB*"
if [[ -n "$1" && "$1" != "-" ]]; then
   template="$1"
fi

remote_subdirs=FRB20240114_flagants_ch40_ch256/256/filterbank_msok_64ch/
# remote_dir=/data/${dataset}/${remote_subdirs}/
if [[ -n "$2" && "$2" != "-" ]]; then
   remote_subdirs="$2"
fi

local_dir=/data/sdhav2/FRB20240114
if [[ -n "$3" && "$3" != "-" ]]; then
   local_dir="$3"
fi

show_ds9=1
if [[ -n "$4" && "$4" != "-" ]]; then
   show_ds9=$4
fi

last_n_datasets=10
if [[ -n "$5" && "$5" != "-" ]]; then
   last_n_datasets=$5
fi


echo "########################################"
echo "PARAMETERS:"
echo "########################################"
# echo "dataset = $dataset"
echo "template = $template"
echo "remote_dir = $remote_dir"
echo "local_dir = $local_dir"
echo "show_ds9  = $show_ds9"
echo "last_n_datasets = $last_n_datasets"
echo "########################################"

if [[ -d ${local_dir} ]]; then
   cd ${local_dir}
   
   for remote_path in `ssh ${remote_server} "ls -ad ${remote_drive}/${template} | tail --lines=${last_n_datasets}"`
   do   
      # remote_dir=/data/${dataset}/${remote_subdirs}/
      dataset=`basename $remote_path`
      remote_dir=${remote_path}/${remote_subdirs}/
      echo "DEBUG : dataset = $dataset , remote_dir = $remote_dir"
      sleep 2
      
      if [[ -d ${dataset}/${remote_subdirs} ]]; then
         echo "WARNING : directory already copied earlier -> some things may get overwritten"
      fi
   
      mkdir -p ${dataset}/${remote_subdirs}
      cd ${dataset}/${remote_subdirs}
      pwd
      echo "/home/msok/github/eda2frb/scripts/scp.sh ${remote_dir} - - \"-l -b -q\" - $show_ds9 " > scp!
      chmod +x scp!

      echo "cat scp!"
      cat scp!
   
      date
   
      echo "./scp!"
      ./scp!
      
      cd -
      pwd
   done   
else
   echo "ERROR : local directory does not exist"
fi

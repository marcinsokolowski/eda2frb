#!/bin/bash

# export MWA_FRB=/home/msok/github/mwafrb/ 
# export PATH=/home/msok/github/eda2frb/scripts:$MWA_FRB/scripts:$MWA_FRB/src/:$PATH
source /home/msok/github/eda2frb/scripts/env_aavs2_server

#
#                                                  WARNING - order of paramters below is not-in-order on purpose !!!
# 
# templates="FRB*/??? S1832-0911*/???"
frb_templates="FRB*"
if [[ -n "$2" && "$2" != "-" ]]; then
   frb_templates="$2"
fi

datadir="/data/"
if [[ -n "$3" && "$3" != "-" ]]; then
   datadir="$3"
fi

# dir_template="2024_11_??_FRB*"
last_frb_path=`ls -d ${datadir}/202?_*FRB* | tail -1`
dir_template=`basename $last_frb_path`
if [[ -n "$1" && "$1" != "-" ]]; then
   dir_template="$1"
fi

auto_remove=0
if [[ -n "$4" && "$4" != "-" ]]; then
   auto_remove=$4
fi

last_n_datasets=10
if [[ -n "$5" && "$5" != "-" ]]; then
   last_n_datasets=$5
fi



echo "#######################################"
echo "PARAMETERS:"
echo "#######################################"
echo "dir_template = $dir_template (from last_frb_path = $last_frb_path )"
echo "frb_templates = $frb_templates"
echo "datadir       = $datadir"
echo "auto_remove   = $auto_remove"
echo "last_n_datasets = $last_n_datasets"
echo "#######################################"

cd $datadir
pwd
for dir in `ls -d ${dir_template} | tail --lines=${last_n_datasets}`
do
   if [[ ! -s ${dir}/frb_processing.done ]]; then
      cd $dir
      echo "nohup auto_process_frb_data.sh - \"${frb_templates}\" $auto_remove > auto_process_frb_data.log 2>&1 &"
      nohup auto_process_frb_data.sh - "${frb_templates}" $auto_remove > auto_process_frb_data.log 2>&1 &
      cd ..
   else
      echo "Directory $dir already processed -> skipped"
   fi
done



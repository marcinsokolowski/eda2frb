#!/bin/bash

export MWA_FRB=/home/msok/github/mwafrb/ 
export PATH=/home/msok/github/eda2frb/scripts:$MWA_FRB/scripts:$MWA_FRB/src/:$PATH


dir_template="2024_11_??_FRB*"
if [[ -n "$1" && "$1" != "-" ]]; then
   dir_template="$1"
fi

# templates="FRB*/??? S1832-0911*/???"
frb_templates="FRB*"
if [[ -n "$2" && "$2" != "-" ]]; then
   frb_templates="$2"
fi

datadir="/data/"
if [[ -n "$3" && "$3" != "-" ]]; then
   datadir="$3"
fi

auto_remove=0
if [[ -n "$4" && "$4" != "-" ]]; then
   auto_remove=$4
fi


echo "#######################################"
echo "PARAMETERS:"
echo "#######################################"
echo "dir_template = $dir_template"
echo "frb_templates = $frb_templates"
echo "datadir       = $datadir"
echo "auto_remove   = $auto_remove"
echo "#######################################"

cd $datadir
pwd
for dir in `ls -d ${dir_template}`
do
   if [[ ! -s ${dir}/frb_processing.done ]]; then
      cd $dir
      echo "auto_process_frb_data.sh - \"${frb_templates}\" $auto_remove"
      auto_process_frb_data.sh - "${frb_templates}" $auto_remove
      cd ..
   else
      echo "Directory $dir already processed -> skipped"
   fi
done



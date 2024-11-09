#!/bin/bash

dt=`date +%Y_%m_%d_pulsars`
# local_data_dir="/data/${dt}/"
local_data_dir=`pwd`
if [[ -n "$1" && "$1" != "-" ]]; then
   local_data_dir="$1"
fi

# templates="FRB*/??? S1832-0911*/???"
templates="FRB*"
if [[ -n "$2" && "$2" != "-" ]]; then
   templates="$2"
fi


echo "-------------------------------- auto-processing FRB data --------------------------------"
date
count_local=`ls -ald ${local_data_dir}/${templates} 2>&1 |  grep -v "ls: cannot access" | wc -l `

if [[ $count_local -gt 0 ]]; then
   cd ${local_data_dir}
   if [[ -s copied.txt ]]; then
      for frb_dir in `ls -d ${templates}/???`
      do
         if [[ -d $frb_dir ]]; then
            echo "DEBUG : Starting processing data in $frb_dir"
            cd $frb_dir
            ux_start=`date +%s`
            date
            
            if [[ ! -s frb_processing.done ]]; then
               pwd
               echo "/home/msok/github/eda2frb/scripts/doit_64ch.sh"
               /home/msok/github/eda2frb/scripts/doit_64ch.sh
            else
               echo "INFO : processing already done in this directory:"
               pwd
               echo "completed at:"
               cat frb_processing.done
            fi
            date > frb_processing.done
            
            ux_end=`date +%s`
            diff=$(($ux_end-$ux_start))
            echo "DEBUG : finished processing data (took $diff seconds) in $frb_dir at :"
            date
            cd -
         else
            echo "DEBUG : non-directory $frb_dir skipped"
         fi
      done           
   else
      echo "WARNING : data copying not finished yet (file copied.txt not found) -> $frb_dir skipped"
   fi
else
   echo "DEBUG : no new data found in ${local_data_dir}/"
fi


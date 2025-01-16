#!/bin/bash

wait_for_file () {
  file=$1
  if [[ -n "$1" && "$1" != "-" ]]; then
     file="$1"
  fi

   ux=`date +%s`
   while [[ ! -s ${file} ]];
   do
      ux=`date +%s`
      echo "Waiting 10 seconds for file $file to be created (ux = $ux) ..."
      sleep 10
   done   
}


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

auto_remove=0
if [[ -n "$3" && "$3" != "-" ]]; then
   auto_remove=$3
fi

gpu=0
if [[ -n "$4" && "$4" != "-" ]]; then
   gpu=$4
fi

gpu_blocks=14
if [[ -n "$5" && "$5" != "-" ]]; then
   gpu_blocks=$5
fi



echo "############################################"
echo "PARAMETERS:"
echo "############################################"
echo "local_data_dir = $local_data_dir"
echo "templates      = $templates"
echo "auto_remove    = $auto_remove"
echo "gpu            = $gpu (-x $gpu_blocks)"
echo "gpu_blocks     = $gpu_blocks"
echo "############################################"


if [[ -s frb_processing.done ]]; then
   pwd
   echo "Data in this directory already processed -> exiting"
   exit;
fi

echo "-------------------------------- auto-processing FRB data --------------------------------"
date
count_local=`ls -ald ${local_data_dir}/${templates} 2>&1 |  grep -v "ls: cannot access" | wc -l `
echo "ls -ald ${local_data_dir}/${templates} | wc -l"
echo "DEBUG : count_local = $count_local"

if [[ $count_local -gt 0 ]]; then
   cd ${local_data_dir}
   wait_for_file copied.txt
   
   if [[ -s copied.txt ]]; then
      for frb_dir in `ls -d ${templates}/???`
      do
         if [[ -d $frb_dir ]]; then
            object_name=`echo ${frb_dir} | awk '{i=index($1,"_");print substr($1,1,i-1);;}'`
            echo "DEBUG : Starting processing data in $frb_dir -> object_name = $object_name"
            cd $frb_dir
            ux_start=`date +%s`
            date
            
            if [[ ! -s frb_processing.done ]]; then
               pwd
               echo "/home/msok/github/eda2frb/scripts/doit_64ch.sh $object_name - - - $gpu $gpu_blocks"
               /home/msok/github/eda2frb/scripts/doit_64ch.sh $object_name - - - $gpu $gpu_blocks
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
            if [[ $auto_remove -gt 0 ]]; then
                echo "WARNING : removing .dada files, you have 10 seconds to change your mind ..."
                pwd
                sleep 10
                echo "rm -f *.dada"
                rm -f *.dada
            else
            	echo "WARNING : auto-remove is disabled this may result in accumulation of large amount of data."
            fi
            
            cd -
            
            date > frb_processing.done                        
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


#!/bin/bash

template="2024_12_??_*"
if [[ -n "$1" && "$1" != "-" ]]; then
   template="$1"
fi

objects="FRB* J* B*"
if [[ -n "$2" && "$2" != "-" ]]; then
   objects="$2"
fi


for dir in `ls -d ${template}`
do
   cd $dir
   for object in `ls -d ${objects}`   
   do
      path=`pwd`
      if [[ -d ${object}/256/filterbank_msok_64ch ]]; then
         cd ${object}/256/filterbank_msok_64ch
         
         merged_dir=`ls -d merged_channels_?????????? | tail -1 2>/dev/null `
         if [[ -d ${merged_dir} ]]; then
            cd ${merged_dir}
            
            date
            echo "Starting processing in:"
            pwd

            echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 350 1 > sps_10sigma.out 2>&1"
            ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 350 1 > sps_10sigma.out 2>&1

            echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1"            
            ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1

            echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - 350 1 > sps_5sigma.out 2>&1"
            ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - 350 1 > sps_5sigma.out 2>&1
            
            echo "Finished processing at:"
            date

            cd ..
         else
            echo "WARNING : directory merged_channels_?????????? does not exist"
         fi
         
         cd ../../../
      else
         echo "INFO : ${object}/256/filterbank_msok_64ch - no such directory in $path -> skipped"
      fi      
   done
   cd ..
   
   echo "sleep 10"
   sleep 10

done

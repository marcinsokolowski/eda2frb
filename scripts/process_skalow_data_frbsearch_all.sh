#!/bin/bash

# find . -name "*.dada" -exec dirname {} \; | sort -u

template="J* B*"
if [[ -n "$1" && "$1" != "-" ]]; then
   template="$1"
fi

# 1000 -> 1.08us -> ~1080.us ~ 1ms 
scrunch_factor=1000
if [[ -n "$2" && "$2" != "-" ]]; then
   scrunch_factor=$2
fi

filterbank_dir=filterbank_scrunch${scrunch_factor}
if [[ $scrunch_factor -le 1 ]]; then
   filterbank_dir=filterbank
fi

digifil_options=""
if [[ -n "$3" && "$3" != "-" ]]; then
   digifil_options=$3
fi


echo "#############################################"
echo "PARAMETERS:"
echo "template        = $template"
echo "scrunch_factor  = $scrunch_factor"
echo "filterbank_dir  = $filterbank_dir"
echo "digifil_options = $digifil_options"
echo "#############################################"

for subdir in `ls -d ${template}*`
do
   cd ${subdir}
   for ch in `ls -d ??? ??`
   do
      cd ${ch}
      current_path=`pwd`

      echo "process_skalow_data_frbsearch.sh $current_path $scrunch_factor \"${digifil_options}\""
      process_skalow_data_frbsearch.sh $current_path $scrunch_factor "${digifil_options}"
      cd ../
   done
   cd ../
done

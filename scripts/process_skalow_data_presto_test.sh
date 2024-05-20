#!/bin/bash

n_chan=16
if [[ -n "$1" && "$1" != "-" ]]; then
   n_chan=$1
fi

object="B0950+08"
if [[ -n "$2" && "$2" != "-" ]]; then
   object="$2"
fi

ch=1
while [[ $ch -le $n_chan ]];
do
   echo "~/github/eda2frb/scripts/process_skalow_data_presto.sh "ch???/dynspec_avg7_i.fil" $object $ch > nchan${ch}.out 2>&1"
   ~/github/eda2frb/scripts/process_skalow_data_presto.sh "ch???/dynspec_avg7_i.fil" $object $ch > nchan${ch}.out 2>&1
   
   ch=$(($ch+1))
done
   
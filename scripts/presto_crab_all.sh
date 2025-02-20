#!/bin/bash

export PATH=~/github/eda2frb/scripts:$PATh

for dataset in `cat crab_list.txt`
do
   dir=`ls ${dataset}/J0534+2200_flagants_ch40_ch256/256/filterbank_msok_64ch/merged_channels_??????????/ | tail -1`
   cd ${dir}
   echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2_CRAB.sh > presto_single_pulse_aavs2_CRAB.out 2>&1"
   ~/github/eda2frb/scripts/presto_single_pulse_aavs2_CRAB.sh > presto_single_pulse_aavs2_CRAB.out 2>&1
   cd -
done

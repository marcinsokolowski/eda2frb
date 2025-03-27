#!/bin/bash

export PATH=~/github/eda2frb/scripts:$PATH

template="20??_??_??_pulsars_msok/J0534+2200_flagants_ch40_ch256/256/filterbank_msok_64ch/merged_channels_??????????/"

for dir in `ls -d ${template}`
do
   echo 
   echo "dir = $dir"
   date
   cd ${dir}
   
#   if [[ -d presto_sps_thresh5_numdms100_dmstep0.01 ]]; then
#      echo "mv presto_sps_thresh5_numdms100_dmstep0.01 presto_sps_thresh5_numdms100_dmstep0.01_OLD"
#      mv presto_sps_thresh5_numdms100_dmstep0.01 presto_sps_thresh5_numdms100_dmstep0.01_OLD
#   fi
   
   echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2_CRAB.sh > presto_single_pulse_aavs2_CRAB.out 2>&1"
   ~/github/eda2frb/scripts/presto_single_pulse_aavs2_CRAB.sh > presto_single_pulse_aavs2_CRAB.out 2>&1
   cd -
done

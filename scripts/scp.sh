#!/bin/bash

path=/data/2024_06_10_pulsars/FRB20240114_flagants_ch40_ch256/256/filterbank_msok_64ch/
if [[ -n "$1" && "$1" != "-" ]]; then
   path="$1"
fi

do_copy=1
if [[ -n "$2" && "$2" != "-" ]]; then
   do_copy=$2
fi

do_plots=1
if [[ -n "$3" && "$3" != "-" ]]; then
   do_plots=$3
fi

root_options="-l"
if [[ -n "$4" && "$4" != "-" ]]; then
   root_options="$4"
fi

local_dir=`pwd`
pwd
if [[ -n "$5" && "$5" != "-" ]]; then
   local_dir=$5
   mkdir -p ${local_dir}
   cd ${local_dir}
   pwd
fi
pwd

show_ds9=1
if [[ -n "$6" && "$6" != "-" ]]; then
   show_ds9=$6
fi

host=aavs2
if [[ -n "$7" && "$7" != "-" ]]; then
   host="$7"
fi

run_crab_analysis=`echo $path | awk '{print index($0,"J0534+2200");}'`
if [[ -n "$8" && "$8" != "-" ]]; then
   run_crab_analysis=$8
fi


echo "#########################################"
echo "PARAMETERS:"
echo "#########################################"
echo "path = $path"
echo "do_copy  = $do_copy"
echo "do_plots = $do_plots"
echo "root_options = $root_options"
echo "local_dir = ${local_dir}"
echo "show_ds9 = $show_ds9"
echo "host = $host"
echo "run_crab_analysis = $run_crab_analysis"
echo "#########################################"


if [[ $do_copy -gt 0 ]]; then
   echo "rsync -avP ${host}:${path}/*.png ."
   rsync -avP ${host}:${path}/*.png .
   
   echo "rsync -avP ${host}:${path}/*.cand* ."
   rsync -avP ${host}:${path}/*.cand* .
else
   echo "WARNING : copying results is disabled (2nd parameter <=0 )"    
fi   

echo
echo "------------------------------------------------------------------------------"
echo "STATISTICS:"
wc *.cand*

echo
echo "MAX SNR:"
awk '{if($3>35){print $0;}}' merged_channels_??????????.cand_merged
echo "------------------------------------------------------------------------------"
echo
sleep 10

if [[ $show_ds9 -gt 0 ]]; then
   # Show png-s from FREDDA:
   gthumb -n *png &
fi

if [[ $do_copy -gt 0 ]]; then   
   # start with PRESTO to have stuff to inspect !!!
   echo "rsync --exclude '*.fil' --exclude '*.dat' --exclude '*.inf' -avPL ${host}:${path}/merged_channels_?????????? ."
   rsync --exclude '*.fil' --exclude '*.dat' --exclude '*.inf' -avPL ${host}:${path}/merged_channels_?????????? .

   echo "rsync -avP ${host}:${path}/total_power.txt ."
   rsync -avP ${host}:${path}/total_power.txt .
 
# 2024-12-24 - not really used/inspected  , needed for plotting total power !!!
   echo "rsync -avP ${host}:${path}/fredda_totalpower_4sec.out ."
   rsync -avP ${host}:${path}/fredda_totalpower_4sec.out .
   
   echo "rsync -avP ${host}:${path}/candidates_fits ."
   rsync -avP ${host}:${path}/candidates_fits .

else
   echo "WARNING : copying results is disabled (2nd parameter <=0 )"   
fi   

if [[ $do_plots -gt 0 ]]; then
   mkdir -p images/

   echo "~/github/mwafrb/scripts/plot_median_of_median_check.sh fredda_totalpower_4sec.out \"${root_options}\""
   ~/github/mwafrb/scripts/plot_median_of_median_check.sh fredda_totalpower_4sec.out "${root_options}"

   candmerged_file=`ls *.cand_merged | tail -1`
   echo "/home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${candmerged_file} - - \"${root_options}\""
   /home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${candmerged_file} - - "${root_options}"

# 2024-12-24 : only overplot merged candidates - takes a lot of time already 
#   cand_file=`ls *.cand | tail -1`
#   echo "/home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${cand_file} - - \"${root_options}\""
#   /home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${cand_file} - - "${root_options}"

   if [[ $show_ds9 -gt 0 ]]; then
      pwd
      for merged_dir in `ls -d merged_channels_??????????`
      do
         cd $merged_dir
         echo "acroread prest*/*.pdf &"
         acroread prest*/*.pdf &
         cd ..
      done      
   fi
   
   pwd
   date
   
   # plot total power around merged candidates:
   echo "~/github/mwafrb/scripts/plot_total_power_for_merged.sh - - \"${root_options}\" ${show_ds9}"
   ~/github/mwafrb/scripts/plot_total_power_for_merged.sh - - "${root_options}" ${show_ds9}
   
   echo "THE END"
else
   echo "WARNING : ploting is disabled (3rd parameter <= 0)"
fi

# assuming we are in directory : 2025_02_20_pulsars_msok/J0534+2200_flagants_ch40_ch256/256/filterbank_msok_64ch
# need to go down to 2025_02_20_pulsars_msok/
if [[ $run_crab_analysis -gt 0 ]]; then
   pwd
   cd ../../../
   pwd
   export PATH=~/github/crab_frb_paper/scripts/calib/:$PATH
   echo "~/github/crab_frb_paper/scripts/calib/process_dataset.sh > analysis_final.out 2>&1"
   ~/github/crab_frb_paper/scripts/calib/process_dataset.sh > analysis_final.out 2>&1

   echo "All processing done at :"
   date
else
   echo "WARNING : running Crab GPs analysis is not requested, to do so execute :"
   echo "export PATH=~/github/crab_frb_paper/scripts/calib/:$PATH"
   echo "~/github/crab_frb_paper/scripts/calib/process_dataset.sh > analysis_final.out 2>&1"
   
fi   


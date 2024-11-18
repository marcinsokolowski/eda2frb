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

echo "#########################################"
echo "PARAMETERS:"
echo "#########################################"
echo "path = $path"
echo "do_copy  = $do_copy"
echo "do_plots = $do_plots"
echo "#########################################"


if [[ $do_copy -gt 0 ]]; then
   rsync -avP aavs2:${path}/*.cand* .
   rsync -avP aavs2:${path}/total_power.txt .
   rsync -avP aavs2:${path}/fredda_totalpower_4sec.out .
   rsync -avP aavs2:${path}/*.png .
   rsync -avP aavs2:${path}/candidates_fits .
else
   echo "WARNING : copying results is disabled (2nd parameter <=0 )"   
fi   

# Show png-s from FREDDA:
gthumb -n *png &

echo "STATISTICS:"
wc *.cand*
sleep 10

if [[ $do_plots -gt 0 ]]; then
   ~/github/mwafrb/scripts/plot_median_of_median_check.sh fredda_totalpower_4sec.out

   candmerged_file=`ls *.cand_merged | tail -1`
   /home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${candmerged_file}

   cand_file=`ls *.cand | tail -1`
   /home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${cand_file}

   # plot total power around merged candidates:
   ~/github/mwafrb/scripts/plot_total_power_for_merged.sh
else
   echo "WARNING : ploting is disabled (3rd parameter <= 0)"
fi

   

#!/bin/bash

path=/data/2024_06_10_pulsars/FRB20240114_flagants_ch40_ch256/256/filterbank_msok_64ch/
if [[ -n "$1" && "$1" != "-" ]]; then
   path="$1"
fi

rsync -avP aavs2:${path}/*.cand* .
rsync -avP aavs2:${path}/total_power.txt .
rsync -avP aavs2:${path}/fredda_totalpower_4sec.out .

echo "STATISTICS:"
wc *.cand*
sleep 10

~/github/mwafrb/scripts/plot_median_of_median_check.sh fredda_totalpower_4sec.out

candmerged_file=`ls *.cand_merged | tail -1`
/home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${candmerged_file}

cand_file=`ls *.cand | tail -1`
/home/msok/github/mwafrb/scripts/overplot_candidates_and_totalpower.sh ${cand_file}

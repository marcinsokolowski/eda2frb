#!/bin/bash

# find . -name "*.dada" -exec dirname {} \; | sort -u

export PATH=~/github/eda2frb/scripts/:$MWA_FRB/scripts/:/usr/local/bin/:$PATH

dada_files_path=`pwd`
if [[ -n "$1" && "$1" != "-" ]]; then
   dada_files_path="$1"
fi

# 1000 -> 1.08us -> ~1080.us ~ 1ms 
scrunch_factor=14 
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

merge_candidates=1
if [[ -n "$4" && "$4" != "-" ]]; then
   merge_candidates=$4
fi

filterbank_dir=filterbank_msok_64ch
if [[ -n "$5" && "$5" != "-" ]]; then
   filterbank_dir=$5
fi

run_presto=1
if [[ -n "$6" && "$6" != "-" ]]; then
   run_presto=$6
fi

observed_object="J0835-4510"
if [[ -n "$7" && "$7" != "-" ]]; then
   observed_object="$7"
fi

use_digifil=0
if [[ -n "$8" && "$8" != "-" ]]; then
   use_digifil=$8
fi

pwd_path=`pwd`
start_channel=`basename $pwd_path`
if [[ -n "$9" && "$9" != "-" ]]; then
   start_channel=$9
fi

start_ux=-1
if [[ -n "${10}" && "${10}" != "-" ]]; then
   start_ux=${10}
fi

total_power_threshold=5
if [[ -n "${11}" && "${11}" != "-" ]]; then
   total_power_threshold=${11}
fi

max_presto_dm=350
if [[ $observed_object == "FRB20180301" ]]; then
   echo "OBSERVED OBJECT = FRB20180301 -> setting max_presto_dm = 600"
   max_presto_dm=600
fi
if [[ -n "${12}" && "${12}" != "-" ]]; then
   max_presto_dm=${12}
fi


exclude_daytime=0

# use 64 fine channels as the current merge is optimised and hardcoded for this number. Could also be any multiplicity of 64 -> k*64, but 64 is computationally the cheapest option
n_fine_ch=64
#if [[ -n "${10}" && "${10}" != "-" ]]; then
#   n_fine_ch=${10}
#fi

if [[ -s daq.out ]]; then
   err_count=`grep "Ring buffer occupancy" daq.out  |wc -l`
   if [[ $err_count -gt 0 ]]; then
      echo "WARNING : data acquisition was not keeping up and there are $err_count Ring buffer occupancy errors detected -> existing post processig now"
      grep "Ring buffer occupancy" daq.out 
#      exit 
   fi
fi


echo "#############################################"
echo "PARAMETERS:"
echo "dada_files_path = $dada_files_path"
echo "scrunch_factor  = $scrunch_factor"
echo "filterbank_dir  = $filterbank_dir"
echo "digifil_options = $digifil_options"
echo "run_presto      = $run_presto"
echo "observed_object = $observed_object"
echo "use_digifil     = $use_digifil"
echo "start_channel   = $start_channel"
echo "n_fine_ch       = $n_fine_ch"
echo "exclude_daytime = $exclude_daytime"
echo "start_ux        = $start_ux"
echo "total_power_threshold = $total_power_threshold"
echo "max_presto_dm   = $max_presto_dm"
echo "#############################################"


# check all requirements and dependencies:
if [[ ! -d ${dada_files_path} ]]; then
   echo "ERROR : path $dada_files_path does not exist"
   exit
fi

skalow_spectrometer_path=`which skalow_spectrometer`
if [[ $use_digifil -le 0 ]]; then
   if [[ -n $skalow_spectrometer_path ]]; then
      echo "OK : program skalow_spectrometer found at $skalow_spectrometer_path -> OK"
   else
      echo "ERROR : program skalow_spectrometer not found on path, install as described at https://github.com/marcinsokolowski/skalow_station_data"
      exit -1
   fi
fi   

cd ${dada_files_path}
if [[ -s frb_processing.done ]]; then
   echo "WARNING : the processing was already performed and finished at:"
   cat frb_processing.done
   echo "WARNING : exiting the script now"
   exit;
fi

# check time of acquisition:
dada_count=`ls channel_0_*.dada 2>/dev/null | wc -l`
if [[ $dada_count -gt 0 ]]; then
   start_ux=`ls channel_0_*.dada | cut -b 13-22`
   echo "DEBUG : start_ux = $start_ux (from .dada files)"
else 
   echo "DEBUG : start_ux = $start_ux (from parameters)"
fi   
hour_local=`date -d "1970-01-01 UTC $start_ux seconds" +%H`

if [[ $exclude_daytime -gt 0 && $hour_local -ge 6 && $hour_local -le 17 ]]; then
   echo "WARNING : daytime observation started at:"
   date -d "1970-01-01 UTC $start_ux seconds" +"%Y-%m-%d %T"
   
   echo "WARNING : too much RFI -> FRB processing skipped"
   exit;
fi

# PULSAR:
psrcat_path=`which psrcat`
if [[ -n $psrcat_path ]]; then
   echo "psrcat -e ${observed_object} > ${observed_object}.eph_full"
   psrcat -e2 ${observed_object} > ${observed_object}.eph_full
   p0=`cat ${observed_object}.eph_full | grep P0 | awk '{if($1=="P0"){print $2;}}'`
   echo "DEBUG : p0 = $p0, taken from ${observed_object}.eph_full :"
   cat ${observed_object}.eph_full
else
   echo "ERROR : psrcat not installed -> cannot continue"
   exit;
fi   

mkdir -p ${filterbank_dir}
# digifil -t 1000 -o filterbank_1ms/channel_57_1_1713782313.693404.fil channel_57_1_1713782313.693404.dada -b 8
# start_ux=-1
fil_count=0
for dada_file in `ls channel*.dada`
do
   fil_file=${dada_file%%dada}fil
   base_name=${dada_file%%.dada}
   start_ux_set=`echo $start_ux | awk '{if($1>0){print 1;}else{print 0;}}'`
   ch=`echo $dada_file | awk -F '_' '{ch=$2;ux=substr($4,1,17);print ch;}'`
   channel_total=`echo "$ch $start_channel" | awk '{printf("%d\n",($1+$2));}'`
   freq_mhz=`echo "$ch $start_channel" | awk '{printf("%.6f\n",($1+$2)*(400.00/512.00));}'`
   echo "INFO : processing dada_file = $dada_file -> ch=$ch, start_channel=$start_channel -> freq = $freq_mhz [MHz]"
   
   if [[ $start_ux_set -le 0 ]]; then
      start_ux=`echo ${base_name} | awk '{print substr($1,length($1)-16);}'`
      echo "INFO : start_ux = $start_ux"
   fi
   
   if [[ -s ${filterbank_dir}/${fil_file} ]]; then
      echo "INFO : filterbank file ${filterbank_dir}/${fil_file} - already exists -> skipped"
   else
      if [[ $use_digifil -gt 0 ]]; then
         if [[ $scrunch_factor -gt 1 ]]; then
            echo "digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}"
            digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}
         else
            echo "digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}"
            digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}
         fi
      else
         # use MSOK's conversion software: https://github.com/marcinsokolowski/skalow_station_data
         # skalow_station_fold.sh /data/ 2024_05_01_pulsars 230 J0835-4510_flagants_70ch_ch230  1 1 - 16 0.089328385024 - - "-a 7 -b 1" - - - _16ch
         cd ${filterbank_dir}/
         pwd
         echo "ln -sf ../${dada_file}"
         ln -sf ../${dada_file}
         date
         echo "time skalow_spectrometer ${dada_file} -f test -p 0 -C 1 -c 0 -s 4096 -Z  -m -1 -F ${channel_total} -N $n_fine_ch -O dynspec -a ${scrunch_factor} -P ${p0} -D 2 -A ch${channel_total} -b 1"
         time skalow_spectrometer ${dada_file} -f test -p 0 -C 1 -c 0 -s 4096 -Z  -m -1 -F ${channel_total} -N $n_fine_ch -O dynspec -a ${scrunch_factor} -P ${p0} -D 2 -A ch${channel_total} -b 1
         date
                  
         echo "ln -s ch${channel_total}/dynspec_avg${scrunch_factor}_i.fil ${fil_file}"
         ln -s ch${channel_total}/dynspec_avg${scrunch_factor}_i.fil ${fil_file}
         
         cd ../
      fi
  fi
  
  fil_count=$(($fil_count+1))
done

cd ${filterbank_dir}
# merging filterbank files from different coase frequency channels into one BIG file :
# fil_merge_list=`ls *.fil | head --lines=${fil_to_process} | awk '{printf("%s,",$1);}'`
ls channel_?_?_*.fil > fil_list_all_tmp
ls channel_??_?_*.fil >> fil_list_all_tmp
ls channel_???_?_*.fil >> fil_list_all_tmp
all_count=`cat fil_list_all_tmp | wc -l`
# ignore last 6 files:
if [[ $all_count -gt 64 ]]; then
   echo "INFO : there are $all_count filterbank files -> ignoring last 6 of them"
   all_count_minus4=$(($all_count-6))
else
   echo "INFO : there are $all_count filterbank files -> can use all of them"
   all_count_minus4=$all_count
fi   
head --lines=${all_count_minus4} fil_list_all_tmp | head --lines=57 > fil_list_all # only 57 coarse channels 57*54 = 3078 fine channels -> only remove 6 fine channels to make it divide by 128 as required by FREDDA

# div4=`echo ${fil_count} | awk '{print int($1/4);}'`
# div4=`echo ${all_count_minus4} | awk '{print int($1/4);}'`
# fil_to_process=$(($div4*4))
# echo "Total $fil_count filterbank files - FREDDA required divsion by 4 -> processing $fil_to_process files"

# fil_merge_list=`cat fil_list_all | head --lines=${fil_to_process} | awk '{printf("%s,",$1);}'`
# max 59 coarse channels to end up with 768 fine channels (divides by 128)
fil_merge_list=`cat fil_list_all | head --lines=59 | awk '{printf("%s,",$1);}'`

merged_filfile=merged_${fil_to_process}channels_${start_ux}.fil
merged_fitsfile=merged_${fil_to_process}channels_${start_ux}.fits
merged_candfile=merged_${fil_to_process}channels_${start_ux}.cand
merged_candidates=merged_${fil_to_process}channels_${start_ux}.cand_merged

# WARNING : for fredda it may required -s -1 !!!
if [[ -s ${merged_filfile} ]]; then
   echo "INFO : merged file ${merged_filfile} already exists -> no need to run merge_coarse_channels"
else
   echo "INFO : merged file ${merged_filfile} does not exist -> running merge_coarse_channels now"
   echo "merge_coarse_channels ${fil_merge_list} ${merged_filfile} -o -F -S -C ${start_channel}"
   merge_coarse_channels ${fil_merge_list} ${merged_filfile} -o -F -S -C ${start_channel}
fi   

# conversion of merged FIL to FITS file:
echo "dumpfilfile_float ${merged_filfile} ${merged_fitsfile}"
dumpfilfile_float ${merged_filfile} ${merged_fitsfile}

# compilation:
# LAPTOP : ~/github/fredda/branches/main/fredda/src/cudafdmt
# aavs2-server : /home/msok/install/fredda/src/
# echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}"
# /usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}
echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 4096 -d 16384 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile} -A ${total_power_threshold} -P 5 -O 50 > fredda_totalpower_4sec.out 2>&1"
/usr/local/bin//cudafdmt ${merged_filfile} -t 4096 -d 16384 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile} -A ${total_power_threshold} -P 5 -O 50 > fredda_totalpower_4sec.out 2>&1

path=`which my_friends_of_friends.py`
# merge candidates 
if [[ $merge_candidates -gt 0 ]]; then
   echo "python $path ${merged_candfile} --outfile=${merged_candidates}"
   python $path ${merged_candfile} --outfile=${merged_candidates}
else
   echo "WARNING : merging of candidates is not required. If needed execute command:"
   echo "python $path ${merged_candfile} --outfile=${merged_candidates}"
fi   

if [[ $run_presto -gt 0 ]]; then   
   # PRESTO folding :
   echo "presto_fold.sh ${merged_filfile} ${observed_object} - - 16 0.00 \"-noxwin\""
   presto_fold.sh ${merged_filfile} ${observed_object} - - 16 0.00 "-noxwin"

   # PRESTO single pulse searches :   
   b=${merged_filfile%%.fil}
   cd ${b}
   echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - $max_presto_dm 1 > sps_10sigma.out 2>&1"
   ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - $max_presto_dm 1 > sps_10sigma.out 2>&1
   size=`ls -ltr presto_sps_thresh10_numdms${max_presto_dm}*/singlepulse_thresh10.pdf | tail -1 | awk '{print $5}'`
   if [[ $size -lt 5000 ]]; then
      echo "ERROR in PRESTO processing -> trying to repeat"
      
      mkdir -p OLD
      echo "mv presto_sps_thresh10_numdms${max_presto_dm}*/ OLD/"
      mv presto_sps_thresh10_numdms${max_presto_dm}*/ OLD/
      
      echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - $max_presto_dm 1 > sps_10sigma.out 2>&1"
      ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - $max_presto_dm 1 > sps_10sigma.out 2>&1 # doubled to try to fix the usual crash 
   fi

   echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1"
   ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1
   
   size=`ls -ltr presto_sps_thresh10_numdms250_*/singlepulse_thresh10.pdf | tail -1 | awk '{print $5}'`
   if [[ $size -lt 5000 ]]; then
      echo "ERROR in PRESTO processing -> trying to repeat"
      
      mkdir -p OLD
      echo "mv presto_sps_thresh10_numdms250_*/ OLD/"
      mv presto_sps_thresh10_numdms250_*/ OLD/

      echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1"
      ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 10 - 250 0.1 > sps_10sigma_maxdm25.out 2>&1 # doubled to try to fix the usual crash
   fi

   echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - $max_presto_dm 1 > sps_5sigma.out 2>&1"
   ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - $max_presto_dm 1 > sps_5sigma.out 2>&1
   
   size=`ls -ltr presto_sps_thresh5_numdms${max_presto_dm}_*/singlepulse_thresh5.pdf | tail -1 | awk '{print $5}'`
   if [[ $size -lt 5000 ]]; then
      echo "ERROR in PRESTO processing -> trying to repeat"
      
      mkdir -p OLD
      echo "mv presto_sps_thresh5_numdms${max_presto_dm}_*/ OLD/"
      mv presto_sps_thresh5_numdms${max_presto_dm}_*/ OLD/
      
      echo "~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - $max_presto_dm 1 > sps_5sigma.out 2>&1"
      ~/github/eda2frb/scripts/presto_single_pulse_aavs2.sh 5 - $max_presto_dm 1 > sps_5sigma.out 2>&1 # doubled to try to fix the usual crash
   fi
   cd ..
else
   echo "WARNING : running PRESTO is not required"
fi

# TODO:
# visualisation of candidates etc 
# use ~/github/mwafrb/scripts/showcand_merged.sh 
#                             create_cutouts_fits.sh

# create png files from FREDDA/Keith's python script:
echo "Generating png for maximum 1000 candidates (execute the line below with 1000 -> DIFFERENT NUMBER if more is needed)"
echo "$MWA_FRB/scripts/showcand_merged.sh $merged_filfile 10 - 1000"
$MWA_FRB/scripts/showcand_merged.sh $merged_filfile 10 - 1000

# Create Cutouts :
transposed_fits=`ls *out_t.fits | tail -1`
echo "$MWA_FRB/scripts/create_cutouts_fits.sh $transposed_fits ${merged_candfile} - - MIN_DM"
$MWA_FRB/scripts/create_cutouts_fits.sh ${transposed_fits}

subdir=${merged_filfile%%.fil}
echo "For viewing FREDDA FRB candidates use:"
echo "$MWA_FRB/scripts/showcand_merged.sh $merged_filfile 10"
echo "or"
echo "$MWA_FRB/scripts/showcand_all.sh $subdir 10"
echo "or"
echo "cd $subdir"
echo "$MWA_FRB/scripts/showcand.sh FIL_FILE 10" 
echo "or to create cutouts of fits files execute:"

# end of processing 
cd ${dada_files_path}
date > frb_processing.done

date

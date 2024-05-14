#!/bin/bash

# find . -name "*.dada" -exec dirname {} \; | sort -u

export PATH=$MWA_FRB/scripts/:$PATH

dada_files_path=/data/2024_04_22_pulsars/J0835-4510_flagants_90ch_ch230/230
if [[ -n "$1" && "$1" != "-" ]]; then
   dada_files_path="$1"
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

merge_candidates=0
if [[ -n "$4" && "$4" != "-" ]]; then
   merge_candidates=$4
fi

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


echo "#############################################"
echo "PARAMETERS:"
echo "dada_files_path = $dada_files_path"
echo "scrunch_factor  = $scrunch_factor"
echo "filterbank_dir  = $filterbank_dir"
echo "digifil_options = $digifil_options"
echo "run_presto      = $run_presto"
echo "observed_object = $observed_object"
echo "#############################################"



if [[ ! -d ${dada_files_path} ]]; then
   echo "ERROR : path $dada_files_path does not exist"
   exit
fi

cd ${dada_files_path}
if [[ -s done.txt ]]; then
   echo "WARNING : the processing was already performed and finished at:"
   cat done.txt
   echo "WARNING : exiting the script now"
   exit;
fi

# check time of acquisition:
start_ux=`ls channel_0_*.dada | cut -b 13-22`
hour_local=`date -d "1970-01-01 UTC $start_ux seconds" +%H`

if [[ $hour_local -ge 6 && $hour_local -le 17 ]]; then
   echo "WARNING : daytime observation started at:"
   date -d "1970-01-01 UTC $start_ux seconds" +"%Y-%m-%d %T"
   
   echo "WARNING : too much RFI -> FRB processing skipped"
   exit;
fi

mkdir -p ${filterbank_dir}
# digifil -t 1000 -o filterbank_1ms/channel_57_1_1713782313.693404.fil channel_57_1_1713782313.693404.dada -b 8
start_ux=-1
fil_count=0
for dada_file in `ls channel*.dada`
do
   fil_file=${dada_file%%dada}fil
   base_name=${dada_file%%.dada}
   start_ux_set=`echo $start_ux | awk '{if($1>0){print 1;}else{print 0;}}'`
   
   if [[ $start_ux_set -le 0 ]]; then
      start_ux=`echo ${base_name} | awk '{print substr($1,length($1)-16);}'`
      echo "INFO : start_ux = $start_ux"
   fi
   
   if [[ -s ${filterbank_dir}/${fil_file} ]]; then
      echo "INFO : filterbank file ${filterbank_dir}/${fil_file} - already exists -> skipped"
   else
      if [[ $scrunch_factor -gt 1 ]]; then
         echo "digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}"
         digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}
      else
         echo "digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}"
         digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8 -d 1 ${digifil_options}
      fi
  fi
  
  fil_count=$(($fil_count+1))
done

div4=`echo ${fil_count} | awk '{print int($1/4);}'`
fil_to_process=$(($div4*4))
echo "Total $fil_count filterbank files - FREDDA required divsion by 4 -> processing $fil_to_process files"

cd ${filterbank_dir}

# merging filterbank files from different coase frequency channels into one BIG file :
# fil_merge_list=`ls *.fil | head --lines=${fil_to_process} | awk '{printf("%s,",$1);}'`
ls channel_?_*.fil > fil_list_all
ls channel_??_*.fil >> fil_list_all
ls channel_???_*.fil >> fil_list_all
fil_merge_list=`cat fil_list_all | head --lines=${fil_to_process} | awk '{printf("%s,",$1);}'`

merged_filfile=merged_${fil_to_process}channels_${start_ux}.fil
merged_fitsfile=merged_${fil_to_process}channels_${start_ux}.fits
merged_candfile=merged_${fil_to_process}channels_${start_ux}.cand
merged_candidates=merged_${fil_to_process}channels_${start_ux}.cand_merged

echo "merge_coarse_channels ${fil_merge_list} ${merged_filfile} -s -1"
merge_coarse_channels ${fil_merge_list} ${merged_filfile} -s -1 

# conversion of merged FIL to FITS file:
echo "dumpfilfile_float ${merged_filfile} ${merged_fitsfile}"
dumpfilfile_float ${merged_filfile} ${merged_fitsfile}

# compilation:
# LAPTOP : ~/github/fredda/branches/main/fredda/src/cudafdmt
# aavs2-server : /home/msok/install/fredda/src/
echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}"
/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}

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
   echo "presto_fold.sh ${merged_filfile} ${observed_object} - - 16 0.00 \"-noxwin\""
   presto_fold.sh ${merged_filfile} ${observed_object} - - 16 0.00 "-noxwin"
else
   echo "WARNING : running PRESTO is not required"
fi

# TODO:
# visualisation of candidates etc 
# use ~/github/mwafrb/scripts/showcand_merged.sh 
#                             create_cutouts_fits.sh

# end of processing 
cd ${dada_files_path}
date > done.txt

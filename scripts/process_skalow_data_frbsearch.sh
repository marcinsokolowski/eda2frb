#!/bin/bash

# find . -name "*.dada" -exec dirname {} \; | sort -u

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

echo "#############################################"
echo "PARAMETERS:"
echo "dada_files_path = $dada_files_path"
echo "scrunch_factor  = $scrunch_factor"
echo "filterbank_dir  = $filterbank_dir"
echo "#############################################"



if [[ ! -d ${dada_files_path} ]]; then
   echo "ERROR : path $dada_files_path does not exist"
   exit
fi

cd ${dada_files_path}
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
         echo "digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8"
         digifil -t ${scrunch_factor} -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8
      else
         echo "digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8"
         digifil -o ${filterbank_dir}/${fil_file} ${dada_file} -b 8
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

echo "merge_coarse_channels ${fil_merge_list} ${merged_filfile}"
merge_coarse_channels ${fil_merge_list} ${merged_filfile}

# conversion to FITS file:
echo "dumpfilfile ${merged_filfile} ${merged_fitsfile}"
dumpfilfile ${merged_filfile} ${merged_fitsfile}

# compilation:
# LAPTOP : ~/github/fredda/branches/main/fredda/src/cudafdmt
# aavs2-server : /home/msok/install/fredda/src/
echo "/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}"
/usr/local/bin//cudafdmt ${merged_filfile} -t 512 -d 2048 -S 0 -r 1 -s 1 -m 100 -x 10 -o ${merged_candfile}


# TODO:
# visualisation of candidates etc 

#!/bin/bash

# WARNING : forth parameter goes first to be used as default :
remote_server="msok@eda2-server"
if [[ -n "$4" && "$4" != "-" ]]; then
   remote_server="$4"
fi

remote_data_drive="/data2/"
if [[ -n "$2" && "$2" != "-" ]]; then
   remote_data_drive="$2"  
fi

# WARNING 1st parameter goes last 
# dt=`date +%Y_%m_%d_pulsars_msok`
last_frb_path=`ssh ${remote_server} "ls -d ${remote_data_drive}/202?_*FRB*" | tail -1`
dt=`basename ${last_frb_path}`
if [[ -n "$1" && "$1" != "-" ]]; then
  dt="$1"
fi

local_data_drive="/data/"
if [[ -n "$3" && "$3" != "-" ]]; then
   local_data_drive="$3"
fi

last_n_datasets=10
if [[ -n "$4" && "$4" != "-" ]]; then
   last_n_datasets=$4
fi

echo "#############################################"
echo "PARAMETERS:"
echo "#############################################"
echo "dt = $dt"
echo "local_data_drive  = $local_data_drive"
echo "remote_server     = $remote_server"
echo "last_n_datasets   = $last_n_datasets"
echo "#############################################"


echo "-------------------------------- copy_data_root.sh --------------------------------"

date

for remote_data_dir in `ssh ${remote_server} "ls -d ${remote_data_drive}/${dt} | tail --lines=${last_n_datasets}"`
do
   echo "-------------------------------------------------------------------------------------------------------"
   echo "CHECKING : $remote_data_dir"
   
   b=`basename $remote_data_dir`
   local_data_dir="${local_data_drive}/${b}/"
   # count_remote=`ssh ${remote_server} "ls -ald ${remote_data_dir}/FRB* | wc -l"`
   # count_local=`ls -ald ${local_data_dir}/FRB* 2>&1 |  grep -v "ls: cannot access" | wc -l `
   # echo "DEBUG : count_remote = $count_remote, count_local = $count_local"
   # if [[ $count_remote -gt 0 && $count_local -le 0 ]]; then
   
   if [[ -s ${local_data_dir}/copied.txt ]]; then
      echo "DEBUG : data from ${remote_server}:${remote_data_dir}/FRB* already copied"
   else 
      echo "Starting copying data at:"
      date
      mkdir -p ${local_data_dir}/
      echo "rsync -avP ${remote_server}:${remote_data_dir}/* ${local_data_dir}/ > ${local_data_dir}/scp.out 2>&1"
      rsync -avP ${remote_server}:${remote_data_dir}/* ${local_data_dir}/ > ${local_data_dir}/scp.out 2>&1
   
      cd ${local_data_dir}/
      date > copied.txt
      chown aavs .
      chgrp aavs .
      chown aavs * -R
      chgrp aavs * -R 
      echo "DEBUG : owner and group changed to aavs user:"
      ls -al 
   
      echo "Finished copying at:"
      date
      cd -
   fi
done

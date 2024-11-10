#!/bin/bash

dt=`date +%Y_%m_%d_pulsars`
if [[ -n "$1" && "$1" != "-" ]]; then
  dt="$1"
fi

remote_data_drive="/data2/"
if [[ -n "$2" && "$2" != "-" ]]; then
   remote_data_drive="$2"  
fi
remote_data_dir=${remote_data_drive}/${dt}/

local_data_dir="/data/${dt}/"
if [[ -n "$3" && "$3" != "-" ]]; then
   local_data_dir="$3"
fi

remote_server="msok@eda2-server"
if [[ -n "$4" && "$4" != "-" ]]; then
   remote_server="$4"
fi

echo "#############################################"
echo "PARAMETERS:"
echo "#############################################"
echo "dt = $dt"
echo "remote_data_drive = $remote_data_drive"
echo "remote_data_dir   = $remote_data_dir"
echo "local_data_dir    = $local_data_dir"
echo "remote_server     = $remote_server"
echo "#############################################"


echo "-------------------------------- copy_data_root.sh --------------------------------"

date

count_remote=`ssh ${remote_server} "ls -ald ${remote_data_dir}/FRB* | wc -l"`
count_local=`ls -ald ${local_data_dir}/FRB* 2>&1 |  grep -v "ls: cannot access" | wc -l `
echo "DEBUG : count_remote = $count_remote, count_local = $count_local"
if [[ $count_remote -gt 0 && $count_local -le 0 ]]; then
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
else
   echo "DEBUG : data from ${remote_server}:${remote_data_dir}/FRB* already copied"
fi


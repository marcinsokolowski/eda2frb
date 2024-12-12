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
object_types="FRB RRAT PSR"
if [[ -n "$1" && "$1" != "-" ]]; then
  object_types="$1"
fi

remote_data_dir=${remote_data_drive}/${dt}/

local_data_dir="/data/"
if [[ -n "$3" && "$3" != "-" ]]; then
   local_data_dir="$3"
fi


echo "#############################################"
echo "PARAMETERS:"
echo "#############################################"
echo "object_types      = $object_types"
echo "remote_data_drive = $remote_data_drive"
echo "remote_data_dir   = $remote_data_dir"
echo "local_data_dir    = $local_data_dir"
echo "remote_server     = $remote_server"
echo "#############################################"


echo "-------------------------------- copy_data_root.sh --------------------------------"

date

if [[ ! -d ${local_data_dir} ]]; then
   echo "ERROR : local directory $local_data_dir does not exist"
   exit
fi

for type in `echo $object_types`
do
   for remote_path in `ssh ${remote_server} "ls -ad ${remote_drive}/202[4,5,6]_??_??_${type}* | tail --lines=${last_n_datasets}"`
   do   
      bdir=`basename ${remote_path}`
      mkdir -p ${local_data_dir}/${bdir}
     
      echo "rsync -avP ${remote_server}:${remote_path} ${local_data_dir}/ > ${local_data_dir}/${bdir}/scp.out 2>&1"
      rsync -avP ${remote_server}:${remote_path} ${local_data_dir}/ > ${local_data_dir}/${bdir}/scp.out 2>&1
      
      cd ${local_data_dir}/${bdir}/
      pwd
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
   done
done   



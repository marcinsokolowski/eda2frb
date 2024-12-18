#!/bin/bash

n_last=10
if [[ -n "$1" && "$1" != "-" ]]; then
   n_last=$1
fi

cd /data/sdhav2/

/home/msok/bin/lsobs.sh | tail --lines=${n_last} > latestobs.txt

for dir in `cat latestobs.txt`
do
   dataset=`basename $dir`
   
   echo "/home/msok/bin/copyobs.sh $dataset"
   /home/msok/bin/copyobs.sh $dataset

   echo "sleep 2"   
   sleep 2
done

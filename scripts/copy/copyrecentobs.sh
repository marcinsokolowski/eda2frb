#!/bin/bash

cd /data/sdhav2/

/home/msok/bin/lsobs.sh | tail -10 > latestobs.txt

for dir in `cat latestobs.txt`
do
   dataset=`basename $dir`
   
   echo "/home/msok/bin/copyobs.sh $dataset"
   /home/msok/bin/copyobs.sh $dataset

   echo "sleep 2"   
   sleep 2
done

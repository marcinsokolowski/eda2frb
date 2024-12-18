#!/bin/bash

n_last=10
if [[ -n "$1" && "$1" != "-" ]]; then
   n_last=$1
fi

cd /data/sdhav2/

/home/msok/bin/lsobs.sh | tail --lines=${n_last} > latestobs.txt

pwd
for dir in `cat latestobs.txt`
do
   dataset=`basename $dir`
   type=`echo $dataset | cut -b 12-14`
   
   ok=1
   if [[ $type == "FRB" ]]; then
      cd FRBs      
   else 
      if [[ $type == "PSR" ]]; then
         cd PSRs
      else
         if [[ $type == "RRA" ]]; then
            cd $RRATs
         else
            ok=0
         fi
      fi
   fi
   
   if [[ $ok -gt 0 ]]; then
      pwd
      echo "/home/msok/bin/copyobs.sh $dataset \"J*\""
      /home/msok/bin/copyobs.sh $dataset "J*"
   
      cd ..
   else
      echo "ERROR : object type |$type| is not known -> skipped"      
   fi
   pwd

   echo "sleep 2"   
   sleep 2
done

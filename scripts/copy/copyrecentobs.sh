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
   
   ok=0
   pwd
   echo "DEBUG : ok???"
   if [[ $type == "FRB" ]]; then
      cd FRBs      
      ok=1
   else 
      if [[ $type == "PSR" || $type == "pul" ]]; then
         cd PSRs
         type="J*"
         ok=1
      else
         if [[ $type == "RRA" ]]; then
            cd RRATs
            type="J*"
            ok=1
         fi
      fi
   fi
   
   if [[ $ok -gt 0 ]]; then
      pwd
      echo "/home/msok/bin/copyobs.sh $dataset \"${type}\""
      /home/msok/bin/copyobs.sh $dataset "${type}"
   
      cd ..
   else
      echo "ERROR : object type |$type| is not known -> skipped"      
   fi
   
   pwd
   echo "sleep 2"   
   sleep 2
done

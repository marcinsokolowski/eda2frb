#!/bin/bash

trigger_list=list

for candname in `cat list`
do
   if [[ -d ${candname} ]]; then
      echo "INFO : directory ${candname}/256/filterbank_msok_64ch already exists -> skipped"
   else
      mkdir -p ${candname}/256/filterbank_msok_64ch
      cd ${candname}/256/filterbank_msok_64ch
      echo "~/github/eda2frb/scripts/scp.sh /data/triggering/${candname}/256/filterbank_msok_64ch" > scp!
      chmod +x scp!
      pwd
      echo "./scp!"
      ./scp!
      cd -
   fi
done

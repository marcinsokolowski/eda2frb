#!/bin/bash

object=J0534+2200

mkdir single_pulse_archives/
cd single_pulse_archives/
psrcat -e ${object} > ${object}.eph


for dada_file in `ls ../*.dada`
do
   echo "ln -s $dada_file"
   ln -s $dada_file
done

for dada_file in `ls *.dada`  
do
   outfile=${dada_file%%dada}_single_pulse.ar 

   # use -cuda 0 when there is GPU     
   echo "dspsr -F1024:D -b1024 -E ${object}.eph -turns 1 -a PSRFITS -minram=256 -B 0.925925926 ${dada_file}"
#   dspsr -F1024:D -b1024 -E ${object}.eph -turns 1 -O ${outfile} -a PSRFITS -minram=256 -B 0.925925926 ${dada_file}
done

#!/bin/bash

object=J0534+2200

mkdir single_pulse_archives/
cd single_pulse_archives/
psrcat -e ${object} > ${object}.eph

for dada in `ls ../*.dada`  
do
   outfile=${dada_file%%dada}_single_pulse.ar 
   dada_file=`basename $dada`
   
   dada_dir=${dada_file%%.dada}
   mkdir -p $dada_dir
   cd $dada_dir
   
   psrcat -e ${object} > ${object}.eph
   
   ln -s ../../${dada_file}

   # use -cuda 0 when there is GPU     
   echo "dspsr -F1024:D -b1024 -E ${object}.eph -turns 1 -a PSRFITS -minram=256 -B 0.925925926 ${dada_file}"
   dspsr -F1024:D -b1024 -E ${object}.eph -turns 1 -a PSRFITS -minram=256 -B 0.925925926 ${dada_file}
   cd ..
done

#!/bin/bash

thresh_sigma=10
if [[ -n "$1" && "$1" != "-" ]]; then
   thresh_sigma=$1
fi

filfile=updated.fil
if [[ -n "$2" && "$2" != "-" ]]; then
   filfile="$2"
fi

numdms=200
if [[ -n "$3" && "$3" != "-" ]]; then
   numdms=$3
fi


echo "##########################################"
echo "PARAMETERS of presto_single_pulse_aavs2.sh :"
echo "thresh_sigma = $thresh_sigma"
echo "filfile      = $filfile"
echo "numdms       = $numdms"
echo "##########################################"

echo "INFO : activating Python environment with PRESTO single pulse search enabled"
echo "source ~/msok_python38_env/bin/activate"
source ~/msok_python38_env/bin/activate

outdir=presto_sps_thresh${thresh_sigma}
mkdir -p ${outdir}

# prepsubband :
echo "prepsubband updated.fil -o ${outdir}/ -numdms $numdms"
prepsubband updated.fil -o ${outdir}/ -numdms $numdms

# single pulse searches :
cd ${outdir}/
for datfile in `ls *.dat`
do  
   echo "python ~/github/presto/bin/single_pulse_search.py --threshold=${thresh_sigma} ${datfile}"
   python ~/github/presto/bin/single_pulse_search.py --threshold=${thresh_sigma} ${datfile}
done
cd ..

# merging all single pulses to a single plot:
echo "single_pulse_search.py _DM*.??*.singlepulse"
single_pulse_search.py _DM*.??*.singlepulse

echo "ps2pdf _singlepulse.ps singlepulse_thresh${thresh_sigma}.pdf"
ps2pdf _singlepulse.ps singlepulse_thresh${thresh_sigma}.pdf


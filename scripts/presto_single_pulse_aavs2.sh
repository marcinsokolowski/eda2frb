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

dmstep=1
if [[ -n "$4" && "$4" != "-" ]]; then
   dmstep=$4
fi

outdir=presto_sps_thresh${thresh_sigma}_numdms${numdms}_dmstep${dmstep}
if [[ -n "$5" && "$5" != "-" ]]; then
   outdir="$5"
fi

echo "##########################################"
echo "PARAMETERS of presto_single_pulse_aavs2.sh :"
echo "thresh_sigma = $thresh_sigma"
echo "filfile      = $filfile"
echo "numdms       = $numdms"
echo "dmstep       = $dmstep"
echo "outdir       = $outdir"
echo "##########################################"

echo "INFO : activating Python environment with PRESTO single pulse search enabled"
echo "source ~/msok_python38_env/bin/activate"
source ~/msok_python38_env/bin/activate

if [[ -d ${outdir} ]]; then
   echo "INFO : directory $outdir already exists -> processing skipped"
else
   mkdir -p ${outdir}
   
   # RFI flagging :
   if [[ -s updated_rfiflags.mask_rfifind.mask ]]; then
      echo "INFO : file updated_rfiflags.mask_rfifind.mask already exists -> RFI flagging skipped"
   else
      echo "rfifind -time 2.0 -o updated_rfiflags.mask updated.fil"
      rfifind -time 2.0 -o updated_rfiflags.mask updated.fil
   fi

#   cd ${outdir}
#   pwd
#   echo "ln -s ../updated.fil"
#   ln -s ../updated.fil  
#   echo "ln -s ../updated_rfiflags.mask_rfifind.mask"
#   ln -s ../updated_rfiflags.mask_rfifind.mask

   # prepsubband :
   # WARNING : order of parameters matter, see point 4. in https://github.com/scottransom/presto/issues/33
   # removed -o ${outdir} -> saving to local dir (see cd ${outdir}/)
   current_path=`pwd`
   echo "prepsubband -numdms $numdms -nsub 256 -dmstep ${dmstep} -mask updated_rfiflags.mask_rfifind.mask -o \"${outdir}/\" updated.fil"
   prepsubband -numdms $numdms -nsub 256 -dmstep ${dmstep} -mask updated_rfiflags.mask_rfifind.mask -o "${outdir}/" updated.fil

   presto_path=`which single_pulse_search.py`
   # single pulse searches :
   cd ${outdir}/
   for datfile in `ls *.dat`
   do  
      echo "python $presto_path --threshold=${thresh_sigma} ${datfile}"
      python $presto_path --threshold=${thresh_sigma} ${datfile}
   done

   # merging all single pulses to a single plot:
   echo "python $presto_path _DM*.??*.singlepulse"
   python $presto_path _DM*.??*.singlepulse

   echo "ps2pdf _singlepulse.ps singlepulse_thresh${thresh_sigma}.pdf"
   ps2pdf _singlepulse.ps singlepulse_thresh${thresh_sigma}.pdf

   cd ..
fi   

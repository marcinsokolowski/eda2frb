#!/bin/bash

template="202?_??_??_*"
if [[ -n "$1" && "$1" != "-" ]]; then
   template="$1"
fi

objects="FRB* J* B*"
if [[ -n "$2" && "$2" != "-" ]]; then
   objects="$2"
fi

local_dir=`pwd`
if [[ -n "$3" && "$3" != "-" ]]; then
   local_dir="$3"
   cd ${local_dir}
fi

show_pdf=0
if [[ -n "$4" && "$4" != "-" ]]; then
   show_pdf=$4
fi

remote_server="aavs2"
if [[ -n "$5" && "$5" != "-" ]]; then
   remote_server=$5
fi


remote_dir="/data/"

pwd

for dir in `ls -d ${template}`
do
   cd $dir
   pwd
   
   for object in `ls -d ${objects}`   
   do
      path=`pwd`
      pwd
      if [[ -d ${object}/256/filterbank_msok_64ch ]]; then
         cd ${object}/256/filterbank_msok_64ch
                           
         date
         echo "Copying PRESTO results in:"
         pwd

         echo "INFO : checking remote directory ${remote_dir}/${dir}/${object}/256/filterbank_msok_64ch/merged_channels_*/ on ${remote_server}"          
         remote_full_path=`ssh ${remote_server} "ls -d ${remote_dir}/${dir}/${object}/256/filterbank_msok_64ch/merged_channels_*/" 2>/dev/null | tail -1 | awk '{print substr($1,1,length($1)-1);}'`          
         echo "INFO : remote_full_path = $remote_full_path"
         
         if [[ -n "$remote_full_path" ]]; then         
            echo "rsync --exclude '*.dat' --exclude '*.inf' --exclude '*.fil' -avP ${remote_server}:${remote_full_path} ."
            rsync --exclude '*.dat' --exclude '*.inf' --exclude '*.fil' -avP ${remote_server}:${remote_full_path} .            

            echo "Finished processing at:"
            date
         
            echo "ls -al merged_channels_*/presto*/*.pdf" 
            ls -al merged_channels_*/presto*/*.pdf
         
            pdf_count=`ls merged_channels_*/presto*/*.pdf |wc -l`        
         
            pwd
            if [[ $pdf_count -gt 0 ]]; then
               if [[ $show_pdf -gt 0 ]]; then
                  echo "acroread merged_channels_??????????/presto*/*.pdf"
                  acroread merged_channels_??????????/presto*/*.pdf 
               fi
            else
               echo "WARNING : pdf_count = $pdf_count -> nothing to show"
            fi
         
         else
            echo "WARNING : directory ${dir} not found in ${remote_server}:${remote_dir}/"
         fi      
         cd ../../../
      else
         echo "INFO : ${object}/256/filterbank_msok_64ch - no such directory in $path -> skipped"
      fi      
   done
   cd ..
   
   echo
   echo
   echo
   pwd
   echo "sleep 4"
   sleep 4

done

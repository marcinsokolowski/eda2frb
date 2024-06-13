#!/bin/bash

dada_file=`ls *.dada | head -1`
if [[ -n "$1" && "$1" != "-" ]]; then
   dada_file="$1"
fi

ls -al ${dada_file} | awk '{print $5-4096" bytes -> "(($5-4096)/(2*2))" time samples";}'
ls -al ${dada_file} | awk '{print (($5-4096)/(2*2))*1.08/1000000.00" seconds";}'
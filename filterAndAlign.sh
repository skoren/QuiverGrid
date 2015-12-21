#!/usr/bin/env bash

######################################################################
#Copyright (C) 2015, Battelle National Biodefense Institute (BNBI);
#all rights reserved. Authored by: Sergey Koren
#
#This Software was prepared for the Department of Homeland Security
#(DHS) by the Battelle National Biodefense Institute, LLC (BNBI) as
#part of contract HSHQDC-07-C-00020 to manage and operate the National
#Biodefense Analysis and Countermeasures Center (NBACC), a Federally
#Funded Research and Development Center.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are
#met:
#
#* Redistributions of source code must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#
#* Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#* Neither the name of the Battelle National Biodefense Institute nor
#  the names of its contributors may be used to endorse or promote
#  products derived from this software without specific prior written
#  permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
######################################################################

SCRIPT_PATH=`cat scripts`

source ~/.bashrc
LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep LD_LIBRARY_PATH |wc -l`
if [ $LD_ADDITION -eq 1 ]; then
   LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep LD_LIBRARY_PATH |tail -n 1 | awk '{print $NF}'`
   export LD_LIBRARY_PATH=$LD_ADDITION:$LD_LIBRARY_PATH
fi

wrk=`pwd`
syst=`uname -s`
arch=`uname -m`
name=`uname -n`

if [ "$arch" = "x86_64" ] ; then
  arch="amd64"
fi

jobid=$SGE_TASK_ID
if [ x$jobid = x -o x$jobid = xundefined -o x$jobid = x0 ]; then
jobid=$1
fi

echo "The id is $1 and SGE $SGE_TASK_ID"
env

if test x$jobid = x; then
  echo Error: I need SGE_TASK_ID set, or a job index on the command line
  exit 1
fi

line=`cat input.fofn |head -n $jobid |tail -n 1`
prefix=`cat prefix`
reference=`cat reference`
whitelist=`cat whitelist`
fofn=`echo $line |awk '{print $1}'`
`find $fofn*.bax.h5 > $prefix.$jobid.fofn`

echo "Mapping $prefix $fofn to $reference whitelist is $whitelist"
if [ -e $prefix.$jobid.byCtg ]; then
   echo "Already done"
   exit
fi
if [ -e "$prefix.$jobid.cmp.h5" ]; then
   echo "Already done"
   exit
fi

cat $prefix.$jobid.fofn
echo "$prefix.$jobid.fofn"
if [ ! -e $prefix.filtered.$jobid.fofn ]; then
   mkdir -p `pwd`/filtered
   mkdir -p `pwd`/tmpdir
   filterOptions=`echo "MinReadScore=0.8000,MinSRL=500,MinRL=100${whitelist}"`
   echo "Running filter with $filterOptions"

   filter_plsh5.py --debug --filter=$filterOptions  --trim='True' --outputDir=`pwd`/filtered --outputSummary=`pwd`/$prefix.filtered.$jobid.csv --outputFofn=`pwd`/$prefix.filtered.$jobid.fofn `pwd`/$prefix.$jobid.fofn
fi
if [ ! -e $prefix.$jobid.cmp.h5 ]; then
   pbalign `pwd`/$prefix.$jobid.fofn "$reference" `pwd`/$prefix.$jobid.cmp.h5 --seed=1 --minAccuracy=0.75 --minLength=50 --concordant --algorithmOptions="-useQuality" --algorithmOptions=' -minMatch 12 -bestn 10 -minPctIdentity 70.0' --hitPolicy=randombest --tmpDir=`pwd`/tmpdir --nproc=8 --regionTable=`pwd`/$prefix.filtered.$jobid.fofn
   loadPulses `pwd`/$prefix.$jobid.fofn `pwd`/$prefix.$jobid.cmp.h5 -metrics DeletionQV,IPD,InsertionQV,PulseWidth,QualityValue,MergeQV,SubstitutionQV,DeletionTag -byread 
fi
count=`h5ls $prefix.$jobid.cmp.h5 |grep AlnInfo |wc -l`
ref=`h5ls -rf $prefix.$jobid.cmp.h5 |head -n 50 |grep FullName`
echo "Done $prefix.$jobid.cmp.h5. It has $count alignments aligned to reference $ref"

if [ $count -eq 0 ]; then
   rm $prefix.$jobid.cmp.h5
   rm $prefix.$jobid.fofn

   echo "Error: job $jobid failed, no alignments generated, please check the error log and try again"
fi

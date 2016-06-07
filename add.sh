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

LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#"  |grep LD_LIBRARY_PATH |wc -l`
if [ $LD_ADDITION -eq 1 ]; then
   LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#"  |grep LD_LIBRARY_PATH |tail -n 1 |awk '{print $NF}'`
   export LD_LIBRARY_PATH=$LD_ADDITION:$LD_LIBRARY_PATH
fi
VARIANTPARAMS=`cat smrtparams`

wrk=`pwd`
syst=`uname -s`
arch=`uname -m`
name=`uname -n`

if [ "$arch" = "x86_64" ] ; then
  arch="amd64"
fi

prefix=`cat prefix`
PREFIX=$prefix
FOFN=`cat fofn`
asm=`cat asm`
refs=`dirname $SEYMOUR_HOME`
refs="$refs/userdata/references"
org=`cat organism`

referenceUploader -c -p$refs -o \"$org\" --ploidy haploid -n $prefix -f $asm --saw='sawriter -welter' --samIdx='samtools faidx'

# now split the contigs
reference=$refs/$prefix
echo "$reference" > reference

numContigs=`cat $reference/reference.info.xml |grep "<contig length" |awk -F "id=" '{print $2}'|awk '{print $1}' |sed s/\"//g |wc -l |awk '{print $1}'`
NUM_JOBS=`wc -l $FOFN |awk '{print $1}'`
numPerBatch=`echo "$numContigs $NUM_JOBS" |awk '{printf("%d\n", ($1/$2)+1)}'`
echo "Num contigs $numContigs ($numPerBatch) for $NUM_JOBS $reference"

count=1
set -f
IFS='
'
for list in `cat $reference/reference.info.xml |grep "<contig length" |awk -F "id=" '{print $2}'|awk '{print $1}' |sed s/\"//g | xargs -n $numPerBatch`; do
   `echo $list | tr ' ' '\n' > $PREFIX.$count.contig_ids`
   count=$((count + 1))
done

unset IFS
set +f

> $PREFIX.bax.fofn
for input in `cat $FOFN |awk '{print $1}'`; do
   `find $input*.bax.h5 >> $PREFIX.bax.fofn`
done

> $PREFIX.cmph5.fofn
for jobid in `seq 1 $NUM_JOBS`; do
   echo "$PREFIX.$jobid.cmp.h5" >> $PREFIX.cmph5.fofn
done

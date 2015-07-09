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

MACHINE=`uname`
PROC=`uname -p`
SCRIPT_PATH=$BASH_SOURCE
SCRIPT_PATH=`dirname $SCRIPT_PATH`
JAVA_PATH=$SCRIPT_PATH:.

FOFN=$1
PREFIX=$2
REFERENCE=$3

NUM_JOBS=`wc -l $FOFN |awk '{print $1}'`

# now split the contigs
reference=$REFERENCE
numContigs=`cat $reference/reference.info.xml |grep "<contig length" |awk -F "id=" '{print $2}'|awk '{print $1}' |sed s/\"//g |wc -l |awk '{print $1}'`
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
for input in `cat input.fofn |awk '{print $1}'`; do
   `find $input*.bax.h5 >> $PREFIX.bax.fofn`
done

> $PREFIX.cmph5.fofn
for jobid in `seq 1 $NUM_JOBS`; do
   echo "$PREFIX.$jobid.cmp.h5" >> $PREFIX.cmph5.fofn
done

VARIANTPARAMS=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep  SMRTPORTAL |tail -n 1 |awk '{print $2}'`
echo "$PREFIX" > prefix
echo "$REFERENCE" > reference
echo "$SCRIPT_PATH" > scripts
echo "$SEYMOUR_HOME/$VARIANTPARAMS" > smrtparams

echo "Running with $PREFIX $REFERENCE $HOLD_ID"
USEGRID=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep USEGRID |awk '{print $NF}'`
if [ $USEGRID -eq 1 ]; then
   if [ $# -ge 4 ]; then
      qsub -pe threads 15 -l mem=2GB -t 1-$NUM_JOBS -hold_jid $4 -cwd -N "${PREFIX}align" -j y -o `pwd`/\$TASK_ID.out $SCRIPT_PATH/filterAndAlign.sh
   else
      qsub -pe threads 15 -l mem=2GB -t 1-$NUM_JOBS -cwd -N "${PREFIX}align" -j y -o `pwd`/\$TASK_ID.out $SCRIPT_PATH/filterAndAlign.sh
   fi
   qsub -pe threads 1 -l mem=5GB -hold_jid "${PREFIX}align" -t 1-$NUM_JOBS -cwd -N "${PREFIX}split" -j y -o `pwd`/\$TASK_ID.out $SCRIPT_PATH/splitByContig.sh
   qsub -pe threads 15 -l mem=2GB -t 1-$NUM_JOBS -hold_jid "${PREFIX}split" -cwd -N "${PREFIX}cns" -j y -o `pwd`/\$TASK_ID.cns.out $SCRIPT_PATH/consensus.sh
else
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/filterAndAlign.sh $i
   done
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/splitByContig.sh $i
   done
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/consensus.sh $i
   done
fi

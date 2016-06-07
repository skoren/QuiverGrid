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
ORG=$4

NUM_JOBS=`wc -l $FOFN |awk '{print $1}'`

VARIANTPARAMS=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep  SMRTPORTAL |tail -n 1 |awk '{print $2}'`
echo "$FOFN" > fofn
echo "$PREFIX" > prefix
echo "$REFERENCE" > asm
echo "$SCRIPT_PATH" > scripts
echo "$SEYMOUR_HOME/$VARIANTPARAMS" > smrtparams
echo "$ORG" > organism

if [ $# -ge 6 ]; then
   fileName=`readlink -e $6` 
   echo ",ReadWhitelist=$fileName" > whitelist
else
   echo "" > whitelist
fi

echo "Running with $PREFIX $REFERENCE $HOLD_ID"
USEGRID=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#" |grep USEGRID |awk '{print $NF}'`
if [ $USEGRID -eq 1 ]; then
   if [ $# -ge 5 ] && [ x$5 != "x" ]; then
      qsub -V -pe thread 8 -l mem_free=5G -cwd -N "${PREFIX}add" -hold_jid $5 -j y -o `pwd`/add.out $SCRIPT_PATH/add.sh
   else
      qsub -V -pe thread 8 -l mem_free=5G -cwd -N "${PREFIX}add" -j y -o `pwd`/add.out $SCRIPT_PATH/add.sh
   fi
   qsub -V -pe thread 8 -tc 50 -l mem_free=5G -t 1-$NUM_JOBS -hold_jid ${PREFIX}add -cwd -N "${PREFIX}align" -j y -o `pwd`/\$TASK_ID.out $SCRIPT_PATH/filterAndAlign.sh
   qsub -V -pe thread 1 -l mem_free=5G -tc 400 -hold_jid "${PREFIX}align" -t 1-$NUM_JOBS -cwd -N "${PREFIX}split" -j y -o `pwd`/\$TASK_ID.split.out $SCRIPT_PATH/splitByContig.sh
   qsub -V -pe thread 1 -l mem_free=5G -tc 400 -hold_jid "${PREFIX}split" -t 1-$NUM_JOBS -cwd -N "${PREFIX}cov" -j y -o `pwd`/\$TASK_ID.cov.out $SCRIPT_PATH/coverage.sh
   qsub -V -pe thread 8 -l mem_free=5G -tc 50 -t 1-$NUM_JOBS -hold_jid "${PREFIX}split" -cwd -N "${PREFIX}cns" -j y -o `pwd`/\$TASK_ID.cns.out $SCRIPT_PATH/consensus.sh
   qsub -V -pe thread 8 -l mem_free=5G -cwd -N "${PREFIX}rm" -hold_jid "${PREFIX}cns" -j y -o `pwd`/remove.out $SCRIPT_PATH/remove.sh
else
   sh $SCRIPT_PATH/add.sh
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/filterAndAlign.sh $i
   done
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/splitByContig.sh $i
   done
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/coverage.sh $i
   done
   for i in `seq 1 $NUM_JOBS`; do
      sh $SCRIPT_PATH/consensus.sh $i
   done
   sh $SCRIPT_PATH/remove.sh
fi

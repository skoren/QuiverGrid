#!/usr/bin/env bash

######################################################################
#  PUBLIC DOMAIN NOTICE
#
#  This software is "United States Government Work" under the terms of the United
#  States Copyright Act. It was written as part of the authors' official duties
#  for the United States Government and thus cannot be copyrighted. This software
#  is freely available to the public for use without a copyright
#  notice. Restrictions cannot be placed on its present or future use.
#
#  Although all reasonable efforts have been taken to ensure the accuracy and
#  reliability of the software and associated data, the National Human Genome
#  Research Institute (NHGRI), National Institutes of Health (NIH) and the
#  U.S. Government do not and cannot warrant the performance or results that may
#  be obtained by using this software or data. NHGRI, NIH and the U.S. Government
#  disclaim all warranties as to performance, merchantability or fitness for any
#  particular purpose.
#
#  Please cite the authors in any work or product based on this material.
######################################################################

SCRIPT_PATH=`cat scripts`

LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#"  |grep LD_LIBRARY_PATH |wc -l`
if [ $LD_ADDITION -eq 1 ]; then
   LD_ADDITION=`cat ${SCRIPT_PATH}/CONFIG |grep -v "#"  |grep LD_LIBRARY_PATH |tail -n 1 |awk '{print $NF}'`
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

if test x$jobid = x; then
  echo Error: I need SGE_TASK_ID set, or a job index on the command line
  exit 1
fi

prefix=`cat prefix`
reference=`cat reference`
asm=`ls $reference/sequence/*.fasta |awk '{print $1}'`
echo "Running with $prefix $asm"

#rm -rf $prefix.$jobid.byCtg
if [ -e "$prefix.$jobid.coverage.gff" ]; then
   echo "Already done!"
   exit
fi

if [ ! -e "$prefix.$jobid.byContig.cmp.h5" ]; then
   echo "Invalid job id $jobid, exiting"
else
      summarize_coverage.py --reference $reference --regionSize 100 $prefix.$jobid.byContig.cmp.h5 $prefix.$jobid.coverage.gff
fi

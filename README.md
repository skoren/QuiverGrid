# QuiverGrid

The distribution is a parallel wrapper around the [Quiver](http://github.com/PacificBiosciences/GenomicConsensus/blob/master/doc/QuiverFAQ.rst) consensus framework within the [SMRT Analysis Software](http://github.com/PacificBiosciences/SMRT-Analysis). The pipeline is composed of bash scripts, an example input fofn which shows how to input your bax.h5 files (you give paths without the .1.bax.h5), and how to launch the pipeline. 

The current pipeline has been designed to run on the SGE scheduling system and has hard-coded grid resource request parameters. You must edit quiver.sh to match your grid options. It is, in principle, possible to run on other grid engines but will require editing all shell scripts to not use SGE_TASK_ID but the appropriate variable for your grid environment and editing the qsub commands in quiver.sh to the appropriate commands for your grid environment.

To run the pipeline you need to:

1. You must have a working SMRT Analysis Software installation and have it configured so the SEYMOUR_HOME environment variable points to the installation and the pipeline binaries are in your path. 

2. Import your assembled fasta file into smrtportal as a reference (say named human_asm)

2. Create the input.fofn file which lists the SMRTcells you want to use for Quiver (the full path excluding .[1-3].bax.h5), it will treat each collection of bax.h5 files as a single SMRTcell.

3. run the pipeline specifying the input file, the path to the reference, and a prefix for the outputs:

```
sh quiver.sh input.fofn trio3 /path/to/smrtanalysis/userdata/references/human_asm
```

The pipeline is very rough and has undergone limited testing so user beware.

######CITE
If you find this pipeline useful, please cite the original Quiver paper:<br>
Chin et. al. [Nonhybrid, finished microbial genome assemblies from long-read SMRT sequencing data.](http://www.nature.com/nmeth/journal/v10/n6/full/nmeth.2474.html) Nature Methods, 2013

and the MHAP paper:<br>
Berlin et. al. [Assembling large genomes with single-molecule sequencing and locality-sensitive hashing.](http://www.nature.com/nbt/journal/v33/n6/full/nbt.3238.html) Nature Biotechnology, 2015


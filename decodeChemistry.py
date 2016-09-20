#!/usr/bin/env python

USAGE = \
"""
decodeChemistry.py

 Load chemistry info into a cmp.h5, just copying the triple.  Note
 that there is no attempt to "decode" chemistry barcodes here---this
 is a dumb pipe.

 usage:
  % decodeChemistry [input.fofn | list of input.ba[sx].h5] aligned_reads.cmp.h5
"""

import sys, h5py, numpy as np
from pbcore.io import *

class ChemistryLoadingException(BaseException): pass

STRING_DTYPE = h5py.special_dtype(vlen=bytes)

def main():
    if len(sys.argv) < 2:
        print USAGE
        return -1

    inputFilenames = sys.argv[1:]

    if len(inputFilenames) == 1 and inputFilenames[0].endswith(".fofn"):
        basFnames = list(enumeratePulseFiles(inputFilenames[0]))
    else:
        basFnames = inputFilenames

    for basFname in basFnames:
        bas = BasH5Reader(basFname)
        print "%s\t%s\t%s"%(bas.movieName, bas.sequencingChemistry, bas.chemistryBarcodeTriple)

if __name__ == '__main__':
    main()

#! /usr/bin/python3

import numpy as np
import csv
import sys

if __name__ == "__main__":
    no_in = 64
    shape = [ 3, no_in, 64 ]
    weights = np.zeros( shape )
    weights += -1*(np.random.random( shape ) < 0.3)
    weights += 1*(np.random.random( shape ) > 0.7)
    w_r = np.reshape( weights, [ 3*no_in, 64 ] )
    w_orig = w_r
    f = open( "conv_1.0_weights.csv", "w" )
    wrt = csv.writer( f )
    for x in w_orig:
        wrt.writerow( [ int(y) for y in x ] )
    f.close()
    num_reps = int( sys.argv[1] )
    for i in range( 1, num_reps ):
        zero = np.zeros( [ no_in, 64*i ] )
        w_A = np.concatenate( [ w_r, zero ] )
        zero = np.zeros( [ no_in*i, 64 ] )
        w_B = np.concatenate( [ zero, w_orig ] )
        w_r = np.concatenate( [ w_A, w_B ], 1 )
        f = open( "conv_1." + str(i) + "_weights.csv", "w" )
        wrt = csv.writer( f )
        for x in w_r:
            wrt.writerow( [ int(y) for y in x ] )
        f.close()

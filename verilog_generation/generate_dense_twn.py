#! /usr/bin/python3

import csv
import sys
import math
import numpy as np

def generate_ROM( weights, input_w, weights_name ):
    no_addr = int( len( weights ) / input_w )
    # need 2 bits to store each weight
    data_len = len( weights[0] ) * input_w * 2
    module_txt = "reg [" + str(data_len - 1) + ":0] " + weights_name + " [" + str( no_addr - 1 ) + ":0] = { "
    w_vec_all = []
    # transform -1 => 3, 1 => 1, 0 => 0
    weights = (2-weights)*(np.abs( weights ))
    for i in range( no_addr ):
        w_vec = []
        for tmp_v in zip( *list(weights[i*input_w:(i+1)*input_w]) ):
            tmp = sum([ x << 2*( len(tmp_v) - 1 - i ) for i, x in enumerate( tmp_v ) ])
            w_vec += [ tmp ]
        if input_w == 1:
            w_vec_new = []
            for j in range( int( len( w_vec )/2 ) ):
                w_vec_new += [ w_vec[2*j]*4 + w_vec[2*j+1] ]
            w_vec = w_vec_new
        # convert to hex
        no_hex_chars = max( int( input_w/ 2 ), 1 )
        format_str = '00' + str( no_hex_chars ) + 'x'
        w_vec = [ format( x, format_str ) for x in w_vec ]
        # w_vec = list( reversed( w_vec ))
        w_vec_all += [ str(data_len) + "'h" + "".join( w_vec ) ]
    w_vec_all = reversed( w_vec_all )
    module_txt += ", ".join( w_vec_all )
    module_txt += "};\n"
    return module_txt

# for dense 3
def generate_fp_ROM( weights, weights_name ):
    no_addr = len( weights )
    # need 2 bits to store each weight
    data_len = len( weights[0] )*8
    module_txt = "reg [" + str(data_len - 1) + ":0] " + weights_name + " [" + str( no_addr - 1 ) + ":0] = { "
    w_vec_all = []
    # transform -1 => 3, 1 => 1, 0 => 0
    weights = np.round( weights*(1 << 3) ).astype( int )
    for i in range( no_addr ):
        w_vec = (weights[i] < 0)*( 1 << 8 ) + weights[i]
        w_vec_all += [ "192'h" + "".join( [ format( x, '002x' ) for x in w_vec ] ) ]
    w_vec_all = reversed( w_vec_all )
    module_txt += ", ".join( w_vec_all )
    module_txt += "};\n"
    return module_txt

if __name__ == "__main__":
    fname_w = sys.argv[1] # weights
    weights_name = fname_w.split(".csv")[0].split("vgg_")[1]
    f = open( fname_w )
    rdr = csv.reader( f )
    weights = np.array( [ [ int( x ) for x in y ] for y in rdr ] )
    input_w = int( sys.argv[2] )
    module_txt = generate_ROM( weights, input_w, weights_name )
    fname_out = sys.argv[3]
    f = open( fname_out, "w" )
    f.write( module_txt )
    f.close()

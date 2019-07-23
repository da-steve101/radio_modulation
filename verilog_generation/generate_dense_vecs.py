#! /usr/bin/python3

import csv
import sys
import math
import numpy as np

def format_hex( x, bits = 16 ):
    chars = int( math.ceil( bits / 4 ) )
    if x < 0:
        x += (1 << bits)
    return str(bits) + "'h" + f"{x:0{chars}x}"

def get_weights( weights, bits, no_in ):
    w_vec = []
    for i in range( 0, len(weights), no_in ):
        tmp_w = np.reshape( weights[i*no_in:(i+1)*no_in], [-1] )
        hex_w = [ format_hex( x, bits ) for x in tmp_w ]
        w_vec += [ "{ " + ", ".join( reversed(hex_w) ) + " }" ]
    return "{ " +  ", ".join( reversed(w_vec) ) + " }"

if __name__ == "__main__":
    fname_w = sys.argv[1]
    out_name = sys.argv[2]
    lyr = sys.argv[3]
    rshift = int(sys.argv[4])
    bits = int(sys.argv[5])
    no_inputs = int(sys.argv[6])
    f = open( fname_w )
    rdr = csv.reader( f )
    weights = np.array( [ [ int(float( x ) * ( 1 << rshift )) for x in y ] for y in rdr ] )
    f.close()
    w_str = get_weights( weights, bits, no_inputs )
    f_out = open( out_name, "w" )
    d1_cyc = int(weights.shape[0]/no_inputs)
    log2_d1_cyc = math.ceil(math.log2( d1_cyc ))
    f_out.write( "localparam LOG2_D%s_CYC = %d;\n" % ( lyr, log2_d1_cyc ) )
    f_out.write( "localparam D%s_CYC = %d;\n" % ( lyr, d1_cyc ) )
    f_out.write( "localparam D%s_CH = %d;\n" % ( lyr, weights.shape[1] ) )
    f_out.write( "reg [D%s_CYC-1:0][D%s_CH-1:0][%d:0] dw_%s = " % ( lyr, lyr, bits-1, lyr ) )
    f_out.write( w_str )
    f_out.write( ";\n" )
    f_out.close()

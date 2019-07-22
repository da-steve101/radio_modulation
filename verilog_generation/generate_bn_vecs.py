#! /usr/bin/python3

import csv
import sys
import math

def format_hex( x, bits = 16 ):
    chars = int( math.ceil( bits / 4 ) )
    if x < 0:
        x += (1 << bits)
    return str(bits) + "'h" + f"{x:0{chars}x}"
    
if __name__ == "__main__":
    f = open( sys.argv[1] )
    bn_id = sys.argv[3]
    rdr = csv.reader( f )
    bw = 16 + 6
    data = [ [ int( round( float( x ) * ( 1 << 6 ) ) ) for x in y ] for y in rdr ]
    CH_IN = len(data[0])
    hex_data = [ list(reversed([ format_hex(x, bw)  for x in y ])) for y in data ]
    vecs = [ "{ " + ", ".join( x ) + " }" for x in hex_data ]
    a_str = vecs[0]
    b_str = vecs[1]
    f_out = open( sys.argv[2], "w" )
    f_out.write( "reg [%d:0][%d:0] bn%s_a = " % ( CH_IN-1, bw-1, bn_id ));
    f_out.write( a_str + ";\n" )
    f_out.write( "reg [%d:0][%d:0] bn%s_b = "  % ( CH_IN-1, bw-1, bn_id ));
    f_out.write( b_str + ";\n" )
    f_out.close()

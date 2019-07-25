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
    a_prec = int(sys.argv[4])
    b_prec = int(sys.argv[5])
    rdr = csv.reader( f )
    bw = 16 + a_prec
    data = [ [ float( x ) for x in y ] for y in rdr ]
    data[0] = [ round( x * ( 1 << a_prec ) ) for x in data[0] ]
    data[1] = [ round( x * ( 1 << b_prec ) ) for x in data[1] ]
    CH_IN = len(data[0])
    hex_data = [ list(reversed([ format_hex(x, bw)  for x in y ])) for y in data ]
    vecs = [ "{ " + ", ".join( x ) + " }" for x in hex_data ]
    a_str = vecs[0]
    b_str = vecs[1]
    f_out = open( sys.argv[2], "w" )
    bn_id_u = bn_id.upper()
    f_out.write( "localparam BN%s_CH = %d;\n" % ( bn_id_u, CH_IN ));
    f_out.write( "localparam BN%s_BW = %d;\n" % ( bn_id_u, bw ));
    f_out.write( "reg [BN%s_CH-1:0][%d:0] bn%s_a = " % ( bn_id_u, bw-1, bn_id ));
    f_out.write( a_str + ";\n" )
    f_out.write( "reg [BN%s_CH-1:0][%d:0] bn%s_b = " % ( bn_id_u, bw-1, bn_id ));
    f_out.write( b_str + ";\n" )
    f_out.close()

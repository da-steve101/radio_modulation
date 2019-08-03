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
    bn_rshift = int(sys.argv[4])
    bn_bw_in = int(sys.argv[5])
    bn_bw_out = int(sys.argv[6])
    bn_maxval = int(sys.argv[7])
    lyr_bw_out = int(sys.argv[8])
    rdr = csv.reader( f )
    data = [ [ int( x ) for x in y ] for y in rdr ]
    # work out the bw needed
    a_bw = math.ceil( math.log2( max([ abs(x) for x in data[0] ]) + 1) ) + 1
    b_bw = math.ceil( math.log2( max([ abs(x) for x in data[1] ]) + 1) ) + 1
    CH_IN = len(data[0])
    a_hex = list(reversed([ format_hex(x, a_bw) for x in data[0] ]))
    b_hex = list(reversed([ format_hex(x, b_bw) for x in data[1] ]))
    a_str = "{ " + ", ".join( a_hex ) + " }"
    b_str = "{ " + ", ".join( b_hex ) + " }"
    f_out = open( sys.argv[2], "w" )
    bn_id_u = bn_id.upper()
    f_out.write( "localparam BN%s_CH = %d;\n" % ( bn_id_u, CH_IN ));
    f_out.write( "localparam BN%s_BW_A = %d;\n" % ( bn_id_u, a_bw ));
    f_out.write( "localparam BN%s_BW_B = %d;\n" % ( bn_id_u, b_bw ));
    f_out.write( "localparam BN%s_RSHIFT = %d;\n" % ( bn_id_u, bn_rshift ));
    f_out.write( "localparam BN%s_BW_IN = %d;\n" % ( bn_id_u, bn_bw_in ));
    f_out.write( "localparam BN%s_BW_OUT = %d;\n" % ( bn_id_u, bn_bw_out ));
    f_out.write( "localparam BN%s_MAXVAL = %d;\n" % ( bn_id_u, bn_maxval ));
    f_out.write( "localparam LYR%s_BW_OUT = %d;\n" % ( bn_id_u, lyr_bw_out ));
    f_out.write( "reg [BN%s_CH-1:0][BN%s_BW_A-1:0] bn%s_a = " % ( bn_id_u, bn_id_u, bn_id ));
    f_out.write( a_str + ";\n" )
    f_out.write( "reg [BN%s_CH-1:0][BN%s_BW_B-1:0] bn%s_b = " % ( bn_id_u, bn_id_u, bn_id ));
    f_out.write( b_str + ";\n" )
    f_out.close()

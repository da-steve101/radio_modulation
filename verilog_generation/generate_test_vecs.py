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
    sfx = sys.argv[3]
    shift = 4
    if len(sys.argv) > 4:
        shift = int(sys.argv[4])
    rdr = csv.reader( f )
    data = [ [ int( float( x ) * ( 1 << shift ) ) for x in y ] for y in rdr ]
    CH_IN = len(data[0])
    hex_data = [ list(reversed([ format_hex(x)  for x in y ])) for y in data ]
    vecs = [ "{ " + ", ".join( x ) + " }" for x in hex_data ]
    signal_str = "{" + ", ".join( vecs ) + "};"
    f_out = open( sys.argv[2], "w" )
    f_out.write( "localparam BW_%s = 16;\n" % sfx )
    f_out.write( "localparam CH_%s = %d;\n" % ( sfx, CH_IN ) )
    f_out.write( "localparam SIG_LEN_%s = %d;\n" % ( sfx, len(data) ) )
    f_out.write( "localparam CNTR_BW_%s = $clog2( %d );\n" % (sfx, len(data) ) )
    f_out.write( "wire [CH_%s-1:0][BW_%s-1:0] signal_%s [SIG_LEN_%s] = " % ( sfx, sfx, sfx.lower(), sfx ) )
    f_out.write( signal_str );
    f_out.close()

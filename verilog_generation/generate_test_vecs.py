#! /usr/bin/python3

import csv
import sys
import math
import argparse
import common

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--file_in", type = str, required = True,
                         help="The floating point values as a csv" + \
                         "The number of columns in the CSV is the number of channels" + \
                         "The number of rows is the length of the signal")
    parser.add_argument( "--file_out", type = str, required = True,
                         help="The filename to write the quantized verilog output to")
    parser.add_argument( "--is_in", action = 'store_true',
                         help="Set this file as IN instead of OUT")
    parser.add_argument("--mul", type=float, default = 1.0,
                        help = "What to multiply the values a,b in the file with" )
    parser.add_argument("--bw", type=int, default = 16,
                        help = "What bitwidth to use for the variables" )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    sfx = "OUT"
    if args.is_in:
        sfx = "IN"
    f_out = open( args.file_out, "w" )
    data = common.get_data_from_csv( args.file_in, args.mul, True )
    CH_IN = len(data[0])
    cntr_bw = int( math.ceil( math.log2( len(data) ) ) )
    hex_data = [ list(reversed([ common.format_hex(x, args.bw)  for x in y ])) for y in data ]
    vecs = [ "{ " + ", ".join( x ) + " }" for x in hex_data ]
    signal_str = "{" + ", ".join( vecs ) + "};"
    f_out.write( "localparam BW_%s = %d;\n" % ( sfx, args.bw ) )
    f_out.write( "localparam CH_%s = %d;\n" % ( sfx, CH_IN ) )
    f_out.write( "localparam SIG_LEN_%s = %d;\n" % ( sfx, len(data) ) )
    f_out.write( "localparam CNTR_BW_%s = %d;\n" % (sfx, cntr_bw ) )
    f_out.write( "wire [CH_%s-1:0][BW_%s-1:0] signal_%s [SIG_LEN_%s] = " % ( sfx, sfx, sfx.lower(), sfx ) )
    f_out.write( signal_str );
    f_out.close()

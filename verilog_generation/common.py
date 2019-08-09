#! /usr/bin/python3

import math
import csv

def unsigned( x, bits = 16 ):
    return ( x + ( 1 << bits ) ) % ( 1 << bits ) # make unsigned

def format_hex( x, bits = 16 ):
    chars = int( math.ceil( bits / 4 ) )
    x = unsigned( x, bits )
    return str(bits) + "'h" + f"{x:0{chars}x}"

def get_data_from_csv( fname, mul = 1, use_int = False ):
    f = open( fname )
    rdr = csv.reader( f )
    data = [ [ int(round(float(x)*mul)) if use_int else float(x)*mul for x in y ] for y in rdr ]
    f.close()
    return data

#! /usr/bin/python3

import twn_generator as twn
import csv
import sys
import os

def make_conv( idx, bw, create_op, model_dir ):
    f_in = model_dir + "/vgg_conv_lyr%d.csv" % idx
    f_tree = model_dir + "/vgg_conv_lyr%d_td_cse.csv" % idx
    mod_out = "conv%d" % idx
    f_out = model_dir + "/" + mod_out + ".sv"
    if not os.path.exists(f_tree):
        matrix, no_in, no_out, initial_no_adds = twn.get_matrix( f_in  )
        matrix = twn.td_CSE( matrix )
        twn.write_output( f_tree, matrix, initial_no_adds, no_in, no_out )
        twn.verify_tree( f_in, f_tree )
    f = open( f_out, "w" )
    f.write( twn.SMM_generate( f_tree, mod_out, bw, bw, create_op ) )
    f.close()

if __name__ == "__main__":
    model_dir = sys.argv[1]
    no_px = 2
    for idx in range( 1, 8 ):
        if idx < no_px + 1:
            create_op = twn.create_normal_add_op
            bw = 16
        else:
            twn.write_serial_adder_module( model_dir +  "/serial_adder.sv" )
            create_op = twn.create_serial_add_op
            bw = int( 16 / ( 1 << ( idx - no_px ) ) )
            if bw < 1:
                bw = 1
        make_conv( idx, bw, create_op, model_dir )

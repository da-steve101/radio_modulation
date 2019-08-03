#! /usr/bin/python3

import twn_generator as twn
import csv
import sys
import os

def make_conv( idx, bw_in, bw_out, create_op, model_dir ):
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
    f.write( twn.SMM_generate( f_tree, mod_out, bw_in, bw_out, create_op ) )
    f.close()

def map_to_ops( op_str, model_dir ):
    ops = []
    for c in op_str:
        if c == "n":
            ops += [ twn.create_normal_add_op ]
        if c == "s":
            twn.write_serial_adder_module( model_dir +  "/serial_adder.sv" )
            ops += [ twn.create_serial_add_op ]
        if c == "p":
            ops += [ twn.create_pop_count_op ]
    return ops

if __name__ == "__main__":
    model_dir = sys.argv[1]
    bws_in = [ int(x) for x in sys.argv[2].split(",") ]
    bws_out = [ int(x) for x in sys.argv[3].split(",") ]
    ops = map_to_ops( sys.argv[4], model_dir )
    for i, bw_in, bw_out, op in zip( range( len(bws_in) ), bws_in, bws_out, ops ):
        make_conv( i+1, bw_in, bw_out, op, model_dir )

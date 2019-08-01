#! /usr/bin/python3

import twn_generator as twn
import csv
import sys
import os
import numpy as np

def make_conv( idx, model_dir ):
    f_in = model_dir + "/vgg_conv_lyr%d.csv" % idx
    f_tree = model_dir + "/vgg_conv_lyr%d_td_cse.csv" % idx
    mod_out = "conv%d" % idx
    f_out = model_dir + "/" + mod_out
    if not os.path.exists(f_tree):
        matrix, no_in, no_out, initial_no_adds = twn.get_matrix( f_in )
        matrix = twn.td_CSE( matrix )
        twn.write_output( f_tree, matrix, initial_no_adds, no_in, no_out )
        twn.verify_tree( f_in, f_tree )
    twn.write_tree_to_c( f_tree, f_out )

def make_dense( idx, model_dir ):
    f_in = model_dir + "/vgg_dense_%d.csv" % idx
    f_tree = model_dir + "/vgg_dense_%d_td_cse.csv" % idx
    mod_out = "dense%d" % idx
    f_out = model_dir + "/" + mod_out
    if not os.path.exists(f_tree):
        matrix, no_in, no_out, initial_no_adds = twn.get_matrix( f_in )
        matrix = twn.td_CSE( matrix )
        twn.write_output( f_tree, matrix, initial_no_adds, no_in, no_out )
        twn.verify_tree( f_in, f_tree )
    twn.write_tree_to_c( f_tree, f_out )

def make_bn( idx, model_dir, f_type = "lyr", r_shift = 8, quantize_out = None ):
    f_in = model_dir + "/vgg_bn_%s%d.csv" % (f_type,idx)
    f_a_b = model_dir + "/vgg_bn_%s%d_a_b.csv" % (f_type,idx)
    if f_type == "lyr":
        f_out = model_dir + "/bn%d_a_b" % idx
    else:
        f_out = model_dir + "/bnd%d_a_b" % idx
    if quantize_out[0] is not None:
        twn.write_bn_relu_to_c( f_a_b, r_shift, f_out, quantize_to = quantize_out )
    else:
        twn.write_bn_relu_to_c( f_a_b, r_shift, f_out )

if __name__ == "__main__":
    model_dir = sys.argv[1]
    twn_incr = int(sys.argv[2])
    r_shifts = [8]*9
    q_outs = [( None, None )]*9
    PREC = 6
    if twn_incr > 0: # if quantized
        # always do dense layers as 1 bit
        q_outs[0] = (PREC, 1) # first layer needs to shift as 6 frac bits in from image
        # leave a, b and r as is for first layer
        for i in range( 1, twn_incr ):
            q_outs[i] = (0,1) # binary layer
        for i in range( twn_incr, 6 ):
            q_outs[i] = (0, ( 1 << (2**( i - twn_incr + 1 ) )) - 1 )
        for i in range( twn_incr, 6 ):
            if q_outs[i][1] > ( 1 << 8 ) - 1:
                q_outs[i] = ( None, None )
        # always output binary to the dense layers and dense layers
        if q_outs[5] == (None,None):
            q_outs[6] = (6,1)
        else:
            q_outs[6] = (0,1)
        q_outs[7:9] = [(0,1)]*2
    for idx in range( 1, 8 ):
        make_conv( idx, model_dir )
        make_bn( idx, model_dir, r_shift = r_shifts[idx-1], quantize_out = q_outs[idx-1] )
    for idx in range( 1, 3 ):
        make_dense( idx, model_dir )
        make_bn( idx, model_dir, f_type = "dense_", r_shift = r_shifts[idx+6], quantize_out = q_outs[idx+6] )
    twn.write_matrix_to_c_ary( model_dir + "/input_img.csv" )
    if q_outs[8] == (None, None):
        twn.write_matrix_to_c_ary( model_dir + "/vgg_dense_3.csv", "#define USE_D3_RSHIFT" )
    else:
        twn.write_matrix_to_c_ary( model_dir + "/vgg_dense_3.csv" )
    twn.write_matrix_to_c_ary( model_dir + "/pred_output.csv" )

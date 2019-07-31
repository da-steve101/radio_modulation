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

def make_bn( idx, model_dir, prec_out, f_type = "lyr", a_mult = 256,
             b_mult = 16384, r_shift = 8, quantize_out = None ):
    f_in = model_dir + "/vgg_bn_%s%d.csv" % (f_type,idx)
    f_a_b = model_dir + "/vgg_bn_%s%d_a_b.csv" % (f_type,idx)
    f = open( f_in )
    rdr = csv.reader( f )
    data = [ [ float(y) for y in x ]for x in rdr ]
    f.close()
    a = np.array( data[0] )
    b = np.array( data[1] )
    if quantize_out is None:
        b += 0.5/( 1 << prec_out )
    else:
        b += 0.5/(( 1 << prec_out ) - 1)
    f = open( f_a_b, "w" )
    wrt = csv.writer( f )
    wrt.writerow( [ int(round( x * a_mult )) for x in a ] )
    wrt.writerow( [ int(round( x * b_mult )) for x in b ] )
    f.close()
    if f_type == "lyr":
        f_out = model_dir + "/bn%d_a_b" % idx
    else:
        f_out = model_dir + "/bnd%d_a_b" % idx
    twn.write_bn_relu_to_c( f_a_b, r_shift, f_out, quantize_to = quantize_out )

if __name__ == "__main__":
    model_dir = sys.argv[1]
    twn_incr = int(sys.argv[2])
    a_mults = [(1 << 8)]*9
    b_mults = [(1 << 14)]*9
    r_shifts = [8]*9
    q_outs = [None]*9
    PREC = 6
    precs = [PREC]*10
    if twn_incr > 0: # if quantized
        # always do dense layers as 1 bit
        q_outs[0] = (PREC, 1) # first layer needs to shift as 6 frac bits in from image
        precs[1] = 1
        # leave a, b and r as is for first layer
        for i in range( 1, twn_incr ):
            q_outs[i] = (0,1) # binary layer
            b_mults[i] = (1 << 8) # input and output are 0 or 1 so don't need to change a,r
            precs[i+1] = 1
        for i in range( twn_incr, 6 ):
            precs[i+1] = precs[i]*2
            q_outs[i] = (0, ( 1 << precs[i+1] ) - 1 )
            scaling = ( ( 1 << precs[i+1] ) - 1 )/( ( 1 << ( precs[i+1] / 2 ) ) - 1 )
            b_mults[i] = (1 << 8) # b should not be more shifted than a
            a_mults[i] *= scaling
            b_mults[i] *= scaling
        for i in range( twn_incr, 6 ):
            if precs[i+1] >= 16:
                precs[i+1] = PREC
                a_mults[i] = 1 << 8
                b_mults[i] = 1 << 14
                q_outs[i] = None
        precs[7:10] = [1]*3
        scaling = 1
        if precs[6] > 1 and precs[6] < 16:
            scaling = 1/( (1 << precs[6] ) - 1 )
        elif precs[6] >= 16:
            scaling = 1/(1 << 6)
        b_mults[6:9] = [(1 << 8)]*3 # b should not be more shifted than a
        a_mults[6] *= scaling
        b_mults[6] *= scaling
        # always output binary to the dense layers and dense layers
        q_outs[6:9] = [(0,1)]*3
    for idx in range( 1, 8 ):
        make_conv( idx, model_dir )
        make_bn( idx, model_dir, precs[idx], a_mult = a_mults[idx-1], b_mult = b_mults[idx-1],
                 r_shift = r_shifts[idx-1], quantize_out = q_outs[idx-1] )
    for idx in range( 1, 3 ):
        make_dense( idx, model_dir )
        make_bn( idx, model_dir, precs[idx+7], f_type = "dense_", a_mult = a_mults[idx+6], b_mult = b_mults[idx+6],
                 r_shift = r_shifts[idx+6], quantize_out = q_outs[idx+6] )
    twn.write_matrix_to_c_ary( model_dir + "/input_img.csv" )
    twn.write_matrix_to_c_ary( model_dir + "/vgg_dense_3.csv" )
    twn.write_matrix_to_c_ary( model_dir + "/pred_output.csv" )

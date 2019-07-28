#! /usr/bin/python3

import twn_generator as twn
import csv
import sys
import os

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

def make_bn( idx, model_dir, f_type = "lyr", a_prec = 8, b_prec = 14, r_shift = 8 ):
    f_in = model_dir + "/vgg_bn_%s%d.csv" % (f_type,idx)
    f_a_b = model_dir + "/vgg_bn_%s%d_a_b.csv" % (f_type,idx)
    f = open( f_in )
    rdr = csv.reader( f )
    data = [ [ float(y) for y in x ]for x in rdr ]
    f.close()
    f = open( f_a_b, "w" )
    wrt = csv.writer( f )
    wrt.writerow( [ round(x * ( 1 << a_prec )) for x in data[0] ] )
    wrt.writerow( [ round(x * ( 1 << b_prec )) for x in data[1] ] )
    f.close()
    if f_type == "lyr":
        f_out = model_dir + "/bn%d_a_b" % idx
    else:
        f_out = model_dir + "/bnd%d_a_b" % idx
    twn.write_bn_relu_to_c( f_a_b, r_shift, f_out )

if __name__ == "__main__":
    model_dir = sys.argv[1]
    for idx in range( 1, 8 ):
        make_conv( idx, model_dir )
        make_bn( idx, model_dir )
    for idx in range( 1, 3 ):
        make_dense( idx, model_dir )
        make_bn( idx, model_dir, f_type = "dense_" )
    twn.write_matrix_to_c_ary( model_dir + "/input_img.csv" )
    twn.write_matrix_to_c_ary( model_dir + "/vgg_dense_3.csv" )
    twn.write_matrix_to_c_ary( model_dir + "/pred_output.csv" )

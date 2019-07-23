#! /usr/bin/python3

import twn_generator as twn
import tensorflow as tf
import csv
import sys
import numpy as np
import os

def decode_twn( sess, conv_filter, nu, fname ):
    clip_val = conv_filter #tf.clip_by_value( conv_filter, -1, 1 )
    thres = nu * tf.reduce_mean(tf.abs(clip_val))
    x_shape = conv_filter.get_shape()
    unmasked = tf.where(
        tf.logical_and(
            tf.greater( clip_val, -thres ),
            tf.less( clip_val, thres )
        ),
        tf.constant( 0.0, shape = x_shape ),
        clip_val )
    eta = tf.reduce_mean( tf.abs( unmasked ) )
    #unmasked = tf.multiply( unmasked, block_mask )
    t_x = tf.where( tf.less_equal( unmasked, -thres ),
                    tf.constant( -1.0, shape = x_shape ),
                    unmasked )
    t_x = tf.where( tf.greater_equal( unmasked, thres ),
                    tf.constant( 1.0, shape = x_shape ),
                    t_x )
    eta_r, thres_r, quant_w = sess.run( [ eta, thres, t_x ] )
    quant_w = np.round(np.reshape( quant_w, [-1, x_shape[-1]] )).astype( int )
    f = open( fname, "w" )
    wrt = csv.writer( f )
    for x in quant_w:
        wrt.writerow( x )
    f.close()
    return eta_r

def get_bn_vars( sess, ops, lyr_name ):
    bn_ops = [ op for op in ops if "batch_normalization" in op.name and
               # "quant" in op.name and
               op.type == "VariableV2" and
               lyr_name in op.name and "Adam" not in op.name ]
    gamma = [ op for op in bn_ops if "gamma" in op.name ][0].outputs[0]
    beta = [ op for op in bn_ops if "beta" in op.name ][0].outputs[0]
    mean = [ op for op in bn_ops if "moving_mean" in op.name ][0].outputs[0]
    var = [ op for op in bn_ops if "moving_var" in op.name ][0].outputs[0]
    gamma_r, beta_r, mean_r, var_r = sess.run( [ gamma, beta, mean, var ] )
    return ( mean_r, var_r, gamma_r, beta_r )

def write_bn( sess, ops, lyr_name, act_prec, eta_r ):
    mean, var, gamma, beta = get_bn_vars( sess, ops, lyr_name )
    print( act_prec )
    if act_prec is None:
        abvars = twn.get_AB( mean, var, gamma, beta, eta_r )
    else:
        s_in = 1.0/eta_r
        if lyr_idx == 1 or act_prec[lyr_idx-2] > 1:
            s_in *= ( 1 << act_prec[lyr_idx-2] ) - 1
        bits = act_prec[ lyr_idx - 1 ]
        abvars = twn.get_AB_quantized( mean, var, gamma, beta, s_in, bits, is_round = True )
    f = open( "vgg_bn_" + lyr_name + ".csv", "w" )
    wrt = csv.writer( f )
    for row in abvars:
        wrt.writerow( row )
    f.close()

def get_conv_filter( ops, lyr_idx ):
    conv_op = [ op for op in ops if "conv_filter" in op.name and op.type == "VariableV2" and "lyr" + str(lyr_idx) in op.name ][0]
    return conv_op.outputs[0]

def get_dense_mat( ops, dense_name ):
    dense_op = [ op for op in ops if
                 #"quant" in op.name and #
                 dense_name in op.name and op.type == "VariableV2" ][0]
    return dense_op.outputs[0]

if __name__ == "__main__":
    prefix = sys.argv[1] # the model name
    nu_conv = float(sys.argv[2]) # the conv nu
    nu_dense = float(sys.argv[3]) # the dense nu
    twn_incr_act = int( sys.argv[4] ) # number of bin lyrs or full prec in conv before doubling
    if not os.path.exists( prefix ):
        os.mkdir( prefix )
    grph = tf.train.import_meta_graph( prefix + ".meta" )
    sess = tf.Session()
    grph.restore( sess, prefix )
    cnn = tf.get_default_graph()
    ops = cnn.get_operations()
    os.chdir( prefix ) # put all files in this dir

    nu = [ 0.7 ] + [ nu_conv ]*6 + [ nu_dense ]*2
    if twn_incr_act == -1:
        act_prec = None
    else:
        act_prec = [1]*twn_incr_act + [ 1 << ( i + 1 ) for i in range(6-twn_incr_act) ] + [1]*3
    for lyr_idx in range( 1, 8 ):
        conv_filter = get_conv_filter( ops, lyr_idx )
        lyr_name = "lyr" + str(lyr_idx)
        eta_r = decode_twn( sess, conv_filter, nu[lyr_idx-1], "vgg_conv_" + lyr_name + ".csv" )
        print( eta_r )
        write_bn( sess, ops, lyr_name, act_prec, eta_r )

    # do the dense layers
    for dense_var, dense_lyr in [ ("dense_8", 1), ("dense_9", 2) ]:
        dense_mat = get_dense_mat( ops, dense_var )
        lyr_name = "dense_" + str(dense_lyr)
        eta_r = decode_twn( sess, dense_mat, nu[6+dense_lyr], "vgg_" + lyr_name + ".csv" )
        write_bn( sess, ops, lyr_name, act_prec, eta_r )

    kernel = [ op for op in ops if "dense_3/dense/kernel" in op.name and op.type == "VariableV2" ][0].outputs[0]
    # bias = [ op for op in ops if "dense_3/dense/bias" in op.name and op.type == "VariableV2" ][0].outputs[0]
    kernel_r = sess.run( kernel )
    kernel_r = np.round( kernel_r * ( 1 << 4 ) )/(1 << 4 )
    # kernel_r, bias_r = sess.run( [ kernel, bias ] )
    f = open( "vgg_dense_3.csv", "w" )
    wrt = csv.writer( f )
    for k in kernel_r:
        wrt.writerow( k )
    f.close()

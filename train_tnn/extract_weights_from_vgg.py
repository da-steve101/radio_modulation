#! /usr/bin/python3

import tensorflow as tf
import csv
import sys
import numpy as np

def decode_twn( sess, conv_filter, nu, fname ):
    clip_val = tf.clip_by_value( conv_filter, -1, 1 )
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
    quant_w = np.reshape( quant_w, [-1, x_shape[-1]] ).astype( int )
    f = open( fname, "w" )
    wrt = csv.writer( f )
    # wrt.writerow( [ eta_r, thres_r ] )
    for x in quant_w:
        wrt.writerow( x )
    f.close()
    return eta_r

def get_conv_filter( ops, lyr_idx ):
    conv_op = [ op for op in ops if "conv_filter" in op.name and op.type == "VariableV2" and "lyr" + str(lyr_idx) in op.name ][0]
    return conv_op.outputs[0]

def get_dense_mat( ops, dense_name ):
    dense_op = [ op for op in ops if "quant" in op.name and dense_name in op.name and op.type == "VariableV2" ][0]
    return dense_op.outputs[0]

def get_c_vec( sess, ops, lyr_name, eta_r, fname, cast_to_int = True ):
    bn_ops = [ op for op in ops if "batch_normalization" in op.name and "quant" in op.name and op.type == "VariableV2" and lyr_name in op.name and "Adam" not in op.name ]
    gamma = [ op for op in bn_ops if "gamma" in op.name ][0].outputs[0]
    beta = [ op for op in bn_ops if "beta" in op.name ][0].outputs[0]
    mean = [ op for op in bn_ops if "moving_mean" in op.name ][0].outputs[0]
    var = [ op for op in bn_ops if "moving_var" in op.name ][0].outputs[0]
    gamma_r, beta_r, mean_r, var_r = sess.run( [ gamma, beta, mean, var ] )
    a = gamma_r / np.sqrt( var_r + 0.001 )
    # a = a * ( a < 10**15 ) # if very big then prob is ignored anyway
    b = beta_r - a * mean_r
    a = a * eta_r
    c_vec = -b/a
    if cast_to_int:
        c_vec = np.ceil( c_vec ).astype( int )
    f = open( fname, "w" )
    wrt = csv.writer( f )
    wrt.writerow( c_vec )
    f.close()

if __name__ == "__main__":
    prefix = sys.argv[1]
    grph = tf.train.import_meta_graph( prefix + "/vgg_test.meta" )
    sess = tf.Session()
    grph.restore( sess, prefix + "/vgg_test" )
    cnn = tf.get_default_graph()
    ops = cnn.get_operations()

    nu = [ 0.7 ] + [ 1.0 ]*6
    
    for lyr_idx in range( 1, 8 ):
        conv_filter = get_conv_filter( ops, lyr_idx )
        eta_r = decode_twn( sess, conv_filter, nu[lyr_idx-1], "vgg_conv_lyr_" + str( lyr_idx ) + ".csv" )
        get_c_vec( sess, ops, "lyr" + str(lyr_idx), eta_r, "vgg_c_vec_lyr_" + str( lyr_idx ) + ".csv", cast_to_int = ( lyr_idx != 1 ) )

    # do the dense layers
    for dense_var, dense_lyr in [ ("dense_8", "dense_1"), ("dense_9", "dense_2") ]:
        dense_mat = get_dense_mat( ops, dense_var )
        eta_r = decode_twn( sess, dense_mat, 1.4, "vgg_" + dense_lyr + ".csv" )
        get_c_vec( sess, ops, dense_lyr, eta_r, "vgg_c_vec_" + dense_lyr + ".csv" )
        dense_mat = get_dense_mat( ops, dense_var )

    kernel = [ op for op in ops if "quant/dense_3/dense/kernel" in op.name and op.type == "VariableV2" ][0].outputs[0]
    bias = [ op for op in ops if "quant/dense_3/dense/bias" in op.name and op.type == "VariableV2" ][0].outputs[0]
    kernel_r, bias_r = sess.run( [ kernel, bias ] )
    f = open( "vgg_dense_3.csv", "w" )
    wrt = csv.writer( f )
    wrt.writerow( bias_r )
    for k in kernel_r:
        wrt.writerow( k )
    f.close()

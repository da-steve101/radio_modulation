#! /usr/bin/python3

import tensorflow as tf
import quantization as q

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_conv_layer_full_prec( x, training, no_filt = 64 ):
    cnn = tf.layers.conv1d( x, no_filt, 3, padding = "SAME", use_bias = False )
    cnn = tf.layers.batch_normalization( cnn, training = training )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    cnn = tf.nn.relu( cnn )
    return cnn

def get_conv_layer( x, training, no_filt = 128, nu = None, low_prec = True ):
    if nu is None:
        return get_conv_layer_full_prec( x, training, no_filt )
    filter_shape = [ 3, x.get_shape()[-1], no_filt ]
    conv_filter = tf.get_variable( "conv_filter", filter_shape )
    conv_filter = q.trinarize( conv_filter, nu = nu  )
    cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    cnn = tf.layers.batch_normalization( cnn, training = training )
    with tf.device('/device:CPU:0'):
        tf.summary.histogram( "conv_dist", cnn )
        tf.summary.histogram( "conv_filter", conv_filter )
    if low_prec is not None:
        cnn = q.shaped_relu( cnn, low_prec )
    else:
        cnn = tf.nn.relu( cnn )
    return cnn

def get_net( x, training = False, use_SELU = False, low_prec = None, nu = None, no_filt = 64 ):
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    if nu is None:
        nu = [None]*9
    if low_prec is None:
        low_prec = [None]*7
    with tf.variable_scope("lyr1"):
        cnn = get_conv_layer( x, training, no_filt = no_filt, nu = nu[0], low_prec = low_prec[0] )
    with tf.variable_scope("lyr2"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[1], low_prec = low_prec[1] )
    with tf.variable_scope("lyr3"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[2], low_prec = low_prec[2] )
    with tf.variable_scope("lyr4"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[3], low_prec = low_prec[3] )
    with tf.variable_scope("lyr5"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[4], low_prec = low_prec[4] )
    with tf.variable_scope("lyr6"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[5], low_prec = low_prec[5] )
    with tf.variable_scope("lyr7"):
        cnn = get_conv_layer( cnn, training, no_filt = no_filt, nu = nu[6], low_prec = low_prec[6] )
    cnn = tf.layers.flatten( cnn )
    if use_SELU:
        dense_1 = tf.get_variable( "dense_8", [ cnn.get_shape()[-1], 128 ], initializer = get_initializer() )
        dense_2 = tf.get_variable( "dense_9", [ 128, 128 ], initializer = get_initializer() )
        with tf.variable_scope("dense_1"):
            cnn = tf.matmul( cnn, dense_1 )
            cnn = tf.nn.selu( cnn )
            dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.where( training, dropped, cnn )
        with tf.variable_scope("dense_2"):
            cnn = tf.matmul( cnn, dense_2 )
            cnn = tf.nn.selu( cnn )
            dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.where( training, dropped, cnn )
    else:
        dense_1 = tf.get_variable( "dense_8", [ cnn.get_shape()[-1], 128 ] )
        dense_2 = tf.get_variable( "dense_9", [ 128, 128 ] )
        dense_1 = q.trinarize( dense_1, nu = nu[7] )
        dense_2 = q.trinarize( dense_2, nu = nu[8] )
        with tf.variable_scope("dense_1"):
            cnn = tf.matmul( cnn, dense_1 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            if low_prec[7] is not None:
                cnn = q.shaped_relu( cnn, low_prec[7] )
            else:
                cnn = tf.nn.relu( cnn )
        with tf.variable_scope("dense_2"):
            cnn = tf.matmul( cnn, dense_2 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            if low_prec[8] is not None:
                cnn = q.shaped_relu( cnn, low_prec[8] )
            else:
                cnn = tf.nn.relu( cnn )
    with tf.variable_scope("dense_3"):
        pred = tf.layers.dense( cnn, 24 )
    return pred

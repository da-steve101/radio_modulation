#! /usr/bin/python3

import tensorflow as tf
import quantization as q

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_conv_layer( x, training, no_filt = 128, nu = None, low_prec = True ):
    filter_shape = [ 3, x.get_shape()[-1], no_filt ]
    conv_filter = tf.get_variable( "conv_filter", filter_shape )
    if nu is not None:
        conv_filter = q.trinarize( conv_filter, nu = nu  )
    cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    cnn = tf.layers.batch_normalization( cnn, training = training )
    with tf.device('/device:CPU:0'):
        tf.summary.histogram( "conv_dist", cnn )
        tf.summary.histogram( "conv_filter", conv_filter )
    if low_prec:
        cnn = q.shaped_relu( cnn )
    else:
        cnn = tf.nn.relu( cnn )
    return cnn

def get_conv_layer_orig( x, training, no_filt = 64 ):
    cnn = tf.layers.conv1d( x, no_filt, 3, padding = "SAME", use_bias = False )
    cnn = tf.layers.batch_normalization( cnn, training = training )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    cnn = q.shaped_relu( cnn )
    return cnn

def get_net( x, training = False, use_SELU = False, low_prec = True, nu = 1.0 ):
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    with tf.variable_scope("lyr1"):
        cnn = get_conv_layer( x, training, nu = 0.7, low_prec = low_prec )
    with tf.variable_scope("lyr2"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    with tf.variable_scope("lyr3"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    with tf.variable_scope("lyr4"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    with tf.variable_scope("lyr5"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    with tf.variable_scope("lyr6"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    with tf.variable_scope("lyr7"):
        cnn = get_conv_layer( cnn, training, nu = nu, low_prec = low_prec )
    cnn = tf.layers.flatten( cnn )
    dense_1 = tf.get_variable( "dense_8", [ cnn.get_shape()[-1], 128 ], initializer = get_initializer() )
    dense_2 = tf.get_variable( "dense_9", [ 128, 128 ], initializer = get_initializer() )
    if use_SELU:
        with tf.variable_scope("dense_1"):
            # cnn = tf.layers.dense( cnn, 128, kernel_initializer = get_initializer() )
            cnn = tf.matmul( cnn, dense_1 )
            cnn = tf.nn.selu( cnn )
            dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.where( training, dropped, cnn )
        with tf.variable_scope("dense_2"):
            # cnn = tf.layers.dense( cnn, 128, kernel_initializer = get_initializer() )
            cnn = tf.matmul( cnn, dense_2 )
            cnn = tf.nn.selu( cnn )
            dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.where( training, dropped, cnn )
    else:
        dense_1 = q.trinarize( dense_1, nu = 1.4 )
        dense_2 = q.trinarize( dense_2, nu = 1.4 )
        with tf.variable_scope("dense_1"):
            cnn = tf.matmul( cnn, dense_1 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            cnn = q.shaped_relu( cnn )
        with tf.variable_scope("dense_2"):
            cnn = tf.matmul( cnn, dense_2 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            cnn = q.shaped_relu( cnn )
    with tf.variable_scope("dense_3"):
        pred = tf.layers.dense( cnn, 24 )
    return pred

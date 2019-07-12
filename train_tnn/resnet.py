#! /usr/bin/python3

import tensorflow as tf
import quantization as q

def residual_unit( x, training = False, nu = None ):
    no_filt = x.get_shape()[-1]
    filter_shape = [ 3, no_filt, no_filt ]
    with tf.variable_scope("res_unit_a"):
        conv_filter = tf.get_variable( "conv_filter", filter_shape )
        if nu is not None:
            conv_filter = q.trinarize( conv_filter, nu = nu  )
        cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        if nu is not None:
            cnn = q.shaped_relu( cnn )
        else:
            cnn = tf.nn.relu( cnn )
    with tf.variable_scope("res_unit_b"):
        conv_filter = tf.get_variable( "conv_filter", filter_shape )
        if nu is not None:
            conv_filter = q.trinarize( conv_filter, nu = nu  )
        cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        cnn = cnn + x # shortcut
        if nu is not None:
            cnn = q.shaped_relu( cnn )
        else:
            cnn = tf.nn.relu( cnn )
        return cnn

def residual_stack( x, no_filt, training = False, nu = None ):
    filter_shape = [ 3, x.get_shape()[-1], no_filt ]
    with tf.variable_scope("res_stack_a"):
        conv_filter = tf.get_variable( "conv_filter", filter_shape )
        if nu is not None:
            conv_filter = q.trinarize( conv_filter, nu = nu  )
        cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
    with tf.variable_scope("res_stack_b"):
        cnn = residual_unit( cnn, training = training, nu = nu )
    with tf.variable_scope("res_stack_c"):
        cnn = residual_unit( cnn, training = training, nu = nu )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_net( x, training = False ):
    # remove the bias from all examples and make
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    no_filt = 64
    with tf.variable_scope("block_1"):
        cnn = residual_stack( x, no_filt, training = training, nu = 0.7 )
    with tf.variable_scope("block_2"):
        cnn = residual_stack( cnn, no_filt, training = training, nu = 1.0 )
    with tf.variable_scope("block_3"):
        cnn = residual_stack( cnn, no_filt, training = training, nu = 1.0 )
    with tf.variable_scope("block_4"):
        cnn = residual_stack( cnn, no_filt, training = training, nu = 1.0 )
    with tf.variable_scope("block_5"):
        cnn = residual_stack( cnn, no_filt, training = training, nu = 1.0 )
    with tf.variable_scope("block_6"):
        cnn = residual_stack( cnn, no_filt, training = training, nu = 1.0 )
    cnn = tf.layers.flatten( cnn )
    with tf.variable_scope("dense_1"):
        cnn = tf.layers.dense( cnn, 128, kernel_initializer = get_initializer() )
        cnn = tf.nn.selu( cnn )
        dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
        cnn = tf.where( training, dropped, cnn )
    with tf.variable_scope("dense_2"):
        cnn = tf.layers.dense( cnn, 128, kernel_initializer = get_initializer() )
        cnn = tf.nn.selu( cnn )
        dropped = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
        cnn = tf.where( training, dropped, cnn )
    with tf.variable_scope("dense_3"):
        pred = tf.layers.dense( cnn, 24 )
    return pred

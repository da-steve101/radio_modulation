#! /usr/bin/python3

import tensorflow as tf

def residual_unit( x, training = False ):
    no_filt = x.get_shape()[-1]
    with tf.variable_scope("res_unit_a"):
        cnn = tf.layers.conv1d( x, no_filt, 3, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        cnn = tf.nn.relu( cnn )
    with tf.variable_scope("res_unit_b"):
        cnn = tf.layers.conv1d( cnn, no_filt, 3, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        cnn = cnn + x # shortcut
        cnn = tf.nn.relu( cnn )
        return cnn

def residual_stack( x, no_filt, training = False ):
    with tf.variable_scope("res_stack_a"):
        cnn = tf.layers.conv1d( x, no_filt, 3, padding = "SAME" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
    with tf.variable_scope("res_stack_b"):
        cnn = residual_unit( cnn, training = training )
    with tf.variable_scope("res_stack_c"):
        cnn = residual_unit( cnn, training = training )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_net( x, training = False, no_filt = 64 ):
    # remove the bias from all examples and make
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    with tf.variable_scope("block_1"):
        cnn = residual_stack( x, no_filt, training = training )
    with tf.variable_scope("block_2"):
        cnn = residual_stack( cnn, no_filt, training = training )
    with tf.variable_scope("block_3"):
        cnn = residual_stack( cnn, no_filt, training = training )
    with tf.variable_scope("block_4"):
        cnn = residual_stack( cnn, no_filt, training = training )
    with tf.variable_scope("block_5"):
        cnn = residual_stack( cnn, no_filt, training = training )
    with tf.variable_scope("block_6"):
        cnn = residual_stack( cnn, no_filt, training = training )
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

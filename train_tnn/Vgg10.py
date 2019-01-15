#! /usr/bin/python3

import tensorflow as tf
import quantization as q

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_initializer_conv():
    return tf.variance_scaling_initializer(scale=2.0, mode='fan_avg')

def get_conv_layer( x, training, no_filt = 64, quantize_w = False, quantize_act = False ):
    conv_filter = tf.get_variable( "conv_filter", x.get_shape() + [ no_filt ], initializer = get_initializer_conv() )
    if quantize_w:
        conv_filter = q.quantize_weights( conv_filter, quantize_w )
    cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "same" )
    mean, var = tf.nn.moments( cnn, [0, 1, 2] )
    ema = tf.train.ExponentialMovingAverage(decay=0.999)
    train_op = ema.apply( [ mean, var ] )
    tf.add_to_collection( tf.GraphKeys.UPDATE_OPS, train_op )
    moving_mean = ema.average( mean )
    moving_var = ema.average( var )
    beta = tf.get_variable( "beta", [ no_filt ], initializer = tf.zeros_initializer() )
    gamma = tf.get_variable( "gamma", [ no_filt ], initializer = tf.ones_initializer() )
    if quantize_act:
        mean = q.quantize_activations( mean, quantize_act )
        var = q.quantize_activations( var, quantize_act )
        moving_mean = q.quantize_activations( moving_mean, quantize_act )
        moving_var = q.quantize_activations( moving_var, quantize_act )
        cnn = q.quantize_acitvations( cnn, quantize_act )
    if quantize_w:
        beta = q.quantize_w( beta, quantize_w )
        gamma = q.quantize_w( gamma, quantize_w )
    m = tf.where( training, moving_mean, mean )
    v = tf.where( training, moving_var, var )
    cnn = tf.nn.batch_normalization( cnn, m, v, beta, gamma, 1e-3 )
    if quantize_act:
        cnn = q.quantize_activations( cnn, quantize_act )
    cnn = tf.nn.relu( cnn )
    if quantize_act:
        cnn = q.quantize_activations( cnn, quantize_act )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_net( x, training = False, use_SELU = False ):
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    with tf.variable_scope("lyr1"):
        cnn = get_conv_layer( x, training )
    with tf.variable_scope("lyr2"):
        cnn = get_conv_layer( cnn, training )
    with tf.variable_scope("lyr3"):
        cnn = get_conv_layer( cnn, training )
    with tf.variable_scope("lyr4"):
        cnn = get_conv_layer( cnn, training )
    with tf.variable_scope("lyr5"):
        cnn = get_conv_layer( cnn, training )
    with tf.variable_scope("lyr6"):
        cnn = get_conv_layer( cnn, training )
    with tf.variable_scope("lyr7"):
        cnn = get_conv_layer( cnn, training )
    cnn = tf.layers.flatten( cnn )
    if use_SELU:
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
    else:
        with tf.variable_scope("dense_1"):
            cnn = tf.layers.dense( cnn, 128 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            cnn = tf.nn.relu( cnn )
        with tf.variable_scope("dense_2"):
            cnn = tf.layers.dense( cnn, 128 )
            cnn = tf.layers.batch_normalization( cnn, training = training )
            cnn = tf.nn.relu( cnn )
    with tf.variable_scope("dense_3"):
        pred = tf.layers.dense( cnn, 24 )
    return pred

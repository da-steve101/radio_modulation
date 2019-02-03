#! /usr/bin/python3

import tensorflow as tf
import quantization as q

def get_initializer():
    return tf.variance_scaling_initializer(scale=1.0, mode='fan_in')

def get_initializer_conv():
    return tf.initializers.glorot_normal()

def batch_norm_quantized( x, training, decay, quantize_w = False, quantize_act = False ):
    mean, var = tf.nn.moments( x, [0, 1] )
    ema = tf.train.ExponentialMovingAverage(decay=decay)
    train_op = ema.apply( [ mean, var ] )
    tf.add_to_collection( tf.GraphKeys.UPDATE_OPS, train_op )
    moving_mean = ema.average( mean )
    moving_var = ema.average( var )
    beta = tf.get_variable( "beta", [ x.get_shape()[-1] ], initializer = tf.zeros_initializer() )
    gamma = tf.get_variable( "gamma", [ x.get_shape()[-1] ], initializer = tf.ones_initializer() )
    if quantize_act:
        mean = q.quantize_activations( mean, quantize_act )
        var = q.quantize_activations( var, quantize_act )
        moving_mean = q.quantize_activations( moving_mean, quantize_act )
        moving_var = q.quantize_activations( moving_var, quantize_act )
    if False: # quantize_w:
        beta = q.quantize_weights( beta, quantize_w )
        gamma = q.quantize_weights( gamma, quantize_w )
    m = tf.where( training, mean, moving_mean )
    v = tf.where( training, var, moving_var )
    cnn = tf.nn.batch_normalization( x, m, v, beta, gamma, 1e-3 )
    if quantize_act:
        cnn = q.quantize_activations( cnn, quantize_act )
    return cnn

def get_conv_layer( x, training, no_filt = 128, quantize_w = False, quantize_act = False ):
    filter_shape = [ 3, x.get_shape()[-1], no_filt ]
    starting_dist_scale = 10
    conv_filter = starting_dist_scale*tf.get_variable( "conv_filter", filter_shape, initializer = get_initializer_conv() )
    if quantize_w:
        constrained = q.quantize_weights( conv_filter, quantize_w )
        err_q = tf.stop_gradient( conv_filter - conv_filter )
    else:
        constrained = tf.stop_gradient( tf.round( tf.clip_by_value( conv_filter, -1, 1 ) ) )
        err_q = tf.losses.absolute_difference( conv_filter, constrained )
    tf.add_to_collection( "Quant_Errs", err_q )
    tf.add_to_collection( "Weights", conv_filter )
    if quantize_w:
        conv_filter = constrained
    else:
        conv_filter = conv_filter + tf.stop_gradient( conv_filter * tf.math.abs( tf.round( tf.clip_by_value( 5*conv_filter, -1, 1 ) ) ) - conv_filter )
    cnn = x
    cnn = tf.nn.conv1d( cnn, conv_filter, 1, padding = "SAME" )
    scaling = tf.get_variable( "scaling", [ no_filt ], initializer = tf.ones_initializer() )/ starting_dist_scale
    act_reg = tf.stop_gradient( cnn ) * tf.math.abs( scaling )
    # relu regularizer to pull scaling down to near 1
    cnn_pull = tf.nn.relu( act_reg - 1.25 )
    # need something to push scaling up from zero too
    cnn_push = tf.nn.relu( 0.5 - tf.math.abs( act_reg ) ) # minimize this to push from 0.5 to 1/0/-1
    tf.add_to_collection( "Activations_opt", cnn_pull  + cnn_push )    
    cnn = cnn * tf.stop_gradient( tf.math.abs( scaling ) )
    if quantize_act:
        cnn = q.quantize_activations( cnn, quantize_act )
    # cnn = batch_norm_quantized( cnn, training, 0.99, quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.device('/device:CPU:0'):
        tf.summary.scalar( "conv_act_mean", tf.reduce_mean( cnn ) )
        tf.summary.scalar( "conv_act_max", tf.reduce_max( cnn ) )
        tf.summary.histogram( "scaling", scaling )
        tf.summary.histogram( "conv_dist", cnn )
        tf.summary.histogram( "conv_filter", conv_filter )
    cnn = tf.nn.relu( cnn )
    if quantize_act:
        cnn = q.quantize_activations( cnn, quantize_act )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_conv_layer_orig( x, training, no_filt = 64 ):
    cnn = tf.layers.conv1d( x, no_filt, 3, padding = "SAME", use_bias = False )
    # cnn = tf.layers.batch_normalization( cnn, training = training )
    cnn = batch_norm_quantized( cnn, training, 0.99 )
    cnn = tf.nn.relu( cnn )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_net( x, training = False, use_SELU = False, quantize_w = False, quantize_act = False ):
    mean, var = tf.nn.moments(x, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x.get_shape()[1], 1 ] )
    x = ( x - mean )
    with tf.variable_scope("lyr1"):
        cnn = get_conv_layer( x, training ) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr2"):
        cnn = get_conv_layer( cnn, training) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr3"):
        cnn = get_conv_layer( cnn, training) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr4"):
        cnn = get_conv_layer( cnn, training) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr5"):
        cnn = get_conv_layer( cnn, training) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr6"):
        cnn = get_conv_layer( cnn, training) # , quantize_w = quantize_w, quantize_act = quantize_act )
    with tf.variable_scope("lyr7"):
        cnn = get_conv_layer( cnn, training, quantize_w = 1, quantize_act = quantize_act )
    cnn = tf.layers.flatten( cnn )
    if use_SELU:
        dense_1 = tf.get_variable( "dense_8", [ cnn.get_shape()[-1], 128 ], initializer = get_initializer() )
        dense_2 = tf.get_variable( "dense_9", [ 128, 128 ], initializer = get_initializer() )
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

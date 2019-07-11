#! /usr/bin/python3

'''
Methods to train:

A) Two stage training - train Q(weights) then Q(act)
B) Slowly lowering precision
C) Teacher student
'''

import tensorflow as tf

def stop_grad( real, quant ):
    return real + tf.stop_gradient( quant - real )

def quantize( zr, k ):
    scaling = tf.cast( tf.pow( 2.0, k ) - 1, tf.float32 )
    return tf.round( scaling * zr )/scaling

def quantize_weights( w, k ):
    # normalize first
    # zr = tf.tanh( w )/( tf.reduce_max( tf.abs( tf.tanh( w ) ) ) )
    zr = tf.clip_by_value( w, -1, 1 )
    quant = quantize( zr, k )
    return stop_grad( w, quant )

def quantize_activations( xr, k ):
    clipped = tf.clip_by_value( xr, 0, 1 )
    quant = quantize( clipped, k )
    return stop_grad( xr, quant )

def shaped_relu( x, k = 1.0 ):
    # return tf.nn.relu( x )
    act = tf.clip_by_value( x, 0, 1 )
    quant = quantize( act, k ) # tf.round( act )
    return act  + tf.stop_gradient( quant - act )

def trinarize( x, nu = 1.0 ):
    clip_val = tf.clip_by_value( x, -1, 1 )
    x_shape = x.get_shape()
    thres = nu * tf.reduce_mean(tf.abs(clip_val))
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
                    tf.multiply( tf.constant( -1.0, shape = x_shape ), eta ),
                    unmasked )
    t_x = tf.where( tf.greater_equal( unmasked, thres ),
                    tf.multiply( tf.constant( 1.0, shape = x_shape ), eta ),
                    t_x )
    return x + tf.stop_gradient( t_x - x )

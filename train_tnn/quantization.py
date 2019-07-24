#! /usr/bin/python3

import tensorflow as tf

def quantize( zr, k ):
    scaling = tf.cast( tf.pow( 2.0, k ) - 1, tf.float32 )
    return tf.ceil( scaling * zr )/scaling

def shaped_relu( x, k = 1.0 ):
    act = tf.clip_by_value( x, 0, 1 )
    quant = quantize( act, k )
    return act  + tf.stop_gradient( quant - act )

def trinarize( x, nu = 1.0 ):
    clip_val = x # tf.clip_by_value( x, -1, 1 )
    x_shape = x.get_shape()
    thres = nu * tf.reduce_mean(tf.abs(clip_val))
    unmasked = tf.where(
        tf.logical_and(
            tf.greater( x, -thres ),
            tf.less( x, thres )
        ),
        tf.constant( 0.0, shape = x_shape ),
        clip_val )
    eta = tf.reduce_mean( tf.abs( unmasked ) )
    t_x = tf.where( tf.less_equal( unmasked, -thres ),
                    tf.multiply( tf.constant( -1.0, shape = x_shape ), eta ),
                    unmasked )
    t_x = tf.where( tf.greater_equal( unmasked, thres ),
                    tf.multiply( tf.constant( 1.0, shape = x_shape ), eta ),
                    t_x )
    return x + tf.stop_gradient( t_x - x )

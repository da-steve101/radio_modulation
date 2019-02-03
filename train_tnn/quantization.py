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



#! /usr/bin/python3

'''
Methods to train:

A) Two stage training - train Q(weights) then Q(act)
B) Slowly lowering precision
C) Teacher student
'''

import tensorflow as tf

def quantize( zr, k ):
    scaling = tf.pow( 2, k ) - 1
    return tf.round( scaling * zr )/scaling

def quantize_weights( w, k ):
    # normalize first
    zr = ( tf.tanh( w )/( 2 * tf.maximum( tf.abs( tf.tanh( w ) ) ) ) ) + 0.5
    return quantize( zr, k )

def quantize_activations( xr, k ):
    clipped = tf.clip_by_value( xr, 0, 1 )
    return quantize( clipped, k )



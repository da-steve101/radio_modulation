#! /usr/bin/python3

'''
This program generates test vectors for the bn_relu_quantize module
'''

import numpy as np
import tensorflow as tf

def quantize( zr, k ):
    scaling = tf.cast( tf.pow( 2.0, k ) - 1, tf.float32 )
    return tf.round( scaling * zr ) / scaling
    # return tf.ceil( scaling * zr ) / scaling

def shaped_relu( x, k = 1.0 ):
    act = tf.clip_by_value( x, 0, 1 )
    quant = quantize( act, k )
    return quant

def tf_bn_relu_quant( x, mean, var, gamma, beta, bits ):
    bn = tf.nn.batch_normalization( x, mean, var, beta, gamma, 0.001 )
    y = shaped_relu( bn, bits )
    with tf.Session() as sess:
        y, bn = sess.run([y, bn])
    return ( y, bn )

def get_mul_a_b( mean, var, gamma, beta, s_in, s_out, bits, is_round = True ):
    a = gamma / np.sqrt( var + 0.001 )
    b = beta - a * mean
    a *= s_out/s_in
    b *= s_out
    if is_round:
        x_min = np.floor( s_in*( 1/2 - b )/a)
        x_max = np.ceil( s_in*(s_out - 1/2 - b )/a)
        b += 0.4999999
    else:
        x_min = np.floor(-b*s_in/a)
        x_max = np.ceil( s_in*( s_out - b )/a )
        b += 0.999999
    prec_s = ( 1 << ( bits + 2 ) )
    a = np.round( a * prec_s )/prec_s
    b = np.round( b * prec_s )/prec_s
    return a, b, x_min, x_max

def do_mul( x, a, b, x_min, x_max, s_out ):
    zeros = ( x <= x_min )
    ones = ( x >= x_max )
    y = a*x + b
    y[zeros] = 0
    y[ones] = s_out
    return np.floor( y )

if __name__ == "__main__":
    x_len = 20
    mean = np.array([0.1]*x_len)
    var = np.array([16.1]*x_len)
    beta = np.array([0.1]*x_len)
    gamma = np.array([0.75]*x_len)
    scaling_in = ( (1 << 2) - 1 )
    bits = 3
    scaling_out = ( (1 << bits) - 1 )
    x = np.array( list(range( -5, 15, 1 )) )
    x = x.astype( np.float32 )
    tf_y, bn = tf_bn_relu_quant( x/scaling_in, mean, var, gamma, beta, bits )
    tf_y = ( tf_y*scaling_out ).astype(int)
    a, b, x_min, x_max = get_mul_a_b( mean, var, gamma, beta, scaling_in, scaling_out, bits )
    print( a[0], b[0], x_min[0], x_max[0] )
    print( x )
    q_y = do_mul( x, a, b, x_min, x_max, scaling_out )
    print( q_y.astype(int) )
    print( tf_y - q_y, sum( tf_y == q_y ) == len( tf_y ) )

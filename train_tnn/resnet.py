#! /usr/bin/python3

import tensorflow as tf

def residual_unit( x, training = False ):
    no_filt = x.get_shape().as_list()[-1]
    with tf.variable_scope("res_unit_a"):
        cnn = tf.layers.conv1d( x, no_filt, 3, padding = "same" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        cnn = tf.nn.relu( cnn )
    with tf.variable_scope("res_unit_b"):
        cnn = tf.layers.conv1d( cnn, no_filt, 3, padding = "same" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
        cnn = cnn + x # shortcut
        return tf.nn.relu( cnn )

def residual_stack( x, no_filt, training = False ):
    with tf.variable_scope("res_stack_a"):
        cnn = tf.layers.conv1d( x, no_filt, 1, padding = "same" )
        cnn = tf.layers.batch_normalization( cnn, training = training )
    with tf.variable_scope("res_stack_b"):
        cnn = residual_unit( cnn, training = training )
    with tf.variable_scope("res_stack_c"):
        cnn = residual_unit( cnn, training = training )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    return cnn

def get_initializer():
    return tf.contrib.layers.variance_scaling_initializer( factor = 1.0 )

def get_net( x, training = False, use_SELU = False ):
    with tf.variable_scope("block_1"):
        cnn = residual_stack( x, 32, training = training )
    with tf.variable_scope("block_2"):
        cnn = residual_stack( cnn, 32, training = training )
    with tf.variable_scope("block_3"):
        cnn = residual_stack( cnn, 32, training = training )
    with tf.variable_scope("block_4"):
        cnn = residual_stack( cnn, 32, training = training )
    with tf.variable_scope("block_5"):
        cnn = residual_stack( cnn, 32, training = training )
    with tf.variable_scope("block_6"):
        cnn = residual_stack( cnn, 32, training = training )
    cnn = tf.layers.flatten( cnn )
    if use_SELU:
        with tf.variable_scope("dense_1"):
            cnn = tf.layers.dense( cnn, 128, kernel_initializer= get_initializer() )
            if training:
                cnn = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.nn.selu( cnn )
        with tf.variable_scope("dense_2"):
            cnn = tf.layers.dense( cnn, 128, kernel_initializer= get_initializer() )
            if training:
                cnn = tf.contrib.nn.alpha_dropout( cnn, 0.95 )
            cnn = tf.nn.selu( cnn )
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

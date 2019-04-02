#! /usr/bin/python3

import csv
import tensorflow as tf
import quantization as q
import Vgg10 as vgg
import h5py
import sys
import numpy as np
import tqdm
import os

# for the first layer quantize between -2 and 2?
# 4 / 2^(no_bits)


def conv_sum_computation( inputs, weights, c_vec ):
    zero = np.zeros( [ 1, inputs.shape[1] ] )
    inputs_pad = np.concatenate( [ zero, inputs, zero ] )
    conv_sum = np.array( [ np.matmul( np.reshape( inputs_pad[i:(3+i),:], [weights.shape[0]] ), weights ) for i in range( len( inputs ) ) ] )
    if c_vec is None:
        return conv_sum
    conv_max = np.array( [ np.maximum( conv_sum[2*i,:], conv_sum[2*i+1,:] ) for i in range( int( len( conv_sum) / 2 ) ) ] )
    bn_relu = 1*( conv_max >= c_vec )
    return bn_relu

def dense_computation( inputs, weights, c_vec = None ):
    dense_res = np.matmul( inputs, weights )
    if c_vec is not None:
        return 1*( dense_res >= c_vec )
    return dense_res

def get_conv_filter( ops, lyr_idx ):
    conv_op = [ op for op in ops if "conv_filter" in op.name and op.type == "VariableV2" and "lyr" + str(lyr_idx) in op.name ][0]
    return conv_op.outputs[0]

def get_dense_mat( ops, lyr_idx ):
    conv_op = [ op for op in ops if "dense_" in op.name and op.type == "VariableV2" and "dense_" + str(lyr_idx) in op.name and "quant" in op.name ][0]
    return conv_op.outputs[0]

def apply_bn( x, ops, lyr_name ):
    bn_ops = [ op for op in ops if "batch_normalization" in op.name and op.type == "VariableV2" and lyr_name in op.name and "Adam" not in op.name and "quant" in op.name ]
    gamma = [ op for op in bn_ops if "gamma" in op.name ][0].outputs[0]
    beta = [ op for op in bn_ops if "beta" in op.name ][0].outputs[0]
    mean = [ op for op in bn_ops if "moving_mean" in op.name ][0].outputs[0]
    var = [ op for op in bn_ops if "moving_var" in op.name ][0].outputs[0]
    return tf.nn.batch_normalization( x,
                                      mean,
                                      var,
                                      beta,
                                      gamma,
                                      0.001 )

def rd_file( fname ):
    f = open( fname )
    rdr = csv.reader( f )
    res = np.array( [ [ int(x) for x in y ] for y in rdr ] )
    f.close()
    return res

def rd_file_fp( fname ):
    f = open( fname )
    rdr = csv.reader( f )
    res = np.array( [ [ float(x) for x in y ] for y in rdr ] )
    f.close()
    return res

def wr_file( data, fname ):
    f = open( fname, "w" )
    wrt = csv.writer( f )
    for x in data:
        wrt.writerow( x )
    f.close()

def load_conv2_from_csv():
    inputs = rd_file( "lyr1_res.csv" )
    exp_outputs = rd_file( "lyr2_res.csv" )
    weights = rd_file( "vgg_conv_lyr_2.csv" )
    c_vec = rd_file( "vgg_c_vec_lyr_2.csv" )
    return inputs, exp_outputs, weights, c_vec

def compute_whole_network( test_data, test_label, test_snr, bits_prec = 6 ):
    test_data = np.reshape( test_data, [ 1024, 2 ] )
    mean = np.mean( test_data, axis = 0 )
    test_data = test_data - mean
    test_data_quant = np.round( test_data*( 1 << bits_prec ) ).astype( int )
    lyr1 = rd_file( "vgg_conv_lyr_1.csv" )
    c_vec = rd_file_fp( "vgg_c_vec_lyr_1.csv" )
    c_vec_quant = np.ceil( c_vec*(1 << bits_prec ) ).astype( int )
    cnn = conv_sum_computation( test_data_quant, lyr1, c_vec_quant )
    for i in range( 2, 8 ):
        weights = rd_file( "vgg_conv_lyr_" + str(i) + ".csv" )
        c_vec = rd_file( "vgg_c_vec_lyr_" + str(i) + ".csv" )
        cnn = conv_sum_computation( cnn, weights, c_vec )
    # cnn = np.reshape( cnn, [ 1024 ] )
    cnn = cnn.flatten()
    for i in range( 1, 3 ):
        weights = rd_file( "vgg_dense_" + str(i) + ".csv" )
        c_vec = rd_file( "vgg_c_vec_dense_" + str(i) + ".csv" )
        cnn = dense_computation( cnn, weights, c_vec = c_vec )
    weights = rd_file_fp( "vgg_dense_3.csv" )
    weights_quant = np.round( weights*( 1 << ( bits_prec - 3 ) ) ).astype( int )
    bias = weights_quant[0,:]
    weights = weights_quant[1:,:]
    pred = dense_computation( cnn, weights ) + bias
    pred = np.reshape( pred, [24] )
    return np.argmax( pred ) == np.argmax( test_label )

def test_idx( idx, dset, bits_prec = 6 ):
    test_data = dset["X"][idx]
    test_label = dset["Y"][idx]
    test_snr = dset["Z"][idx]
    print( "class = " + str(np.argmax( test_label )) + ", snr = " + str( test_snr ) )
    return compute_whole_network( test_data, test_label, test_snr, bits_prec = bits_prec )

'''
dset = h5py.File( "/opt/datasets/deepsig/2018.01/GOLD_XYZ_OSC.0001_1024.hdf5" )
for i in range( 24 ):
  classification = 23 - i
  idx = 0
  try:
    for j in range( 4096 ):
      idx = -( i*4096*26 + j + 1 )
      if test_idx( idx, dset ):
        samples[classification] = ( dset["X"][idx], dset["Y"][idx], dset["Z"][idx] )
        break
  except KeyboardInterrupt:
    samples[classification] = ( dset["X"][idx], dset["Y"][idx], dset["Z"][idx] )
'''

def parse_example( ex ):
    ftrs = {
        "signal" : tf.FixedLenFeature( shape = [2048 ], dtype = tf.float32 ),
        "label" : tf.FixedLenFeature( shape = [ 1 ], dtype = tf.string ),
        "snr" : tf.FixedLenFeature( shape = [ 1 ], dtype = tf.int64 )
    }
    parsed_ex = tf.parse_single_example( ex, ftrs )
    signal = tf.transpose( tf.reshape( parsed_ex["signal"], ( 2, 1024 ) ) )
    label_char = tf.substr( parsed_ex["label"], 0, 1 )
    label = tf.decode_raw( label_char, out_type=tf.uint8)
    label = tf.reshape( label, [] )
    snr = tf.reshape( parsed_ex["snr"], [] )
    return signal, tf.cast( label, tf.int32 ), snr

def benchmark_train_set( snr, bits_prec = 6 ):
    fname = "/opt/datasets/deepsig/modulation_classification_test_snr_" + str(snr) + ".rcrd"
    dset = tf.data.TFRecordDataset( [ fname ] )
    dset = dset.map( parse_example )
    iterator = dset.make_one_shot_iterator()
    test_data_tf, test_label_tf, test_snr_tf = iterator.get_next()
    sess = tf.Session()
    total_cnt = 0
    total_correct = 0
    try:
        for i in tqdm.tqdm( range( 410*24 ) ) :
            test_data, test_label, test_snr = sess.run( [ test_data_tf, test_label_tf, test_snr_tf ] )
            tmp = compute_whole_network( test_data, test_label, test_snr, bits_prec = bits_prec )
            total_cnt += 1
            if tmp:
                total_correct += 1
    except tf.errors.OutOfRangeError:
        pass
    print( "accuracy = " +  str(total_correct/total_cnt) )
    return total_correct / total_cnt

# should pass inputs through conv2 in tensorflow
# save outputs to verify that it matches

def load_grph( prefix ):
    grph = tf.train.import_meta_graph( prefix + "/vgg_test.meta" )
    init_op = tf.global_variables_initializer()
    sess = tf.Session() 
    sess.run( init_op )
    grph.restore( sess, prefix + "/vgg_test" )
    cnn = tf.get_default_graph()
    ops = cnn.get_operations()
    return ops, sess

def run_tf_verify( prefix, test_data, test_label, test_snr ):
    ops, sess = load_grph( prefix )
    # start tensorflow cnn
    x_in = tf.placeholder( tf.float32, [ 1, 1024, 2 ] )
    mean, var = tf.nn.moments(x_in, axes=[1])
    mean = tf.expand_dims( mean, 1 )
    mean = tf.tile( mean, [ 1, x_in.get_shape()[1], 1 ] )
    x = ( x_in - mean )
    # start layer 1
    conv_filter = get_conv_filter( ops, 1 )
    conv_filter = q.trinarize( conv_filter, nu = 0.7 )
    cnn = tf.nn.conv1d( x, conv_filter, 1, padding = "SAME" )
    cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
    cnn = apply_bn( cnn, ops, "lyr1" )
    cnn = q.shaped_relu( cnn )
    # start layer 2
    for i in range( 2, 8 ):
        conv_filter = get_conv_filter( ops, i )
        conv_filter = q.trinarize( conv_filter, nu = 1.0 )
        cnn = tf.nn.conv1d( cnn, conv_filter, 1, padding = "SAME" )
        cnn = tf.layers.max_pooling1d( cnn, 2, 2 )
        cnn = apply_bn( cnn, ops, "lyr" + str(i) )
        cnn = q.shaped_relu( cnn )
    cnn = tf.layers.flatten( cnn )
    dense_1 = q.trinarize( get_dense_mat( ops, 8 ), nu = 1.4 )
    dense_2 = q.trinarize( get_dense_mat( ops, 9 ), nu = 1.4 )
    dense_3 = get_dense_mat( ops, 3 )
    cnn = tf.matmul( cnn, dense_1 )
    cnn = apply_bn( cnn, ops, "dense_1" )
    cnn = q.shaped_relu( cnn )
    cnn = tf.matmul( cnn, dense_2 )
    cnn = apply_bn( cnn, ops, "dense_2" )
    cnn = q.shaped_relu( cnn )
    cnn = tf.matmul( cnn, dense_3 )
    bias = [ op for op in ops if "quant/dense_3/dense/bias" in op.name and op.type == "VariableV2" ][0].outputs[0]
    cnn = cnn + bias
    pred = sess.run( [ cnn ], feed_dict = { x_in : test_data } )
    flat_vec = compute_whole_network( test_data, None, None, 15 )
    pred = np.reshape(  pred, [24] )
    is_match = np.sum( np.abs( pred - flat_vec ) ) < 0.01
    return np.argmax( test_label ) == np.argmax( pred )

if __name__ == "__main__":
    # dset = h5py.File( "/opt/datasets/deepsig/2018.01/GOLD_XYZ_OSC.0001_1024.hdf5" )
    os.environ["CUDA_VISIBLE_DEVICES"]=""
    accrs = []
    for snr in range( 30, 31, 2 ):
        print( "run snr = " + str(snr) )
        accr = benchmark_train_set( snr, bits_prec = 6 )
        accrs += [ accr ]
        print( accrs )

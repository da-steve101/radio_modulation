#! /usr/bin/python3

import sys
import numpy as np
import tensorflow as tf
import random
import argparse
import os

modulations = ["bpsk", "M8psk", "qam16", "qpsk" ]

def get_example( x, y, snr ):
    label = int( y ).to_bytes( 1, byteorder='big')
    ftrs = {
        "signal" : tf.train.Feature( float_list = tf.train.FloatList(value = x ) ),
        "label" : tf.train.Feature( bytes_list = tf.train.BytesList(value = [ label ] ) ),
        "snr" : tf.train.Feature( int64_list = tf.train.Int64List(value = [ snr ] ) )
    }
    example = tf.train.Example(features=tf.train.Features(feature=ftrs))
    return example.SerializeToString()

def partition_dataset( d_len ):
    train = round( d_len * 0.9 )
    test = d_len - train
    ary = np.array( ( [ True ] * train ) + ( [ False ] * test ) )
    np.random.shuffle( ary )
    is_train = ary
    is_test = np.array( [ not x for x in ary ] )
    return is_train, is_test

def get_chunk( mod, idx, sig_len, scaling_div ):
    chunk = np.load("/opt/datasets/rfsoc_iq/dataset_50k_variation/%s_data/chunk_%d.npy" % ( mod, idx ))
    i_data = np.reshape( chunk[0::2], [-1, 4095 ] )/scaling_div
    q_data = np.reshape( chunk[1::2], [-1, 4095 ] )/scaling_div
    starts = np.random.randint( 0, i_data.shape[1] - sig_len, [i_data.shape[0]] )
    i_data_clipped = np.array([ i_data[i][s:(s+sig_len)] for i, s in enumerate( starts ) ])
    q_data_clipped = np.array([ q_data[i][s:(s+sig_len)] for i, s in enumerate( starts ) ])
    return ( i_data_clipped, q_data_clipped )

def load_modulation( mod, num_modulations = 50, sig_len = 1024, prec = 10 ):
    i_ex = None
    q_ex = None
    for i in range( num_modulations ):
        i_c, q_c = get_chunk( mod, i, sig_len, 1 << prec )
        if i_ex is None:
            i_ex = i_c
            q_ex = q_c
        else:
            i_ex = np.concatenate( [ i_ex, i_c ] )
            q_ex = np.concatenate( [ q_ex, q_c ] )
    is_train, is_test = partition_dataset( i_ex.shape[0] )
    return i_ex[is_train,:], q_ex[is_train,:], i_ex[is_test,:], q_ex[is_test,:]

if __name__ == "__main__":
    i_train = None
    os.environ["CUDA_VISABLE_DEVICES"] = ""
    for j, mod in enumerate(modulations):
        i_tr, q_tr, i_te, q_te = load_modulation( mod, 500 )
        if i_train is None:
            i_train = i_tr
            q_train = q_tr
            i_test = i_te
            q_test = q_te
            train_labels = np.array([j]*i_train.shape[0])
            test_labels = np.array([j]*i_test.shape[0])
        else:
            i_train = np.concatenate( [ i_train, i_tr ] )
            q_train = np.concatenate( [ q_train, q_tr ] )
            i_test = np.concatenate( [ i_test, i_te ] )
            q_test = np.concatenate( [ q_test, q_te ] )
            train_labels = np.concatenate( [ train_labels, np.array([j]*i_train.shape[0]) ] )
            test_labels = np.concatenate( [ test_labels, np.array([j]*i_test.shape[0]) ] )
    train_idxs = np.array( list( range( i_train.shape[0] ) ) )
    np.random.shuffle( train_idxs )
    i_train = i_train[train_idxs,:]
    q_train = q_train[train_idxs,:]
    train_labels = train_labels[train_idxs]
    wrt_train = tf.python_io.TFRecordWriter( "/opt/datasets/rfsoc_iq/train.rcrd" )
    for i, q, y in zip( i_train, q_train, train_labels ):
        x = np.concatenate( [ i, q ] )
        ex = get_example( x, y, 30 )
        wrt_train.write( ex )
    wrt_train.close()
    wrt_test = tf.python_io.TFRecordWriter( "/opt/datasets/rfsoc_iq/test.rcrd" )
    for i, q, y in zip( i_test, q_test, test_labels ):
        x = np.concatenate( [ i, q ] )
        ex = get_example( x, y, 30 )
        wrt_test.write( ex )
    wrt_test.close()

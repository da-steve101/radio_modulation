#! /usr/bin/python3

import h5py
import sys
import numpy as np
import tensorflow as tf
import random

RCRD_PREFIX = "modulation_classification_test_snr_"
RCRD_SUFFIX = ".rcrd"

def get_example( x, y, snr ):
    label = int( np.argmax( y ) ).to_bytes( 1, byteorder='big')
    signal = np.reshape( np.transpose( x ), [ 2048 ] ) # flatten the signal to 1024xI followed by 1024xQ
    ftrs = {
        "signal" : tf.train.Feature( float_list = tf.train.FloatList(value = signal ) ),
        "label" : tf.train.Feature( bytes_list = tf.train.BytesList(value = [ label ] ) ),
        "snr" : tf.train.Feature( int64_list = tf.train.Int64List(value = [ snr ] ) )
    }
    example = tf.train.Example(features=tf.train.Features(feature=ftrs))
    return example.SerializeToString()

def make_wrt( snr ):
    return tf.python_io.TFRecordWriter( RCRD_PREFIX + str( snr ) + RCRD_SUFFIX )

def add_to_rcrd( ex, wrts, snr ):
    if snr not in wrts:
        wrts[snr] = make_wrt( snr )
    wrt = wrts[ snr ]
    wrt.write( ex )
    return wrts

def partition_dataset():
    ary = np.array( ( [ True ] * 3686 ) + ( [ False ] * 410 ) )
    np.random.shuffle( ary )
    return ary

if __name__ == "__main__":
    f = h5py.File( sys.argv[1], "r" )
    train_ex = []
    partition = partition_dataset()
    p_idx = 0
    test_wrts = {}
    for x, y, snr in zip( f["X"], f["Y"], f["Z"] ):
        snr = int( snr )
        ex = get_example( x, y, snr )
        if partition[p_idx]:
            train_ex += [ ex ]
        else:
            test_wrts = add_to_rcrd( ex, test_wrts, snr )
        p_idx = ( p_idx + 1 ) % 4096
        if p_idx == 0:
            partition = partition_dataset()
    for snr in test_wrts:
        test_wrts[snr].close()
    np.random.shuffle( train_ex )
    train_wrt = tf.python_io.TFRecordWriter( "modulation_classification_train.rcrd" )
    for ex in train_ex:
        train_wrt.write( ex )
    train_wrt.close()

#! /usr/bin/python3

import h5py
import sys
import numpy as np
import tensorflow as tf
import random
import argparse
import os

def get_example( x, y, snr, rcrd_prefix, rcrd_suffix ):
    label = int( np.argmax( y ) ).to_bytes( 1, byteorder='big')
    signal = np.reshape( np.transpose( x ), [ 2048 ] ) # flatten the signal to 1024xI followed by 1024xQ
    ftrs = {
        "signal" : tf.train.Feature( float_list = tf.train.FloatList(value = signal ) ),
        "label" : tf.train.Feature( bytes_list = tf.train.BytesList(value = [ label ] ) ),
        "snr" : tf.train.Feature( int64_list = tf.train.Int64List(value = [ snr ] ) )
    }
    example = tf.train.Example(features=tf.train.Features(feature=ftrs))
    return example.SerializeToString()

def make_wrt( snr, rcrd_prefix, rcrd_suffix ):
    return tf.python_io.TFRecordWriter( rcrd_prefix + str( snr ) + rcrd_suffix )

def add_to_rcrd( ex, wrts, snr, rcrd_prefix, rcrd_suffix ):
    if snr not in wrts:
        wrts[snr] = make_wrt( snr, rcrd_prefix, rcrd_suffix )
    wrt = wrts[ snr ]
    wrt.write( ex )
    return wrts

def partition_dataset():
    ary = np.array( ( [ True ] * 3686 ) + ( [ False ] * 410 ) )
    np.random.shuffle( ary )
    return ary

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--dataset_file", type = str, required = True,
                         help="The filename of the dataset")
    parser.add_argument( "--rcrd_prefix", type = str, default = "modulation_classification",
                         help="The filename prefix to use on the output")
    parser.add_argument( "--rcrd_suffix", type = str, default = ".rcrd",
                         help="The filename suffix to use on the output")
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    f = h5py.File( args.dataset_file, "r" )
    dirname = os.path.dirname( args.dataset_file )
    train_ex = []
    partition = partition_dataset()
    p_idx = 0
    test_wrts = {}
    prefix = dirname + "/" + args.rcrd_prefix
    for x, y, snr in zip( f["X"], f["Y"], f["Z"] ):
        snr = int( snr )
        ex = get_example( x, y, snr, prefix + "_test_snr_", args.rcrd_suffix )
        if partition[p_idx]:
            train_ex += [ ex ]
        else:
            test_wrts = add_to_rcrd( ex, test_wrts, snr, args.rcrd_prefix, args.rcrd_suffix )
        p_idx = ( p_idx + 1 ) % 4096
        if p_idx == 0:
            partition = partition_dataset()
    for snr in test_wrts:
        test_wrts[snr].close()
    np.random.shuffle( train_ex )
    train_wrt = tf.python_io.TFRecordWriter( prefix + "_train" + args.rcrd_suffix )
    for ex in train_ex:
        train_wrt.write( ex )
    train_wrt.close()

#! /usr/bin/python3

import tensorflow as tf
import numpy as np
import csv
import tqdm
import sys
import pyvgg
import os
import argparse

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--test_pattern", type = str, default = "/opt/datasets/deepsig/modulation_classification_test_snr_%d.rcrd",
                         help="The file location pattern of the test set")
    parser.add_argument( "--file_out", type = str, required = True,
                         help="The filename to write the classifications to")
    parser.add_argument( "--niter", type = int, default = 410*24*26,
                         help="Number of iterations to run on the rcrd")
    parser.add_argument( "--no_mean", action = 'store_true',
                         help="Do not remove the mean from the signal")
    return parser.parse_args()

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

def load_file( fname ):
    dset = tf.data.TFRecordDataset( fname )
    dset = dset.map( parse_example )
    iterator = dset.make_one_shot_iterator()
    return iterator.get_next()

def test_vec( x ):
    x = np.round( np.reshape( x, [-1] )*( 1 << 6 ) ).astype( int ).tolist()
    return pyvgg.compute( x )

if __name__ == "__main__":
    test_ptn = args.test_pattern
    if "%d" in test_ptn:
        pattern_files = [ test_ptn % snr for snr in range( -20, 32, 2 ) ]
    else:
        pattern_files = [ test_ptn ]
    signal, label, snr = load_file( pattern_files )
    os.environ["CUDA_VISIBLE_DEVICES"] = ""
    with tf.Session() as sess:
        cntr_ary = {}
        correct_ary = {}
        f = open( args.file_out, "w" )
        wrt = csv.writer( f )
        try:
            iterator = tqdm.tqdm( range( args.niter ) )
            for i in iterator:
                img, y, z = sess.run( [ signal, label, snr ] )
                if not args.no_mean:
                    mean = np.mean( img, axis=0)
                    img = ( img - mean )
                np_pred = test_vec( img )
                preds = np.argmax( np_pred )
                if z not in cntr_ary:
                    cntr_ary[z] = 0
                    correct_ary[z] = 0
                cntr_ary[z] += 1
                wrt.writerow( [ z, preds, y ] )
                if preds == y:
                    correct_ary[z] += 1
        finally:
            f.close()
            for z in range( -20, 32, 2 ):
                if z in cntr_ary:
                    print( "accr[" + str(z) + "] = " + str( 100*correct_ary[z]/cntr_ary[z] ) )
    

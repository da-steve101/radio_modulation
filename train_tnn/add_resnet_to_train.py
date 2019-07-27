#! /usr/bin/python3

import tensorflow as tf
import resnet
import os
import argparse
import numpy as np
import csv

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

def get_example( signal, label, snr, rcrd_prefix, rcrd_suffix, teacher ):
    label = int( label ).to_bytes( 1, byteorder='big')
    signal = np.reshape( np.transpose( signal ), [ 2048 ] ) # flatten the signal to 1024xI followed by 1024xQ
    teacher = np.reshape( teacher, [24] )
    ftrs = {
        "signal" : tf.train.Feature( float_list = tf.train.FloatList(value = signal ) ),
        "label" : tf.train.Feature( bytes_list = tf.train.BytesList(value = [ label ] ) ),
        "snr" : tf.train.Feature( int64_list = tf.train.Int64List(value = [ snr ] ) ),
        "teacher" : tf.train.Feature( float_list = tf.train.FloatList(value = teacher ) )
    }
    example = tf.train.Example(features=tf.train.Features(feature=ftrs))
    return example.SerializeToString()

def get_resnet( signal, teacher_name, sess ):
    with tf.variable_scope("teacher"):
        resnet_pred = resnet.get_net( signal, training = False )
    resnet_saver = tf.train.Saver()
    resnet_saver.restore(sess, teacher_name )
    return resnet_pred

def batcher( input_file, batch_size ):
    dset = tf.data.TFRecordDataset( [ input_file ] )
    dset = dset.map( parse_example )
    dset = dset.prefetch( buffer_size = 16*batch_size )
    dset = dset.batch( batch_size )
    iterator = dset.make_one_shot_iterator()
    return iterator

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--dataset_rcrd", type = str, required = True,
                         help="The train dataset to add teacher to")
    parser.add_argument( "--rcrd_prefix", type = str, default = "modulation_classification",
                         help="The filename prefix to use on the output")
    parser.add_argument( "--rcrd_suffix", type = str, default = ".rcrd",
                         help="The filename suffix to use on the output")
    parser.add_argument( "--resnet_model", type = str, required = True,
                         help="Optional teacher model to put in rcrd")
    parser.add_argument( "--gpus", type=str,
                         help = "GPUs to use" )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    if args.gpus is not None:
        os.environ["CUDA_VISIBLE_DEVICES"]=args.gpus
    tf.logging.set_verbosity( tf.logging.INFO )
    dirname = os.path.dirname( args.dataset_rcrd )
    iterator = batcher( args.dataset_rcrd, 128 )
    signal, label, snr = iterator.get_next()
    sess = tf.Session()
    teacher = get_resnet( signal, args.resnet_model, sess )
    train_wrt = tf.python_io.TFRecordWriter( dirname + "/" + args.rcrd_prefix + "_resnet_train" + args.rcrd_suffix )
    f_out = open( "tmp.csv", "w" )
    wrt = csv.writer( f_out )
    try:
        for i in range(100):
            s, l, n, t = sess.run( [signal, label, snr, teacher] )
            for s_ex, l_ex, n_ex, t_ex in zip(s, l, n, t):
                ex = get_example( s_ex, l_ex, n_ex, args.rcrd_prefix, args.rcrd_suffix, t_ex )
                t_class = [ np.argmax( t_ex ) ]
                wrt.writerow( [l_ex] + t_class + [n_ex] + t_ex.tolist() )
                train_wrt.write( ex )
    except tf.errors.OutOfRangeError:
        tf.logging.log( tf.logging.INFO, "Dataset is finished" )
    finally:
        train_wrt.close()
        f_out.close()

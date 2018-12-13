#! /usr/bin/python3

import tensorflow as tf
import csv
import argparse
import resnet
from tqdm import tqdm

NO_TEST_BATCHES = 308 # 410*24 / 32 = 307.5

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

def filter_snr( sig, label, snr ):
    return tf.math.greater( snr, 10 )

def batcher( input_file, batch_size, training = True ):
    dset = tf.data.TFRecordDataset( [ input_file ] )
    dset = dset.map( parse_example )
    if training:
        dset = dset.shuffle( 8*batch_size )
        dset = dset.repeat()
        # dset = dset.filter( filter_snr )
    dset = dset.batch( batch_size )
    if training:
        iterator = dset.make_initializable_iterator()
    else:
        iterator = dset.make_one_shot_iterator()
    return iterator

def get_optimizer( pred, label, learning_rate ):
    err = tf.nn.sparse_softmax_cross_entropy_with_logits(
        labels = label,
        logits = pred,
        name = "softmax_err_func"
    )
    tf.summary.scalar( "train_err", tf.reduce_sum( err ) )
    lr = tf.train.exponential_decay(
        learning_rate,
        tf.train.get_or_create_global_step(),
        100000,
        0.96
    )
    pred = tf.math.argmax( pred, axis = 1 )
    correct = tf.cast( tf.math.equal( pred, tf.cast( label, tf.int64 ) ), tf.float32 )
    accr = tf.reduce_mean( correct )
    tf.summary.histogram( "preds", pred )
    tf.summary.scalar( "learning_rate", tf.reduce_sum( lr ) )
    tf.summary.scalar( "accuracy", accr )
    update_ops = tf.get_collection(tf.GraphKeys.UPDATE_OPS)
    with tf.control_dependencies(update_ops):
        opt = tf.train.AdamOptimizer( lr )
    return opt.minimize( err, global_step = tf.train.get_or_create_global_step() )

def test_loop( snr, pred, label, fname, no_loops ):
    pred = tf.math.argmax( pred, axis = 1 )
    if fname is None:
        fname = "test_pred.csv"
    if no_loops is None:
        no_loops = NO_TEST_BATCHES
    f_out = open( fname, "w" )
    wrt = csv.writer( f_out )
    for i in tqdm(range( no_loops )):
        snr_out, pred_out, label_out = sess.run( [ snr, pred, label ] )
        for s, p, l in zip( snr_out, pred_out, label_out ):
            wrt.writerow( [ s, p, l ] )
    f_out.close()

def train_loop( opt, summary_writer, no_steps = 100000 ):
    summaries = tf.summary.merge_all()
    curr_step = tf.train.get_global_step()
    step = sess.run( curr_step )
    tf.logging.log( tf.logging.INFO, "Starting train loop at step " + str(step) )
    try:
        for i in tqdm( range( step, no_steps ) ):
            step, _, smry = sess.run( [ curr_step, opt, summaries ] )
            if step % 20 == 0:
                summary_writer.add_summary( smry, step )
    except KeyboardInterrupt:
        tf.logging.log( tf.logging.INFO, "Ctrl-c recieved, training stopped" )
    return

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--model_name", type = str, required = True,
                         help="The model name to train or test")
    parser.add_argument( "--dataset", type = str, required = True,
                         help = "The dataset to train or test on" )
    parser.add_argument( "--steps", type = int,
                         help = "The number of training steps" )
    parser.add_argument( "--test", action = "store_true",
                         help = "Test the model on this dataset" )
    parser.add_argument( "--test_output", type = str,
                         help = "Filename to save the output in csv format ( pred, label )" )
    parser.add_argument( "--test_batches", type = int, default = NO_TEST_BATCHES,
                         help = "Number of batches to run on" )
    parser.add_argument( "--batch_size", type=int, default = 32,
                         help = "Batch size to use" )
    parser.add_argument( "--learning_rate", type=float, default = 0.1,
                         help = "The learning rate to use when training" )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    iterator = batcher( args.dataset, args.batch_size, not args.test )
    tf.logging.set_verbosity( tf.logging.INFO )
    signal, label, snr = iterator.get_next()
    pred = resnet.get_net( signal, training = not args.test )
    if not args.test:
        opt = get_optimizer( pred, label, args.learning_rate )
    init_op = tf.global_variables_initializer()
    saver = tf.train.Saver()
    with tf.Session() as sess:
        try:
            if not args.test:
                smry_wrt = tf.summary.FileWriter( args.model_name + "_logs", sess.graph, session = sess )
                sess.run( iterator.initializer )    
            sess.run( init_op )
            # load the model if possible
            if tf.train.checkpoint_exists( args.model_name ):
                tf.logging.log( tf.logging.INFO, "Loading model ... " )
                saver.restore(sess, args.model_name )
            if args.test:
                test_loop( snr, pred, label, args.test_output, args.test_batches )
            else:
                train_loop( opt, smry_wrt, no_steps = args.steps )
                tf.logging.log( tf.logging.INFO, "Saving model ... " )
                saver.save( sess, args.model_name )
        except tf.errors.OutOfRangeError:
            tf.logging.log( tf.logging.INFO, "Dataset is finished" )
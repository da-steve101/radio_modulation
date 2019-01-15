#! /usr/bin/python3

import tensorflow as tf
import csv
import argparse
import resnet
import Vgg10
from tqdm import tqdm

NO_TEST_BATCHES = 154 # 410*24 / 64
NO_TEST_EXAMPLES = NO_TEST_BATCHES * 64

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
    return tf.math.greater( snr, -12 )

def batcher( input_file, batch_size, training = True ):
    dset = tf.data.TFRecordDataset( [ input_file ] )
    dset = dset.map( parse_example )
    if training:
        dset = dset.shuffle( 8*batch_size )
        dset = dset.repeat()
        dset = dset.filter( filter_snr )
    dset = dset.batch( batch_size )
    dset = dset.prefetch( buffer_size = 16*batch_size)
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
    opt = tf.train.AdamOptimizer( lr )
    with tf.control_dependencies(update_ops):
        return opt.minimize( err, global_step = tf.train.get_or_create_global_step() )

def test_loop( snr, pred, label, training, fname, no_loops ):
    pred = tf.math.argmax( pred, axis = 1 )
    if fname is None:
        fname = "test_pred.csv"
    if no_loops is None:
        no_loops = NO_TEST_BATCHES
    f_out = open( fname, "w" )
    wrt = csv.writer( f_out )
    corr_cnt = 0
    total_cnt = 0
    for i in tqdm(range( no_loops )):
        snr_out, pred_out, label_out = sess.run( [ snr, pred, label ], feed_dict = { training : False } )
        for s, p, l in zip( snr_out, pred_out, label_out ):
            if p == l:
                corr_cnt += 1
            wrt.writerow( [ s, p, l ] )
            total_cnt += 1
    tf.logging.log( tf.logging.INFO, "Test done, accr = : " + str( corr_cnt / total_cnt ) )
    f_out.close()

def train_loop( opt, summary_writer, num_correct, training, no_steps = 100000, do_val = True ):
    summaries = tf.summary.merge_all()
    curr_step = tf.train.get_global_step()
    step = sess.run( curr_step )
    tf.logging.log( tf.logging.INFO, "Starting train loop at step " + str(step) )
    try:
        for i in range( step, no_steps ):
            step, _, smry = sess.run( [ curr_step, opt, summaries ], feed_dict = { training : True } )
            if step % 20 == 0:
                summary_writer.add_summary( smry, step )
            if step % 10000 == 0 and do_val:
                cnt = 0
                for i in range( NO_TEST_BATCHES ):
                    corr = sess.run( num_correct, feed_dict = { training : False } )
                    cnt += corr
                tf.logging.log( tf.logging.INFO, "Step: " + str( step ) + " - Test batch complete: accr = " + str( cnt / NO_TEST_EXAMPLES )  )
    except KeyboardInterrupt:
        tf.logging.log( tf.logging.INFO, "Ctrl-c recieved, training stopped" )
    return

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--model_name", type = str, required = True,
                         help="The model name to train or test")
    parser.add_argument( "--dataset", type = str, required = True,
                         help = "The dataset to train or test on" )
    parser.add_argument( "--val_dataset", type = str,
                         help = "The dataset to validate on when training" )
    parser.add_argument( "--steps", type = int,
                         help = "The number of training steps" )
    parser.add_argument( "--test", action = "store_true",
                         help = "Test the model on this dataset" )
    parser.add_argument( "--use_VGG", action = "store_true",
                         help = "Use Vgg instead of resnet" )
    parser.add_argument( "--test_output", type = str,
                         help = "Filename to save the output in csv format ( pred, label )" )
    parser.add_argument( "--test_batches", type = int, default = NO_TEST_BATCHES,
                         help = "Number of batches to run on" )
    parser.add_argument( "--batch_size", type=int, default = 32,
                         help = "Batch size to use" )
    parser.add_argument( "--learning_rate", type=float, default = 0.001,
                         help = "The learning rate to use when training" )
    parser.add_argument( "--use_SELU", action="store_true",
                         help = "Use Self-Normalizing networks" )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    iterator = batcher( args.dataset, args.batch_size, not args.test )
    tf.logging.set_verbosity( tf.logging.INFO )
    training = tf.placeholder( tf.bool, name = "training" )
    if not args.test:
        train_signal, train_label, train_snr = iterator.get_next()
        do_val = True
        if args.val_dataset is not None:
            test_iterator = batcher( args.val_dataset, args.batch_size, not args.test )
            test_signal, test_label, test_snr = test_iterator.get_next()
            signal = tf.where( training, train_signal, test_signal )
            label = tf.where( training, train_label, test_label )
            snr = tf.where( training, train_snr, test_snr )
        else:
            signal, label, snr = ( train_signal, train_label, train_snr )
            do_val = False
    else:
        signal, label, snr = iterator.get_next()
    with tf.device('/device:GPU:0'):
        if args.use_VGG:
            pred = Vgg10.get_net( signal, training = training, use_SELU = args.use_SELU )
        else:
            pred = resnet.get_net( signal, training = training, use_SELU = args.use_SELU )
    if not args.test:
        pred_label = tf.cast( tf.math.argmax( pred, axis = 1 ), tf.int32 )
        num_correct = tf.reduce_sum( tf.cast( tf.math.equal( pred_label, label ), tf.float32 ) )
        num_correct = tf.reshape( num_correct, [] )
        opt = get_optimizer( pred, label, args.learning_rate )
    init_op = tf.global_variables_initializer()
    saver = tf.train.Saver()
    with tf.Session() as sess:
        try:
            if not args.test:
                smry_wrt = tf.summary.FileWriter( args.model_name + "_logs", sess.graph, session = sess )
                sess.run( iterator.initializer )
                sess.run( test_iterator.initializer )
            sess.run( init_op )
            # load the model if possible
            if tf.train.checkpoint_exists( args.model_name ):
                tf.logging.log( tf.logging.INFO, "Loading model ... " )
                saver.restore(sess, args.model_name )
            if args.test:
                test_loop( snr, pred, label, training, args.test_output, args.test_batches )
            else:
                train_loop( opt, smry_wrt, num_correct, training, no_steps = args.steps, do_val = do_val )
                tf.logging.log( tf.logging.INFO, "Saving model ... " )
                saver.save( sess, args.model_name )
        except tf.errors.OutOfRangeError:
            tf.logging.log( tf.logging.INFO, "Dataset is finished" )

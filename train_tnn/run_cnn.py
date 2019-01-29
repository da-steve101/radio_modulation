#! /usr/bin/python3

import tensorflow as tf
import csv
import argparse
import resnet
import Vgg10
from tqdm import tqdm
import os
import quantization as q

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
    '''
    lr = tf.train.exponential_decay(
        learning_rate,
        tf.train.get_or_create_global_step(),
        100000,
        0.96
    )
    '''
    lr = learning_rate
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
    parser.add_argument( "--quantize_w", type=int,
                         help = "Quantize Weights" )
    parser.add_argument( "--quantize_act", type=int,
                         help = "Quantize Activations" )
    parser.add_argument( "--learning_rate", type=float, default = 0.001,
                         help = "The learning rate to use when training" )
    parser.add_argument( "--use_SELU", action="store_true",
                         help = "Use Self-Normalizing networks" )
    return parser.parse_args()

def weights_diff_err( quantize_w, scaling = 0.1 ):
    coll = tf.get_collection( "Weights" )
    total_full = 0
    total_quant = 0
    for i in [ str(i) for i in range( 1, 8 ) ]:
        cnn_weights = [ w for w in coll if i in w.name ]
        if "full" in cnn_weights[0].name:
            full_w = cnn_weights[0]
            quant_w = cnn_weights[1]
        else:
            quant_w = cnn_weights[0]
            full_w = cnn_weights[1]
        '''
        if quantize_w:
            full_w = q.quantize_weights( full_w, quantize_w )
        '''
        total_full += tf.reduce_sum( tf.square( full_w - tf.stop_gradient( quant_w ) ) )
        total_quant += tf.reduce_sum( tf.square( tf.stop_gradient( full_w ) - quant_w ) )
    errA = total_full*scaling/14
    errB = total_quant*scaling/14
    return errA, errB

def guided_training_opt( full_prec_pred, quant_pred, label, learning_rate, quantize_w ):
    full_err = tf.nn.sparse_softmax_cross_entropy_with_logits(
        labels = label,
        logits = full_prec_pred,
        name = "softmax_err_func_f"
    )
    tf.summary.scalar( "train_err_full", tf.reduce_sum( full_err ) )
    quant_err = tf.nn.sparse_softmax_cross_entropy_with_logits(
        labels = label,
        logits = quant_pred,
        name = "softmax_err_func_q"
    )
    tf.summary.scalar( "train_err_quant", tf.reduce_sum( quant_err ) )
    weights_errA, weights_errB = weights_diff_err( quantize_w )
    lr = tf.train.exponential_decay(
        learning_rate,
        tf.train.get_or_create_global_step(),
        100000,
        0.96
    )
    # lr = learning_rate
    pred = tf.math.argmax( quant_pred, axis = 1 )
    correct = tf.cast( tf.math.equal( pred, tf.cast( label, tf.int64 ) ), tf.float32 )
    accr = tf.reduce_mean( correct )
    tf.summary.histogram( "preds", pred )
    tf.summary.scalar( "learning_rate", tf.reduce_sum( lr ) )
    tf.summary.scalar( "accuracy", accr )
    update_ops = tf.get_collection(tf.GraphKeys.UPDATE_OPS)
    tf.summary.scalar( "weights_errA", weights_errA )
    tf.summary.scalar( "weights_errB", weights_errB )
    tf.summary.scalar( "full_err", tf.reduce_mean( full_err ) )
    tf.summary.scalar( "quant_err", tf.reduce_mean( quant_err ) )
    err_A = full_err + weights_errA
    err_B = quant_err + weights_errB
    opt_A = tf.train.AdamOptimizer( lr )
    opt_B = tf.train.AdamOptimizer( lr )
    with tf.control_dependencies(update_ops):
        op_A = opt_A.minimize( err_A, global_step = tf.train.get_or_create_global_step() )
        op_B = opt_B.minimize( err_B, global_step = tf.train.get_or_create_global_step() )
    return op_A, op_B

def guided_train_loop( opt_A, opt_B, summary_writer, num_correct, training, no_steps = 100000, do_val = True ):
    summaries = tf.summary.merge_all()
    curr_step = tf.train.get_global_step()
    step = sess.run( curr_step )
    tf.logging.log( tf.logging.INFO, "Starting train loop at step " + str(step) )
    try:
        for i in range( step, no_steps ):
            step_A, _, smry_A = sess.run( [ curr_step, opt_A, summaries ], feed_dict = { training : True } )
            step, _, smry_B = sess.run( [ curr_step, opt_B, summaries ], feed_dict = { training : True } )
            if step_A % 40 == 0:
                summary_writer.add_summary( smry_B, step_A )
            if step_A % 20000 == 0 and do_val:
                cnt = 0
                for i in range( NO_TEST_BATCHES ):
                    corr = sess.run( num_correct, feed_dict = { training : False } )
                    cnt += corr
                tf.logging.log( tf.logging.INFO, "Step: " + str( step ) + " - Test batch complete: accr = " + str( cnt / NO_TEST_EXAMPLES )  )
    except KeyboardInterrupt:
        tf.logging.log( tf.logging.INFO, "Ctrl-c recieved, training stopped" )
    return
    
if __name__ == "__main__":
    args = get_args()
    iterator = batcher( args.dataset, args.batch_size, not args.test )
    os.environ["CUDA_VISIBLE_DEVICES"]="0"
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
            if args.quantize_w is None:
                quantize_w = False
            else:
                quantize_w = args.quantize_w
            if args.quantize_act is None:
                quantize_act = False
            else:
                quantize_act = args.quantize_act
            with tf.variable_scope( "full" ):
                full_prec_pred = Vgg10.get_net( signal, training = training, use_SELU = args.use_SELU )
            with tf.variable_scope( "quant" ):
                quant_pred = Vgg10.get_net( signal, training = training, use_SELU = args.use_SELU, quantize_w = quantize_w, quantize_act = quantize_act )
            pred = quant_pred
        else:
            pred = resnet.get_net( signal, training = training, use_SELU = args.use_SELU )
    if not args.test:
        pred_label = tf.cast( tf.math.argmax( pred, axis = 1 ), tf.int32 )
        num_correct = tf.reduce_sum( tf.cast( tf.math.equal( pred_label, label ), tf.float32 ) )
        num_correct = tf.reshape( num_correct, [] )
        if args.use_VGG:
            opt_f, opt_q = guided_training_opt( full_prec_pred, quant_pred, label, args.learning_rate, quantize_w )
        else:
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
                if args.use_VGG:
                    guided_train_loop( opt_f, opt_q, smry_wrt, num_correct, training, no_steps = args.steps, do_val = do_val )
                else:
                    train_loop( opt, smry_wrt, num_correct, training, no_steps = args.steps, do_val = do_val )
                tf.logging.log( tf.logging.INFO, "Saving model ... " )
                saver.save( sess, args.model_name )
        except tf.errors.OutOfRangeError:
            tf.logging.log( tf.logging.INFO, "Dataset is finished" )

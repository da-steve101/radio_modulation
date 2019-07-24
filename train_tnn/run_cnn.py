#! /usr/bin/python3

import tensorflow as tf
import csv
import argparse
import resnet
import Vgg10
from tqdm import tqdm
import os
import quantization as q

'''
Classes:
0) OOK,
1) 4ASK,
2) 8ASK,
3) BPSK,
4) QPSK,
5) 8PSK,
6) 16PSK,
7) 32PSK,
8) 16APSK,
9) 32APSK,
10) 64APSK,
11) 128APSK,
12) 16QAM,
13) 32QAM,
14) 64QAM,
15) 128QAM,
16) 256QAM,
17) AM-SSB-WC,
18) AM-SSB-SC,
19) AM-DSB-WC,
20) AM-DSB-SC,
21) FM,
22) GMSK,
23) OQPSK
'''

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
    return tf.math.greater( snr, 4 )

def batcher( input_file, batch_size, training = True ):
    dset = tf.data.TFRecordDataset( [ input_file ] )
    dset = dset.map( parse_example )
    dset = dset.prefetch( buffer_size = 16*batch_size)
    if training:
        dset = dset.filter( filter_snr )
        dset = dset.repeat()
        dset = dset.shuffle( 8*batch_size )
    dset = dset.batch( batch_size )
    if training:
        iterator = dset.make_initializable_iterator()
    else:
        iterator = dset.make_one_shot_iterator()
    return iterator

def get_optimizer( pred, label, learning_rate, resnet_pred = None ):
    err = tf.nn.sparse_softmax_cross_entropy_with_logits(
        labels = label,
        logits = pred,
        name = "softmax_err_func"
    )
    err = tf.reduce_sum( err )
    tf.summary.scalar( "train_err", err )
    if resnet_pred is not None:
        student_err = tf.sqrt( tf.nn.l2_loss( resnet_pred - pred ) )/5
        tf.summary.scalar( "student_err", student_err )
        err = student_err + err
    lr = tf.train.exponential_decay(
        learning_rate,
        tf.train.get_or_create_global_step(),
        100000,
        0.5
    )
    # lr = learning_rate
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

def print_conf_mat( preds, labels ):
    classes = ['32PSK', '16APSK', '32QAM', 'FM', 'GMSK',
               '32APSK', 'OQPSK', '8ASK', 'BPSK', '8PSK',
               'AM-SSB-SC', '4ASK', '16PSK', '64APSK', '128QAM',
               '128APSK', 'AM-DSB-SC', 'AM-SSB-WC', '64QAM', 'QPSK',
               '256QAM', 'AM-DSB-WC', 'OOK', '16QAM']
    print( "\t".join( [ "CM:" ] + classes ) )
    conf_mat = [ [0]*24 for x in range(24) ]
    for p, l in zip( preds, labels ):
        conf_mat[int(p)][int(l)] += 1
    for i, x in enumerate( conf_mat ):
        print( classes[i] + "\t" + ",\t".join( [ str(y) for y in x ]) )

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--model_name", type = str, required = True,
                         help="The model name to train or test")
    parser.add_argument( "--teacher_name", type = str,
                         help="The resnet teacher model to train with")
    parser.add_argument( "--dataset", type = str, required = True,
                         help = "The dataset to train or test on" )
    parser.add_argument( "--val_dataset", type = str,
                         help = "The dataset to validate on when training" )
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
    parser.add_argument( "--learning_rate", type=float, default = 0.001,
                         help = "The learning rate to use when training" )
    group = parser.add_mutually_exclusive_group( required = True )
    group.add_argument("--resnet", action='store_true', help = "Run resnet" )
    group.add_argument("--full_prec", action='store_true', help = "Run full precision VGG with SELU" )
    group.add_argument("--twn", action='store_true', help = "Run Vgg with ternary weights" )
    group.add_argument("--twn_binary_act", action='store_true', help = "Run Vgg with ternary weights and binary activations" )
    group.add_argument("--twn_incr_act", type=int, help = "Run Vgg with ternary weights and incrementatal precision activations\nInput int the the number of bin act layers from the top, after that double each layer until >= 16\nWhen >= 16 switch to floating point\nWill binaraize the last conv layer and the dense layers" )
    parser.add_argument( "--nu_conv", type=float,
                         help = "The parameter to use when trinarizing the conv layers" )
    parser.add_argument( "--nu_dense", type=float,
                         help = "The parameter to use when trinarizing the dense layers" )
    parser.add_argument( "--no_filt_vgg", type=int, default = 64,
                         help = "number of filters to use for vgg" )
    parser.add_argument( "--gpus", type=str,
                         help = "GPUs to use" )
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    iterator = batcher( args.dataset, args.batch_size, not args.test )
    if args.gpus is not None:
        os.environ["CUDA_VISIBLE_DEVICES"]=args.gpus
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
    nu = [0.7] + [args.nu_conv]*6 + [args.nu_dense]*2
    if args.resnet:
        with tf.variable_scope("teacher"):
            pred = resnet.get_net( signal, training = training )
    elif args.full_prec:
        pred = Vgg10.get_net( signal, training, use_SELU = True, act_prec = None, nu = None, no_filt = args.no_filt_vgg )
    elif args.twn:
        pred = Vgg10.get_net( signal, training, use_SELU = False, act_prec = None, nu = nu, no_filt = args.no_filt_vgg )
    elif args.twn_binary_act:
        act_prec = [1]*9
        pred = Vgg10.get_net( signal, training, use_SELU = False, act_prec = act_prec, nu = nu, no_filt = args.no_filt_vgg )
    elif args.twn_incr_act is not None:
        # last conv and dense layers should be bin
        act_prec = [1]*args.twn_incr_act + [ 1 << ( i + 1 ) for i in range(6-args.twn_incr_act) ] + [1]*3
        act_prec = [ x if x < 16 else None for x in act_prec ]
        pred = Vgg10.get_net( signal, training, use_SELU = False, act_prec = act_prec, nu = nu, no_filt = args.no_filt_vgg )
    else:
        tf.logging.log( tf.logging.ERROR, "Invalid arguments" )
        exit()
    if not args.test:
        pred_label = tf.cast( tf.math.argmax( pred, axis = 1 ), tf.int32 )
        num_correct = tf.reduce_sum( tf.cast( tf.math.equal( pred_label, label ), tf.float32 ) )
        num_correct = tf.reshape( num_correct, [] )
        if not args.resnet and args.teacher_name is not None:
            with tf.variable_scope("teacher"):
                resnet_pred = tf.stop_gradient( resnet.get_net( signal, training = False ) )
            resnet_saver = tf.train.Saver( tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES, scope="teacher") )
            opt = get_optimizer( pred, label, args.learning_rate, resnet_pred )
        else:
            opt = get_optimizer( pred, label, args.learning_rate )
    init_op = tf.global_variables_initializer()
    saver = tf.train.Saver()
    with tf.Session() as sess:
        try:
            if not args.test:
                smry_wrt = tf.summary.FileWriter( args.model_name + "_logs", sess.graph, session = sess )
                sess.run( iterator.initializer )
                if do_val:
                    sess.run( test_iterator.initializer )
            sess.run( init_op )
            # load the model if possible
            if tf.train.checkpoint_exists( args.model_name ):
                tf.logging.log( tf.logging.INFO, "Loading model ... " )
                saver.restore(sess, args.model_name )
            if args.teacher_name is not None and tf.train.checkpoint_exists( args.teacher_name ):
                tf.logging.log( tf.logging.INFO, "Loading teacher ... " )
                resnet_saver.restore(sess, args.teacher_name )
            if args.test:
                test_loop( snr, pred, label, training, args.test_output, args.test_batches )
            else:
                train_loop( opt, smry_wrt, num_correct, training, no_steps = args.steps, do_val = do_val )
        except tf.errors.OutOfRangeError:
            tf.logging.log( tf.logging.INFO, "Dataset is finished" )
        finally:
            tf.logging.log( tf.logging.INFO, "Saving model ... " )
            saver.save( sess, args.model_name )

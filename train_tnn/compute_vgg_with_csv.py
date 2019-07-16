#! /usr/bin/python3

import twn_generator as twn
import Vgg10
import csv
import numpy as np
import tensorflow as tf

def run_tf_version( model_name, x_in, nu_conv, nu_dense, no_filt, twn_incr_act = None ):
    x = tf.placeholder( tf.float32, [1,1024,2] )
    nu = [0.7] + [nu_conv]*6 + [nu_dense]*2
    if twn_incr_act is not None:
        act_prec = [1]*twn_incr_act + [ 1 << ( i + 1 ) for i in range(6-twn_incr_act) ] + [1]*3
        act_prec = [ x if x < 16 else None for x in act_prec ]
    else:
        act_prec = None
    vgg_pred = Vgg10.get_net( x, False, act_prec = act_prec, nu = nu, no_filt = no_filt )
    saver = tf.train.Saver()
    with tf.Session() as sess:
        saver.restore(sess, model_name )
        pred = sess.run( vgg_pred, feed_dict = { x : x_in } )
    return pred

def rd_tri_weights_file( fname ):
    f = open( fname )
    rdr = csv.reader(f)
    data = np.array( [ [ int(x) for x in y ] for y in rdr ] )
    f.close()
    return data

def rd_fp_weights_file( fname ):
    f = open( fname )
    rdr = csv.reader(f)
    data = np.array( [ [ float(x) for x in y ] for y in rdr ] ).astype( np.float32 )
    f.close()
    return data

def rd_bn_file( fname ):
    f = open( fname )
    rdr = csv.reader(f)
    data = np.array( [ [ float(x) for x in y ] for y in rdr ] ).astype( np.float32 )
    f.close()
    return data

def compute_bn_relu( img, bnvars ):
    a = bnvars[0]
    b = bnvars[1]
    if len(bnvars) > 2:
        x_min = bnvars[2]
        x_max = bnvars[3]
        img_min = img <= x_min
        img_max = img >= x_max
    img = a*img + b
    if len(bnvars) > 2:
        img[img_min] = 0
        # note should be the prec needed not 1
        img[img_max] = 1
    return img*(img > 0)

def wr_img( img, fname ):
    f = open( fname, "w" )
    wrt = csv.writer( f )
    for x in img:
        wrt.writerow( x )
    f.close()

def round_to( img, prec ):
    return np.round( img * ( 1 << prec ) )/( 1 << prec )
    
def compute_network( model_dir, x_in, no_filt, prec = 20 ):
    img = x_in[0]
    mean = np.mean(img, axis=0)
    img = ( img - mean )
    img = round_to( img, prec )
    wr_img( img, model_dir + "/input_img.csv" )
    for i in range(1,8):
        conv_weights = rd_tri_weights_file( model_dir + "/vgg_conv_lyr" + str(i) + ".csv" )
        conv_weights = np.reshape( conv_weights, [ 3, -1, no_filt ] )
        img = twn.conv1d( img, conv_weights )
        wr_img( img, model_dir + "/conv_img_lyr" + str(i) + ".csv" )
        bnvars = rd_bn_file( model_dir + "/vgg_bn_lyr" + str(i) + ".csv" )
        bnvars = round_to( bnvars, prec + 2 )
        img = compute_bn_relu( img, bnvars )
        img = round_to( img, prec )
        wr_img( img, model_dir + "/conv_bn_relu_img_lyr" + str(i) + ".csv" )
        img = twn.maxpool1d( img )
        wr_img( img, model_dir + "/conv_mp_img_lyr" + str(i) + ".csv" )
    img = np.reshape( img, [-1] )
    for i in range(1,3):
        dense_weights = rd_tri_weights_file( model_dir + "/vgg_dense_" + str(i) + ".csv" )
        img = np.matmul( img, dense_weights )
        img = round_to( img, prec )
        wr_img( [img], model_dir + "/dense_img_lyr" + str(i) + ".csv" )
        bnvars = rd_bn_file( model_dir + "/vgg_bn_dense_" + str(i) + ".csv" )
        bnvars = round_to( bnvars, prec + 2 )
        img = compute_bn_relu( img, bnvars )
        img = round_to( img, prec )
        wr_img( [img], model_dir + "/dense_bn_relu_img_lyr" + str(i) + ".csv" )
    dense_weights = rd_fp_weights_file( model_dir + "/vgg_dense_3.csv" )
    dense_weights = dense_weights[1:,:]
    img = np.matmul( img, dense_weights )
    wr_img( [img], model_dir + "/pred_output.csv" )
    return img

if __name__ == "__main__":
    model_dir = "../untrained_models/vgg_twn_nu_1.2_0.7"
    x_in = np.random.normal( 0, 1, [1,1024,2] ).astype( np.float32 )
    no_filt = 64
    tf_pred = run_tf_version( model_dir, x_in, 1.2, 0.7, no_filt, None )
    np_pred = compute_network( model_dir, x_in, no_filt )
    print( "tf_pred = ", tf_pred, tf_pred.shape )
    print( "np_pred = ", np_pred, np_pred.shape )
    print( "diff = ", np.abs( tf_pred - np_pred ) )
    print( "sum = ", np.sum( np.abs( tf_pred - np_pred ) ) )

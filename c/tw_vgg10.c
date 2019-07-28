#include <stdio.h>
#include <stdlib.h>
#include "tw_vgg10.h"

#include "conv1.h"
#include "conv2.h"
#include "conv3.h"
#include "conv4.h"
#include "conv5.h"
#include "conv6.h"
#include "conv7.h"
#include "bn1_a_b.h"
#include "bn2_a_b.h"
#include "bn3_a_b.h"
#include "bn4_a_b.h"
#include "bn5_a_b.h"
#include "bn6_a_b.h"
#include "bn7_a_b.h"
#include "dense1.h"
#include "bnd1_a_b.h"
#include "dense2.h"
#include "bnd2_a_b.h"
#include "vgg_dense_3.h"

#ifdef PYTHON_MOD
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#endif

#ifdef PYTHON_MOD
#define MALLOC_FUNC PyMem_Malloc
#define FREE_FUNC PyMem_Free
#else
#include "input_img.h"
#include "pred_output.h"
#define MALLOC_FUNC malloc
#define FREE_FUNC free
#define PREC 6
#define OUTPUT_IMG pred_output
#define OUTPUT_LEN PRED_OUTPUT_LEN
#define OUTPUT_FILT PRED_OUTPUT_FILT
#endif

#define KSIZE 3

typedef short * (*compute_func)( const short*,short*);
typedef short * (*bn_func)(short*);

// a struct to hold the network info
struct network_vars {
  short * dense3_vars;
  short * lyr_w[7];
  short * lyr_c[7];
  short * lyr_mp[7];
  short * d[3];
  compute_func convs[7];
  bn_func conv_bn[7];
  compute_func dense[2];
  bn_func dense_bn[2];
  int filts[8];
  int prec;
} net_vars;
typedef struct network_vars * n_vars;
n_vars n = &net_vars;

short * convert_float( const float img[], short * img_out, int prec, int len, int filts ) {
  int i,j;
  for ( i = 0; i < len; i++ ) {
    for ( j = 0; j < filts; j++ ) {
      img_out[i*filts + j] = (short) ( img[i*filts + j] * ( 1 << prec ) );
    }
  }
  return img_out;
}

short * window_data_1d( const short * img, short * out, int idx, int img_len, int no_filt ) {
  int i, j;
  for ( i = -1; i < KSIZE - 1; i++ ) {
    for ( j = 0; j < no_filt; j++ ) {
      if ( idx + i < 0 || idx + i >= img_len )
	out[(i+1)*no_filt + j] = 0;
      else
	out[(i+1)*no_filt + j] = img[(idx + i)*no_filt + j];
    }
  }
  return out;
}

short * maxpool_1d( const short * img, short * out, int len, int filts ) {
  // just always do size of 2
  int i,j;
  for ( i = 0; i < len/2; i++ ) {
    for ( j = 0; j < filts; j++ ) {
      if ( img[2*i*filts + j] > img[(2*i + 1)*filts + j] )
	out[i*filts + j] = img[2*i*filts + j];
      else
	out[i*filts + j] = img[(2*i + 1)*filts + j];
    }
  }
  return out;
}

short * compute_conv_layer( const short * img, int img_len, int lyr_i ) {
  int idx;
  for ( idx = 0; idx < img_len; idx++ ) {
    // window
    window_data_1d( img, n->lyr_w[lyr_i], idx, img_len, n->filts[lyr_i] );
    // conv
    short * curr_conv_out = &(n->lyr_c[lyr_i][idx*n->filts[lyr_i + 1]]);
    n->convs[lyr_i]( n->lyr_w[lyr_i], curr_conv_out );
    // bn
    n->conv_bn[lyr_i]( curr_conv_out );
  }
  // mp
  maxpool_1d( n->lyr_c[lyr_i], n->lyr_mp[lyr_i], img_len, n->filts[lyr_i + 1] );
  return n->lyr_mp[lyr_i];
}

short * compute_dense_layer( short * img, int i ) {
  n->dense[i]( img, n->d[i] );
  n->dense_bn[i]( n->d[i] );
  return n->d[i];
}

short * compute_d3() {
  int i,j;
  for ( i = 0; i < VGG_DENSE_3_FILT; i++ ) {
    int tmp_sum = 0;
    for ( j = 0; j < VGG_DENSE_3_LEN; j++ )
      tmp_sum += n->dense3_vars[j*VGG_DENSE_3_FILT + i]*n->d[1][j];
    n->d[2][i] = (short)(tmp_sum >> n->prec);
  }
  return n->d[2];
}

short * clip_act( short * img, int len, int bits ) {
  // relu already makes sure >= 0
  // bn should have already scaled it, just need to clip for quantization
  int i;
  int max_val = ( 1 << bits ) - 1;
  for ( i = 0; i < len; i++ ) {
    if ( img[i] > max_val )
      img[i] = max_val;
  }
  return img;
}

void allocate_network( int prec ) {
  int img_len = IMG_LEN;
  n = (n_vars)MALLOC_FUNC(sizeof(struct network_vars));
  n->prec = prec;
  n->dense3_vars = (short*)MALLOC_FUNC(sizeof(short)*VGG_DENSE_3_LEN*VGG_DENSE_3_FILT);
  convert_float( vgg_dense_3, n->dense3_vars, prec, VGG_DENSE_3_LEN, VGG_DENSE_3_FILT );
  n->convs[0] = conv1;
  n->convs[1] = conv2;
  n->convs[2] = conv3;
  n->convs[3] = conv4;
  n->convs[4] = conv5;
  n->convs[5] = conv6;
  n->convs[6] = conv7;
  n->conv_bn[0] = bn1_a_b;
  n->conv_bn[1] = bn2_a_b;
  n->conv_bn[2] = bn3_a_b;
  n->conv_bn[3] = bn4_a_b;
  n->conv_bn[4] = bn5_a_b;
  n->conv_bn[5] = bn6_a_b;
  n->conv_bn[6] = bn7_a_b;
  n->dense[0] = dense1;
  n->dense[1] = dense2;
  n->dense_bn[0] = bnd1_a_b;
  n->dense_bn[1] = bnd2_a_b;
  n->filts[0] = IMG_FILT;
  n->filts[1] = CONV1_OUT;
  n->filts[2] = CONV2_OUT;
  n->filts[3] = CONV3_OUT;
  n->filts[4] = CONV4_OUT;
  n->filts[5] = CONV5_OUT;
  n->filts[6] = CONV6_OUT;
  n->filts[7] = CONV7_OUT;
  n->lyr_w[0] = (short*)MALLOC_FUNC(sizeof(short)*CONV1_IN );
  n->lyr_c[0] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV1_OUT );
  img_len /= 2;
  n->lyr_mp[0] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV1_OUT );
  n->lyr_w[1] = (short*)MALLOC_FUNC(sizeof(short)*CONV2_IN );
  n->lyr_c[1] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV2_OUT );
  img_len /= 2;
  n->lyr_mp[1] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV2_OUT );
  n->lyr_w[2] = (short*)MALLOC_FUNC(sizeof(short)*CONV3_IN );
  n->lyr_c[2] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV3_OUT );
  img_len /= 2;
  n->lyr_mp[2] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV3_OUT );
  n->lyr_w[3] = (short*)MALLOC_FUNC(sizeof(short)*CONV4_IN );
  n->lyr_c[3] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV4_OUT );
  img_len /= 2;
  n->lyr_mp[3] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV4_OUT );
  n->lyr_w[4] = (short*)MALLOC_FUNC(sizeof(short)*CONV5_IN );
  n->lyr_c[4] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV5_OUT );
  img_len /= 2;
  n->lyr_mp[4] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV5_OUT );
  n->lyr_w[5] = (short*)MALLOC_FUNC(sizeof(short)*CONV6_IN );
  n->lyr_c[5] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV6_OUT );
  img_len /= 2;
  n->lyr_mp[5] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV6_OUT );
  n->lyr_w[6] = (short*)MALLOC_FUNC(sizeof(short)*CONV7_IN );
  n->lyr_c[6] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV7_OUT );
  img_len /= 2;
  n->lyr_mp[6] = (short*)MALLOC_FUNC(sizeof(short)*img_len*CONV7_OUT );
  n->d[0] = (short*)MALLOC_FUNC(sizeof(short)*DENSE1_OUT );
  n->d[1] = (short*)MALLOC_FUNC(sizeof(short)*DENSE2_OUT );
  n->d[2] = (short*)MALLOC_FUNC(sizeof(short)*VGG_DENSE_3_FILT );
};

void free_network() {
  FREE_FUNC( n->dense3_vars );
  int i;
  for ( i = 0; i < 7; i++ ){
    FREE_FUNC(n->lyr_w[i]);
    FREE_FUNC(n->lyr_c[i]);
    FREE_FUNC(n->lyr_mp[i]);
  }
  for ( i = 0; i < 3; i++ )
    FREE_FUNC(n->d[i]);
  FREE_FUNC(n);
}

short * compute_network( const short * img ) {
  int i;
  int img_len = IMG_LEN;
  short * curr_img = compute_conv_layer( img, img_len, 0 );
  for ( i = 1; i < 7; i++ ) {
    img_len /= 2;
    curr_img = compute_conv_layer( curr_img, img_len, i );
  }
  for ( i = 0; i < 2; i++ )
    curr_img = compute_dense_layer( curr_img, i );
  return compute_d3();
}

#ifndef PYTHON_MOD
int main( int argc, char ** argv ) {
  // expected
  short * img_expect = (short*)malloc(sizeof(short)*OUTPUT_LEN*OUTPUT_FILT );
  convert_float( OUTPUT_IMG, img_expect, PREC, OUTPUT_LEN, OUTPUT_FILT );

  // input
  int img_len = IMG_LEN;
  short * img = (short*)malloc(sizeof(short)*img_len*IMG_FILT );
  convert_float( input_img, img, PREC, img_len, IMG_FILT );

  allocate_network( PREC );
  short * output = compute_network( img );

  int i,j;
  for ( i = 0; i < OUTPUT_LEN; i++ ) {
    for ( j = 0; j < OUTPUT_FILT; j++ ) {
      if ( output[i*OUTPUT_FILT+j] != img_expect[i*OUTPUT_FILT+j] )
	printf( "FAILED: (%d,%d) where %d != %d\n", i, j, output[i*OUTPUT_FILT+j], img_expect[i*OUTPUT_FILT+j] );
    }
  }

  free_network( n );
  return 0;
}
#endif

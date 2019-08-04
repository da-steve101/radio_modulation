#! /bin/bash

export MODEL_DIR=../models/vgg_twn_nu_1.2_0.7_bin_64

python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr1_a_b.csv $MODEL_DIR/bn1.sv 1 14 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr2_a_b.csv $MODEL_DIR/bn2.sv 2 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr3_a_b.csv $MODEL_DIR/bn3.sv 3 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr4_a_b.csv $MODEL_DIR/bn4.sv 4 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr5_a_b.csv $MODEL_DIR/bn5.sv 5 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr6_a_b.csv $MODEL_DIR/bn6.sv 6 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr7_a_b.csv $MODEL_DIR/bn7.sv 7 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_dense_1_a_b.csv $MODEL_DIR/bnd1.sv d1 8 16 1 1 1
python3 generate_bn_vecs.py $MODEL_DIR/vgg_bn_dense_2_a_b.csv $MODEL_DIR/bnd2.sv d2 8 16 1 1 1

python3 generate_dense_vecs.py $MODEL_DIR/vgg_dense_1.csv $MODEL_DIR/dense_1.sv 1 0 2 1
python3 generate_dense_vecs.py $MODEL_DIR/vgg_dense_2.csv $MODEL_DIR/dense_2.sv 2 0 2 1
python3 generate_dense_vecs.py $MODEL_DIR/vgg_dense_3.csv $MODEL_DIR/dense_3.sv 3 6 16 1

python3 generate_test_vecs.py ../models/input_img.csv $MODEL_DIR/input_hex.sv IN 6 16
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr1.csv $MODEL_DIR/conv1_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr2.csv $MODEL_DIR/conv2_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr3.csv $MODEL_DIR/conv3_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr4.csv $MODEL_DIR/conv4_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr5.csv $MODEL_DIR/conv5_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr6.csv $MODEL_DIR/conv6_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_bn_relu_img_lyr7.csv $MODEL_DIR/conv7_bn_relu_hex.sv OUT 0 1
python3 generate_test_vecs.py $MODEL_DIR/conv_mp_img_lyr7.csv $MODEL_DIR/mp7_hex.sv OUT 0 16
python3 generate_test_vecs.py $MODEL_DIR/pred_output.csv $MODEL_DIR/dense_3_hex.sv OUT 6 16

python3 generate_tw_vgg10.py $MODEL_DIR 16,1,1,1,1,1,1 16,16,16,16,16,16,16 n,p,p,p,p,p,p

rsync -aP $MODEL_DIR/*_hex.sv ../verilog_test/tw_vgg_2iq_bin_test.sv tuna:~/rt_amc_models/bin64/sim/
rm $MODEL_DIR/*_hex.sv
rsync -aP $MODEL_DIR/*.sv ../verilog/*.sv --exclude tw_vgg.sv --exclude tw_vgg_2iq.sv tuna:~/rt_amc_models/bin64/srcs/


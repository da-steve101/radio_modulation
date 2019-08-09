#! /bin/bash

MODEL_DIR=../models/vgg_twn_nu_1.2_0.7_incr1_128
PREC=6
BN_PREC=8
SHIFT=$(( PREC + BN_PREC ))

cd ../train_tnn
python3 extract_weights_from_vgg.py --model_name $MODEL_DIR
python3 compute_vgg_with_csv.py --model_name $MODEL_DIR --nu_conv 1.2 --nu_dense 0.7 --prec $PREC \
 --bn_p $BN_PREC --wr_files --no_filts 128,128,128,128,128,128,128,512,512,24 --remove_mean --twn_incr_act 1
cd ../verilog_generation

python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr1_a_b.csv --file_out $MODEL_DIR/bn1.sv --bn_id 1 --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr2_a_b.csv --file_out $MODEL_DIR/bn2.sv --bn_id 2 --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr3_a_b.csv --file_out $MODEL_DIR/bn3.sv --bn_id 3 --rshift $BN_PREC --bw_in 16 --bw_out 2 --maxval 3
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr4_a_b.csv --file_out $MODEL_DIR/bn4.sv --bn_id 4 --rshift $BN_PREC --bw_in 16 --bw_out 4 --maxval 15
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr5_a_b.csv --file_out $MODEL_DIR/bn5.sv --bn_id 5 --rshift $BN_PREC --bw_in 16 --bw_out 8 --maxval 255
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr6_a_b.csv --file_out $MODEL_DIR/bn6.sv --bn_id 6 --rshift $BN_PREC --bw_in 16 --bw_out 16
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr7_a_b.csv --file_out $MODEL_DIR/bn7.sv --bn_id 7 --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1

python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_dense_1_a_b.csv --file_out $MODEL_DIR/bnd1.sv --bn_id D1 --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_1.csv --file_out $MODEL_DIR/dense_1.sv --lyr 1 --bw_w 2 --tput 2
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_dense_2_a_b.csv --file_out $MODEL_DIR/bnd2.sv --bn_id D2 --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_2.csv --file_out $MODEL_DIR/dense_2.sv --lyr 2 --bw_w 2
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_3.csv --file_out $MODEL_DIR/dense_3.sv --lyr 3 --rshift $PREC --bw_w 16

python3 generate_test_vecs.py --file_in $MODEL_DIR/../input_img.csv --file_out $MODEL_DIR/input_hex.sv --is_in --mul 64
python3 generate_test_vecs.py --file_in $MODEL_DIR/pred_output.csv --file_out $MODEL_DIR/dense_3_hex.sv --mul 64

python3 generate_tw_vgg10.py --model_dir $MODEL_DIR --bws_in 16,1,1,1,1,16,16 --bws_out 16,16,16,16,16,16,16 -t n,p,p,p,p,s,s

rsync -aP $MODEL_DIR/*_hex.sv ../verilog_test/tw_vgg_2iq_incr_test.sv tuna:~/rt_amc_models/incr1/sim/
rm $MODEL_DIR/*_hex.sv
rsync -aP $MODEL_DIR/*.sv ../verilog/*.sv --exclude tw_vgg.sv --exclude tw_vgg_2iq_bin.sv --exclude tw_vgg_2iq_bin.sv tuna:~/rt_amc_models/incr1/srcs/


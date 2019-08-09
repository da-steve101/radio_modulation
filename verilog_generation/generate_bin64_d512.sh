#! /bin/bash

MODEL_DIR=../models/vgg_twn_nu_1.2_0.7_bin_64_d512
PREC=6
BN_PREC=8
SHIFT=$(( PREC + BN_PREC ))

cd ../train_tnn
python3 extract_weights_from_vgg.py --model_name $MODEL_DIR
python3 compute_vgg_with_csv.py --model_name $MODEL_DIR --twn_incr_act 6 --nu_conv 1.2 --nu_dense 0.7 --prec $PREC \
 --bn_p $BN_PREC --wr_files --no_filts 64,64,64,64,64,64,64,512,512,24 --remove_mean
cd ../verilog_generation

python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr1_a_b.csv --file_out $MODEL_DIR/bn1.sv --bn_id 1 --rshift $SHIFT --bw_in 16 --bw_out 1 --maxval 1
for i in {2..7}
do
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr$i"_a_b.csv" --file_out $MODEL_DIR/bn$i.sv --bn_id $i --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
done
for i in {1..2}
do
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_dense_$i"_a_b.csv" --file_out $MODEL_DIR/bnd$i.sv --bn_id d$i --rshift $BN_PREC --bw_in 16 --bw_out 1 --maxval 1
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_$i.csv --file_out $MODEL_DIR/dense_$i.sv --lyr $i --bw_w 2
done
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_3.csv --file_out $MODEL_DIR/dense_3.sv --lyr 3 --rshift $PREC --bw_w 16

python3 generate_test_vecs.py --file_in $MODEL_DIR/../input_img.csv --file_out $MODEL_DIR/input_hex.sv --is_in --mul 64
python3 generate_test_vecs.py --file_in $MODEL_DIR/pred_output.csv --file_out $MODEL_DIR/dense_3_hex.sv --mul 64

python3 generate_tw_vgg10.py --model_dir $MODEL_DIR --bws_in 16,1,1,1,1,1,1 --bws_out 16,16,16,16,16,16,16 -t n,p,p,p,p,p,p

rsync -aP $MODEL_DIR/*_hex.sv ../verilog_test/tw_vgg_2iq_bin_test.sv tuna:~/rt_amc_models/bin64_d512/sim/
rm $MODEL_DIR/*_hex.sv
rsync -aP $MODEL_DIR/*.sv ../verilog/*.sv --exclude tw_vgg.sv --exclude tw_vgg_2iq.sv --exclude tw_vgg_2iq_incr.sv tuna:~/rt_amc_models/bin64_d512/srcs/


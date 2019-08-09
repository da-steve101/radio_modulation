#! /bin/bash

MODEL_DIR=../models/vgg_twn_nu_1.2_0.7_f96
PREC=6
BN_PREC=8
SHIFT=$(( PREC + BN_PREC ))

cd ../train_tnn
python3 extract_weights_from_vgg.py --model_name $MODEL_DIR
python3 compute_vgg_with_csv.py --model_name $MODEL_DIR --nu_conv 1.2 --nu_dense 0.7 --prec $PREC \
 --bn_p $BN_PREC --wr_files --no_filts 96,96,96,96,96,96,96,512,512,24 --remove_mean
cd ../verilog_generation

for i in {1..7}
do
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_lyr$i"_a_b.csv" --file_out $MODEL_DIR/bn$i.sv --bn_id $i --rshift $BN_PREC --bw_in 16 --bw_out 16
done
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_dense_1_a_b.csv --file_out $MODEL_DIR/bnd1.sv --bn_id 1 --rshift $BN_PREC --bw_in 16 --bw_out 16
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_1.csv --file_out $MODEL_DIR/dense_1.sv --lyr 1 --bw_w 2 --tput 2
python3 generate_bn_vecs.py --file_in $MODEL_DIR/vgg_bn_dense_2_a_b.csv --file_out $MODEL_DIR/bnd2.sv --bn_id 2 --rshift $BN_PREC --bw_in 16 --bw_out 16
python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_2.csv --file_out $MODEL_DIR/dense_2.sv --lyr 2 --bw_w 2

python3 generate_dense_vecs.py --file_in $MODEL_DIR/vgg_dense_3.csv --file_out $MODEL_DIR/dense_3.sv --lyr 3 --rshift $PREC --bw_w 16

python3 generate_test_vecs.py --file_in $MODEL_DIR/../input_img.csv --file_out $MODEL_DIR/input_hex.sv --is_in --mul 64
python3 generate_test_vecs.py --file_in $MODEL_DIR/pred_output.csv --file_out $MODEL_DIR/dense_3_hex.sv --mul 64

python3 generate_tw_vgg10.py --model_dir $MODEL_DIR --bws_in 16,16,8,4,2,1,1 --bws_out 16,16,8,4,2,1,1 -t n,n,s,s,s,s,s

rsync -aP $MODEL_DIR/*_hex.sv ../verilog_test/tw_vgg_2iq_test.sv tuna:~/rt_amc_models/f96/sim/
rm $MODEL_DIR/*_hex.sv
rsync -aP $MODEL_DIR/*.sv ../verilog/*.sv --exclude tw_vgg.sv --exclude tw_vgg_2iq_bin.sv --exclude tw_vgg_2iq_incr.sv tuna:~/rt_amc_models/f96/srcs/


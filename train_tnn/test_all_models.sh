#! /bin/bash

GPUS=0,1
BATCH_SIZE=64
TEST_BATCHES=154
MODEL_DIR=/home/stephen/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig
for snr in {-20..30..2}
do
TEST_ARGS="--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --dataset $DATA_DIR/modulation_classification_test_snr_$snr.rcrd"
# make resnet full precision
mkdir -p $MODEL_DIR/resnet
python3 run_cnn.py --model_name $MODEL_DIR/resnet --resnet --gpus $GPUS $TEST_ARGS --test_output $MODEL_DIR/resnet/test_$snr"_snr.csv"
# make vgg full precision
mkdir -p $MODEL_DIR/vgg_fp_64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64 $TEST_ARGS --full_prec --no_filt_vgg 64 --test_output $MODEL_DIR/vgg_fp_64/test_$snr"_snr.csv"
# vgg fp with dense 512
mkdir -p $MODEL_DIR/vgg_fp_64_d512
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64_d512 $TEST_ARGS --full_prec --no_filts 64,64,64,64,64,64,64,512,512,24 --test_output $MODEL_DIR/vgg_fp_64_d512/test_$snr"_snr.csv"
# vgg fp 128
mkdir -p $MODEL_DIR/vgg_fp_128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_128 $TEST_ARGS --full_prec --no_filts 128,128,128,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_fp_128/test_$snr"_snr.csv"
#custom Vgg
mkdir -p $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24 $TEST_ARGS --full_prec --no_filts 64,64,64,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24/test_$snr"_snr.csv"
# make vgg TWN with 64
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64 $TEST_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,64,64,64,64,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64/test_$snr"_snr.csv"
# make vgg TWN with 96
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96 $TEST_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 96,96,96,96,96,96,96,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96/test_$snr"_snr.csv"
# make vgg TWN with 128
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128 $TEST_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128/test_$snr"_snr.csv"
#custom Vgg
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24 $TEST_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24/test_$snr"_snr.csv"
# Vgg bin 64
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 $TEST_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 64 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64/test_$snr"_snr.csv"
# Vgg bin 64 dense 512
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64_d512
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64_d512 $TEST_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,64,64,64,64,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64_d512/test_$snr"_snr.csv"
# Vgg bin 128
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 $TEST_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128/test_$snr"_snr.csv"
# Vgg inrc Act
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128 $TEST_ARGS --twn_incr_act 1 --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128/test_$snr"_snr.csv"
# Vgg inrc Act 2
mkdir -p $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128 $TEST_ARGS --twn_incr_act 2 --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24 --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128/test_$snr"_snr.csv"
done

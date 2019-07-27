#! /bin/bash

GPUS=0,1
BATCH_SIZE=64
TEST_BATCHES=154
MODEL_DIR=/home/stephen/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig
for snr in $(seq -20 2 30)
do
# make resnet full precision
python3 run_cnn.py --model_name $MODEL_DIR/resnet --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/resnet/test_$snr"_snr.csv" --resnet --gpus $GPUS
# make vgg full precision
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_fp_64/test_$snr"_snr.csv" --full_prec --gpus $GPUS  \
--no_filt_vgg 64
# vgg fp 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_fp_128/test_$snr"_snr.csv" --full_prec --gpus $GPUS  \
--no_filt_vgg 128
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24/test_$snr"_snr.csv" --full_prec --gpus $GPUS  \
--no_filts 64,64,64,128,128,128,128,512,512,24
# make vgg TWN with 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64/test_$snr"_snr.csv" --twn --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64
# make vgg TWN with 80
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f80 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f80/test_$snr"_snr.csv" --twn --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 80
# make vgg TWN with 96
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96/test_$snr"_snr.csv" --twn --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 96
# make vgg TWN with 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128/test_$snr"_snr.csv" --twn --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24/test_$snr"_snr.csv" --twn --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,128,128,128,128,512,512,24
# Vgg bin 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64/test_$snr"_snr.csv" --twn_binary_act --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64
# Vgg bin 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128/test_$snr"_snr.csv" --twn_binary_act --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
# Vgg inrc Act
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128/test_$snr"_snr.csv" --twn_incr_act 1 --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
# Vgg inrc Act 2
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size $BATCH_SIZE --test --test_batches $TEST_BATCHES --test_output $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128/test_$snr"_snr.csv" --twn_incr_act 2 --gpus $GPUS  \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
done


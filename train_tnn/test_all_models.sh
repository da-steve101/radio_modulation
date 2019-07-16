#! /bin/bash

GPUS=1
MODEL_DIR=~/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig

for snr in $(seq -20 2 30)
do
python3 run_cnn.py --resnet --gpus $GPUS --model_name $MODEL_DIR/resnet --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154
done
python3 print_accrs.py > $MODEL_DIR/resnet.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --full_prec --gpus $GPUS --model_name $MODEL_DIR/vgg_fp --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154
done
python3 print_accrs.py > $MODEL_DIR/vgg_fp.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --twn --gpus $GPUS --model_name $MODEL_DIR/vgg_twn_1.2_0.7 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154 --nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64
done
python3 print_accrs.py > $MODEL_DIR/vgg_twn_1.2_0.7.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --twn_binary_act --gpus $GPUS --model_name $MODEL_DIR/vgg_twn_1.2_0.7_bin_64 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154 --nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64
done
python3 print_accrs.py > $MODEL_DIR/vgg_twn_1.2_0.7_bin_64.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --twn_binary_act --gpus $GPUS --model_name $MODEL_DIR/vgg_twn_1.2_0.7_bin_128 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154 --nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
done
python3 print_accrs.py > $MODEL_DIR/vgg_twn_1.2_0.7_bin_128.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --twn_incr_act 1 --gpus $GPUS --model_name $MODEL_DIR/vgg_twn_1.2_0.7_incr_1 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154 --nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
done
python3 print_accrs.py > $MODEL_DIR/vgg_twn_1.2_0.7_incr_1.txt
for snr in $(seq -20 2 30)
do
python3 run_cnn.py --twn_incr_act 2 --gpus $GPUS --model_name $MODEL_DIR/vgg_twn_1.2_0.7_incr_2 --dataset $DATA_DIR/modulation_classification_test_snr_$snr".rcrd" \
--batch_size 64 --test --test_output test_$snr"_snr.csv" --test_batches 154 --nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128
done
python3 print_accrs.py > $MODEL_DIR/vgg_twn_1.2_0.7_incr_2.txt



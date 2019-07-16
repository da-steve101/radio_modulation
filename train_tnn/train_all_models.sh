#! /bin/bash

GPUS=1
STEPS=210000
LR=0.001
BATCH_SIZE=64
MODEL_DIR=/home/stephen/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig
# make resnet full precision
python3 run_cnn.py --model_name $MODEL_DIR/resnet --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --resnet --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd
# make vgg full precision
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --full_prec --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--no_filt_vgg 64 --teacher_name $MODEL_DIR/resnet
STEPS=500000
# make vgg TWN with 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7 --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64 --teacher_name $MODEL_DIR/resnet
# make vgg TWN with binary act and 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_binary_act --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64 --teacher_name $MODEL_DIR/resnet
# make vgg TWN with binary act and 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_binary_act --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_name $MODEL_DIR/resnet
# make vgg TWN with incr act and 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_inrc_1 --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_incr_act 1 --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_name $MODEL_DIR/resnet
# make vgg TWN with incr act and 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_inrc_2 --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_incr_act 2 --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_name $MODEL_DIR/resnet

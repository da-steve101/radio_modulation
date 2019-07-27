#! /bin/bash

GPUS=0,1
STEPS=250000
LR=0.001
BATCH_SIZE=128
MODEL_DIR=/home/stephen/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig
# make resnet full precision
python3 run_cnn.py --model_name $MODEL_DIR/resnet --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --resnet --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd
# run resnet through the training set to add student teacher
python3 add_resnet_to_train.py --dataset_rcrd /opt/datasets/deepsig/modulation_classification_train.rcrd --rcrd_prefix modulation_classification \
--rcrd_suffix .rcrd --resnet_model $MODEL_DIR/resnet --gpus $GPUS
# make vgg full precision
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --full_prec --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--no_filt_vgg 64 --teacher_dset
# vgg fp 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_128 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --full_prec --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--no_filt_vgg 128 --teacher_dset
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --full_prec --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--no_filts 64,64,64,128,128,128,128,512,512,24 --teacher_dset
# make vgg TWN with 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64 --teacher_dset
# make vgg TWN with 96
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 96 --teacher_dset
# make vgg TWN with 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_dset
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,128,128,128,128,512,512,24 --teacher_dset
# Vgg bin 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_binary_act --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 64 --teacher_dset
# Vgg bin 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_binary_act --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_dset
# Vgg inrc Act
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_incr_act 1 --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_dset
# Vgg inrc Act 2
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128 --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --twn_incr_act 2 --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd \
--nu_conv 1.2 --nu_dense 0.7 --no_filt_vgg 128 --teacher_dset

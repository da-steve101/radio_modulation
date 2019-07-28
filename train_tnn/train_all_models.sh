#! /bin/bash

GPUS=0,1
STEPS=250000
LR=0.001
BATCH_SIZE=128
MODEL_DIR=/home/stephen/radio_modulation/models
DATA_DIR=/opt/datasets/deepsig
TRAIN_ARGS="--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --dataset $DATA_DIR/modulation_classification_resnet_train.rcrd --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd --teacher_dset"
# make resnet full precision
python3 run_cnn.py --model_name $MODEL_DIR/resnet --dataset $DATA_DIR/modulation_classification_train.rcrd \
--steps $STEPS --batch_size $BATCH_SIZE --learning_rate $LR --resnet --gpus $GPUS --val_dataset $DATA_DIR/modulation_classification_test_snr_30.rcrd
# run resnet through the training set to add student teacher
if [ ! -e $DATA_DIR/modulation_classification_resnet_train.rcrd  ]
then
  echo "Teacher Dataset does not exist. Creating ... "
  python3 add_resnet_to_train.py --dataset_rcrd /opt/datasets/deepsig/modulation_classification_train.rcrd --rcrd_prefix modulation_classification \
  --rcrd_suffix .rcrd --resnet_model $MODEL_DIR/resnet --gpus $GPUS
fi
# make vgg full precision
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64 $TRAIN_ARGS --full_prec --no_filt_vgg 64
# vgg fp with dense 512
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_64_d512 $TRAIN_ARGS --full_prec --no_filts 64,64,64,64,64,64,64,512,512,24
# vgg fp 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_128 $TRAIN_ARGS --full_prec --no_filts 128,128,128,128,128,128,128,512,512,24
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_fp_3x64_3x128_512_512_24 $TRAIN_ARGS --full_prec --no_filts 64,64,64,128,128,128,128,512,512,24
# make vgg TWN with 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f64 $TRAIN_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,64,64,64,64,512,512,24
# make vgg TWN with 96
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f96 $TRAIN_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 96,96,96,96,96,96,96,512,512,24
# make vgg TWN with 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_f128 $TRAIN_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24
#custom Vgg
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_3x64_3x128_512_512_24 $TRAIN_ARGS --twn --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,128,128,128,128,512,512,24
# Vgg bin 64
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 $TRAIN_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 64
# Vgg bin 64 dense 512
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64_d512 $TRAIN_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 64,64,64,64,64,64,64,512,512,24
# Vgg bin 128
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 $TRAIN_ARGS --twn_binary_act --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24
# Vgg inrc Act
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr1_128 $TRAIN_ARGS --twn_incr_act 1 --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24
# Vgg inrc Act 2
python3 run_cnn.py --model_name $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr2_128 $TRAIN_ARGS --twn_incr_act 2 --nu_conv 1.2 --nu_dense 0.7 --no_filts 128,128,128,128,128,128,128,512,512,24

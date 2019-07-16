MODEL_DIR=~/radio_modulation/models

python3 extract_weights_from_vgg.py $MODEL_DIR/vgg_twn_nu_1.2_0.7 1.2 0.7 -1
python3 extract_weights_from_vgg.py $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_64 1.2 0.7 6
python3 extract_weights_from_vgg.py $MODEL_DIR/vgg_twn_nu_1.2_0.7_bin_128 1.2 0.7 6
python3 extract_weights_from_vgg.py $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr_1 1.2 0.7 1
python3 extract_weights_from_vgg.py $MODEL_DIR/vgg_twn_nu_1.2_0.7_incr_2 1.2 0.7 2


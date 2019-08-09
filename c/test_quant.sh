#! /bin/bash

MODEL_DIRS="../models/vgg_twn_nu_1.2_0.7_bin_128 ../models/vgg_twn_nu_1.2_0.7_bin_64_d512 ../models/vgg_twn_nu_1.2_0.7_bin_64 ../models/vgg_twn_nu_1.2_0.7_f128 \
../models/vgg_twn_nu_1.2_0.7_f64 ../models/vgg_twn_nu_1.2_0.7_f96 ../models/vgg_twn_nu_1.2_0.7_incr1_128"

for MODEL_DIR in $MODEL_DIRS
do
echo "Running on $MODEL_DIR"
rm -rf build
python3 setup.py build
python3 run_on_test_sets.py --file_out $MODEL_DIR/test_quant_snr.csv
done

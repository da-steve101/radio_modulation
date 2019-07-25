MODEL_DIR=models/vgg_twn_nu_1.2_0.7
A_PREC=8
B_PREC=14

# extract the values from tensorflow
python3 train_tnn/extract_weights_from_vgg.py $MODEL_DIR 1.2 0.7 -1

# create BN csvs
for i in {1..7}
do
  python3 verilog_generation/generate_bn_vecs.py $MODEL_DIR/vgg_bn_lyr$i.csv $MODEL_DIR/bn$i.sv $i $A_PREC $B_PREC
done
for i in {1..2}
do
  python3 verilog_generation/generate_bn_vecs.py $MODEL_DIR/vgg_bn_dense_$i.csv $MODEL_DIR/bnd$i.sv $i $A_PREC $B_PREC
done

# run cse and create convs
python3 verilog_generation/generate_tw_vgg10.py $MODEL_DIR



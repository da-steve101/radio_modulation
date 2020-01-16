Tutorial on training and implementing TNNs
==========================================

This is a casual tutorial on training and implementing TNNs for FPGAs.
It assumes familiarity with neural networks, FPGAs, python and tensorflow.

Training TWNs
=============

I have used the method described in the paper Ternary Weight Networks (TWNs).
The function trinarize in the file [quantization.py](https://github.com/da-steve101/radio_modulation/blob/master/train_tnn/quantization.py) implements this method.
The TWN paper recommends a value of nu = 0.7 and in my experience this gives good accuracy.
However, this value can be increased to give better sparsity with minimal drop in accuracy.
I have found a value of 1.2 to 1.4 to be good.
See table 2 in the paper [Unrolling Ternary Neural Networks (UTNN)](https://dl.acm.org/doi/pdf/10.1145/3359983?download=true) for futher details.
The rest of this tutorial will refer figures and tables from this paper.

Implementing TWNs in Verilog
============================

This method assumes a trained TNN model (does not have to be TWN based).
It is a streaming architecture with each pixel arriving in as shown in figure 1 of the UTNN paper.
All components of the network are implemented similarly to existing literature with the exception of the convolutional layers.
The convolution is streamed so that each cycle a single convolutional window is ready ( the shaded section in fig 1 ).
For a 6x6 image there are 36 different windows so to prepare entire convolution operation will take 36 cycles.
After this buffering, the input of a single window is a vector and the weights are a matrix to multiply into them.

As the values in each layer are -eta,0 and eta for quantized weights using the TWN method, the factor of eta is removed until after the convolution.
This leaves values of -1,0 and 1 for the weights.
Table 1 shows an example filter for the convolution multiplied with the values streaming in.
This gives and equation z0 = c + e + f - ( a + h).
As there are many convolutional filters that need to be computed in parallel with the same inputs, resources can be shared among these computations (see fig 3 for an example).
To determine the best way to share resources, common subexpression elimination (CSE) is used.
It is important to note here that no multipliers are needed to compute the convolution! (except for the eta that we moved out but that will come up later)

To implement the convolutional layer in verilog, the first step is to transform the ternary weights into a csv.
The python3 package 'twn_generator' is used to transform these weights. See the github here: [twn_generator](https://github.com/da-steve101/twn_generator)
The file [conv1_weights.csv](https://github.com/da-steve101/twn_generator/blob/master/data/conv1_weights.csv) contains example weights of a small convolution.
It accepts 27 inputs and has 64 filters so 64 outputs.
Clone the twn_generator repo and run the example:
```bash
python3 run_cse_and_generate_example.py --matrix_fname data/conv1_weights.csv --cse_fname data/conv1_tern_op_list.csv --module_name lyr1 --BW_in 16
```
In the file run_cse_and_generate_example.py, the computationally intensive part is the CSE performed in line #25
This computes how to best share resources among the filters.
Line #37 actually generates the verilog implementing this convolution.
Looking at the generated file lyr1.sv, the operations are implemented as various adds followed by registers.
The module has input vector in, and outputs out.
For a fully functional layer, there has to be a buffering module producing the windows.
This is normally followed by a batch normalization and ReLU.

For inference batch normalization is computed with the function f(x) = a\*x + b. This is where the eta from before comes in.
We also need to compute y = eta\*x. So this gives the new function f(y) = (a\*eta)\*x + b. As both a and eta are known, the multiplication between them can be precomputed.

The next consideration is max pooling layers. Implementing them is straight forward enough but max pooling layers have important implications of the throughput needed in each layer. Consider for example a max pool layer with a kernel of 2x2 and a stride of 2.
For a 2d image, this means the output image is 4x smaller than the input image. Or in the next convolutional layer, there will only be new input every 4 cycles. Instead of computing each add in the tree over 1 cycle, serial adders can be used to reduce the area to compute over 4 cycles. This optimization means much smaller designs with no change in throughput. This can also be exploited for activation precisions but I wont go into any further detail here.

The twn_generator package can generate these serial adders. Run the example
```bash
python3 run_cse_and_generate_example.py --matrix_fname data/conv1_weights.csv --cse_fname data/conv1_tern_op_list.csv --module_name lyr1_serial --BW_in 4 --serial
```
in the twn_generator repository.

Summary
=======
1) Train a model with ternary weights
2) Dump the weights to a CSV
3) Run CSE to build a tree and share resources
4) generate verilog for the convolutions
5) consider exploiting drops in throughputs to save on area
6) Implement the rest of the network (buffering,maxpool,batchnorm,relu) in verilog ( still a very big job! )



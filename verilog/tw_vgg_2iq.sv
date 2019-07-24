`timescale 1ns / 1ps

module tw_vgg_2iq
#(
  parameter CH_OUT = 64
) (
input clk,
input rst,
input vld_in,
input [3:0][15:0] data_in,
output vld_out,
output [CH_OUT-1:0][15:0] data_out
);

`include "bn1.sv"
`include "bn2.sv"
`include "bn3.sv"
`include "bn4.sv"
`include "bn5.sv"
`include "bn6.sv"
`include "bn7.sv"

   // window lyr 1
   wire [31:0] 	    w1_in [1:0];
   assign w1_in[1] = data_in[3:2];
   assign w1_in[0] = data_in[1:0];
   wire [31:0] 	    w1_out [3:0];
   wire 	    w1_vld;
   wire [7:0][15:0] window_c1;

   // window lyr 2
   wire 	    w2_vld;
   wire [1023:0]    w2_in [0:0];
   wire [1023:0]     w2_out [2:0];
   wire [191:0][15:0] window_c2;
   wire c2_ser_rst;

   // window lyr 3
   wire w3_vld;
   wire [511:0]     w3_in;
   wire [511:0]     w3_out [2:0];
   wire [191:0][7:0] window_c3;
   wire c3_ser_rst;

   // window lyr 4
   wire w4_vld;
   wire [255:0]     w4_in;
   wire [255:0]     w4_out [2:0];
   wire [191:0][3:0] window_c4;
   wire c4_ser_rst;

   // window lyr 5
   wire w5_vld;
   wire [127:0]     w5_in;
   wire [127:0]     w5_out [2:0];
   wire [191:0][1:0] window_c5;
   wire c5_ser_rst;

   // window lyr 6
   wire w6_vld;
   wire [63:0]     w6_in;
   wire [63:0]     w6_out [2:0];
   wire [191:0]    window_c6;
   wire c6_ser_rst;

   // window lyr 7
   wire w7_vld;
   wire [63:0]     w7_in;
   wire [63:0]     w7_out [2:0];
   wire [191:0]    window_c7;
   wire c7_ser_rst;

   wire [63:0][15:0] bn1_out, bn2_out, bn3_out, bn4_out, bn5_out, bn6_out, bn7_out;
   wire 	     bn1_vld, bn2_vld, bn3_vld, bn4_vld, bn5_vld, bn6_vld, bn7_vld;
   wire [63:0][15:0] mp1_out, mp2_out, mp3_out, mp4_out, mp5_out, mp6_out, mp7_out;
   wire 	     mp1_vld, mp2_vld, mp3_vld, mp4_vld, mp5_vld, mp6_vld, mp7_vld;
   wire [63:0][31:0] mp1_in;
   wire [63:0][15:0] c1_A_out, c1_B_out;
   wire 	     c1_A_vld, c1_B_vld;
   wire [63:0][15:0] c2_out;
   wire 	     c2_vld;
   wire [63:0][7:0]  ts2_out, c3_out;
   wire 	     ts2_vld, c3_vld;
   wire [63:0][3:0]  ts3_out, c4_out;
   wire 	     ts3_vld, c4_vld;
   wire [63:0][1:0]  ts4_out, c5_out;
   wire 	     ts4_vld, c5_vld;
   wire [63:0] 	     ts5_out, c6_out, ts6_out, c7_out;
   wire 	     ts5_vld, c6_vld, ts6_vld, c7_vld;

   // some hackery for when throughput is too low
   wire [63:0][31:0] ts6_in;
   wire 	     ts6_in_vld, w7_vld_sel;
   reg [4:0] 	     w7_cntr;

   always @( posedge clk ) begin
      if ( rst ) begin
	 w7_cntr <= 0;
      end else begin
	 if ( w7_vld ) begin
	    w7_cntr <= w7_cntr + 1;
	 end
      end
   end
   assign w7_vld_sel = w7_vld & (w7_cntr < 16);

   // implement windows
   genvar 	    i;
   generate
   // layer 1
   for ( i = 0; i < 4; i++ ) begin
      assign window_c1[2*i] = w1_out[3-i][15:0];
      assign window_c1[2*i+1] = w1_out[3-i][31:16];
   end
   for ( i = 0; i < 64; i++ ) begin
      assign mp1_in[i] = { c1_A_out[i], c1_B_out[i] };
      // lyr2
      assign w2_in[0][i*16 +: 16] = bn1_out[i];
      assign window_c2[i] = w2_out[2][16*i +: 16];
      assign window_c2[i + 64] = w2_out[1][16*i +: 16];
      assign window_c2[i + 128] = w2_out[0][16*i +: 16];
      // lyr3
      assign w3_in[i*8 +: 8] = ts2_out[i];
      assign window_c3[i] = w3_out[2][8*i +: 8];
      assign window_c3[i + 64] = w3_out[1][8*i +: 8];
      assign window_c3[i + 128] = w3_out[0][8*i +: 8];
      // lyr4
      assign w4_in[i*4 +: 4] = ts3_out[i];
      assign window_c4[i] = w4_out[2][4*i +: 4];
      assign window_c4[i + 64] = w4_out[1][4*i +: 4];
      assign window_c4[i + 128] = w4_out[0][4*i +: 4];
      // lyr5
      assign w5_in[i*2 +: 2] = ts4_out[i];
      assign window_c5[i] = w5_out[2][i*2 +: 2];
      assign window_c5[i + 64] = w5_out[1][i*2 +: 2];
      assign window_c5[i + 128] = w5_out[0][i*2 +: 2];
      // lyr6
      assign w6_in[i] = ts5_out[i];
      assign window_c6[i] = w6_out[2][i];
      assign window_c6[i + 64] = w6_out[1][i];
      assign window_c6[i + 128] = w6_out[0][i];
      // lyr7
      assign ts6_in[i] = { 16'h0, bn6_out[i] };
      assign w7_in[i] = ts6_out[i];
      assign window_c7[i] = w7_out[2][i];
      assign window_c7[i + 64] = w7_out[1][i];
      assign window_c7[i + 128] = w7_out[0][i];
   end
   endgenerate

   // for the dense layers
`include "dense_1.sv"
`include "bnd1.sv"
`include "dense_2.sv"
`include "bnd2.sv"
`include "dense_3.sv"

   wire [1023:0] ts7_in;
   assign ts7_in = bn7_out;
   wire 	 ts7_vld;
   wire [15:0] 	 ts7_out;
   wire [D1_CH-1:0][15:0] d1_out;
   wire 		  d1_vld;
   reg [LOG2_D1_CYC-1:0]  d1_cntr;
   wire [127:0][15:0] bnd1_out;
   wire 	      bnd1_vld;
   wire [2047:0] tsd1_in;
   assign tsd1_in = bnd1_out;
   wire 	 tsd1_vld;
   wire [15:0] 	 tsd1_out;
   wire [D2_CH-1:0][15:0] d2_out;
   wire 		  d2_vld;
   reg [LOG2_D2_CYC-1:0]  d2_cntr;
   wire [127:0][15:0] 	  bnd2_out;
   wire 		  bnd2_vld;
   wire [2047:0] tsd2_in;
   assign tsd2_in = bnd2_out;
   wire 	 tsd2_vld;
   wire [15:0] 	 tsd2_out;
   wire [D3_CH-1:0][15:0] d3_out;
   wire 		  d3_vld;
   reg [LOG2_D3_CYC-1:0]  d3_cntr;
   always @( posedge clk ) begin
      if ( rst ) begin
	 d1_cntr <= 0;
	 d2_cntr <= 0;
	 d3_cntr <= 0;
      end else begin
	 if ( ts7_vld ) begin
	    d1_cntr <= d1_cntr + 1;
	 end
	 if ( tsd1_vld ) begin
	    d2_cntr <= d2_cntr + 1;
	 end
	 if ( tsd2_vld ) begin
	    d3_cntr <= d3_cntr + 1;
	 end
      end
   end

   // set the outputs
   assign vld_out = d3_vld;
   assign data_out = d3_out;

windower
#(
  .NO_CH(32),
  .LOG2_IMG_SIZE(10),
  .THROUGHPUT(2)
) w1 (
.clk(clk),
.rst(rst),
.vld_in(vld_in),
.data_in(w1_in),
.vld_out(w1_vld),
.data_out(w1_out)
);

conv1 c1_A (
.clock(clk),
.reset(rst),
.vld_in(w1_vld),
.in(window_c1[7:2]),
.vld_out(c1_A_vld),
.out(c1_A_out)
);

conv1 c1_B (
.clock(clk),
.reset(rst),
.vld_in(w1_vld),
.in(window_c1[5:0]),
.vld_out(c1_B_vld),
.out(c1_B_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(32)
) mp1 (
.clk(clk),
.rst(rst),
.vld_in(c1_A_vld),
.data_in(mp1_in),
.vld_out(mp1_vld),
.data_out(mp1_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu1 (
.clk(clk),
.rst(rst),
.vld_in(mp1_vld),
.data_in(mp1_out),
.a(bn1_a),
.b(bn1_b),
.vld_out(bn1_vld),
.data_out(bn1_out)
);

windower
#(
  .NO_CH(64*16),
  .LOG2_IMG_SIZE(9),
  .THROUGHPUT(1)
) w2 (
.clk(clk),
.rst(rst),
.vld_in(bn1_vld),
.data_in(w2_in),
.vld_out(w2_vld),
.data_out(w2_out)
);

conv2 c2 (
.clock(clk),
.reset(rst),
.vld_in(w2_vld),
.in(window_c2),
.vld_out(c2_vld),
.out(c2_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(16)
) mp2 (
.clk(clk),
.rst(rst),
.vld_in(c2_vld),
.data_in(c2_out),
.vld_out(mp2_vld),
.data_out(mp2_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu2 (
.clk(clk),
.rst(rst),
.vld_in(mp2_vld),
.data_in(mp2_out),
.a(bn2_a),
.b(bn2_b),
.vld_out(bn2_vld),
.data_out(bn2_out)
);

to_serial
#(
  .NO_CH(64),
  .BW_IN(16),
  .BW_OUT(8)
  ) ts2 (
.clk(clk),
.rst(rst),
.vld_in(bn2_vld),
.data_in(bn2_out),
.vld_out(ts2_vld),
.data_out(ts2_out)
);

windower_serial
#(
  .NO_CH(64*8),
  .LOG2_IMG_SIZE(8),
  .SER_CYC(2)
) w3 (
.clk(clk),
.rst(rst),
.vld_in(ts2_vld),
.data_in(w3_in),
.vld_out(w3_vld),
.data_out(w3_out),
.ser_rst(c3_ser_rst)
);

conv3 c3 (
.clock(clk),
.reset(c3_ser_rst),
.vld_in(w3_vld),
.in(window_c3),
.vld_out(c3_vld),
.out(c3_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(8)
) mp3 (
.clk(clk),
.rst(rst),
.vld_in(c3_vld),
.data_in(c3_out),
.vld_out(mp3_vld),
.data_out(mp3_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu3 (
.clk(clk),
.rst(rst),
.vld_in(mp3_vld),
.data_in(mp3_out),
.a(bn3_a),
.b(bn3_b),
.vld_out(bn3_vld),
.data_out(bn3_out)
);

to_serial
#(
  .NO_CH(64),
  .BW_IN(16),
  .BW_OUT(4)
  ) ts3 (
.clk(clk),
.rst(rst),
.vld_in(bn3_vld),
.data_in(bn3_out),
.vld_out(ts3_vld),
.data_out(ts3_out)
);

windower_serial
#(
  .NO_CH(64*4),
  .LOG2_IMG_SIZE(7),
  .SER_CYC(4)
) w4 (
.clk(clk),
.rst(rst),
.vld_in(ts3_vld),
.data_in(w4_in),
.vld_out(w4_vld),
.data_out(w4_out),
.ser_rst(c4_ser_rst)
);

conv4 c4 (
.clock(clk),
.reset(c4_ser_rst),
.vld_in(w4_vld),
.in(window_c4),
.vld_out(c4_vld),
.out(c4_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(4)
) mp4 (
.clk(clk),
.rst(rst),
.vld_in(c4_vld),
.data_in(c4_out),
.vld_out(mp4_vld),
.data_out(mp4_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu4 (
.clk(clk),
.rst(rst),
.vld_in(mp4_vld),
.data_in(mp4_out),
.a(bn4_a),
.b(bn4_b),
.vld_out(bn4_vld),
.data_out(bn4_out)
);

to_serial
#(
  .NO_CH(64),
  .BW_IN(16),
  .BW_OUT(2)
  ) ts4 (
.clk(clk),
.rst(rst),
.vld_in(bn4_vld),
.data_in(bn4_out),
.vld_out(ts4_vld),
.data_out(ts4_out)
);

windower_serial
#(
  .NO_CH(64*2),
  .LOG2_IMG_SIZE(6),
  .SER_CYC(8)
) w5 (
.clk(clk),
.rst(rst),
.vld_in(ts4_vld),
.data_in(w5_in),
.vld_out(w5_vld),
.data_out(w5_out),
.ser_rst(c5_ser_rst)
);

conv5 c5 (
.clock(clk),
.reset(c5_ser_rst),
.vld_in(w5_vld),
.in(window_c5),
.vld_out(c5_vld),
.out(c5_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(2)
) mp5 (
.clk(clk),
.rst(rst),
.vld_in(c5_vld),
.data_in(c5_out),
.vld_out(mp5_vld),
.data_out(mp5_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu5 (
.clk(clk),
.rst(rst),
.vld_in(mp5_vld),
.data_in(mp5_out),
.a(bn5_a),
.b(bn5_b),
.vld_out(bn5_vld),
.data_out(bn5_out)
);

to_serial
#(
  .NO_CH(64),
  .BW_IN(16),
  .BW_OUT(1)
  ) ts5 (
.clk(clk),
.rst(rst),
.vld_in(bn5_vld),
.data_in(bn5_out),
.vld_out(ts5_vld),
.data_out(ts5_out)
);

windower_serial
#(
  .NO_CH(64),
  .LOG2_IMG_SIZE(5),
  .SER_CYC(16)
) w6 (
.clk(clk),
.rst(rst),
.vld_in(ts5_vld),
.data_in(w6_in),
.vld_out(w6_vld),
.data_out(w6_out),
.ser_rst(c6_ser_rst)
);

conv6 c6 (
.clock(clk),
.reset(c6_ser_rst),
.vld_in(w6_vld),
.in(window_c6),
.vld_out(c6_vld),
.out(c6_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(1)
) mp6 (
.clk(clk),
.rst(rst),
.vld_in(c6_vld),
.data_in(c6_out),
.vld_out(mp6_vld),
.data_out(mp6_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu6 (
.clk(clk),
.rst(rst),
.vld_in(mp6_vld),
.data_in(mp6_out),
.a(bn6_a),
.b(bn6_b),
.vld_out(bn6_vld),
.data_out(bn6_out)
);

to_serial
#(
  .NO_CH(64),
  .BW_IN(32),
  .BW_OUT(1)
  ) ts6 (
.clk(clk),
.rst(rst),
.vld_in(bn6_vld),
.data_in(ts6_in),
.vld_out(ts6_vld),
.data_out(ts6_out)
);

windower_serial
#(
  .NO_CH(64),
  .LOG2_IMG_SIZE(4),
  .SER_CYC(32)
) w7 (
.clk(clk),
.rst(rst),
.vld_in(ts6_vld),
.data_in(w7_in),
.vld_out(w7_vld),
.data_out(w7_out),
.ser_rst(c7_ser_rst)
);

conv7 c7 (
.clock(clk),
.reset(c7_ser_rst),
.vld_in(w7_vld_sel),
.in(window_c7),
.vld_out(c7_vld),
.out(c7_out)
);

maxpool
#(
  .NO_CH(64),
  .BW_IN(16),
  .SER_BW(1)
) mp7 (
.clk(clk),
.rst(rst),
.vld_in(c7_vld),
.data_in(c7_out),
.vld_out(mp7_vld),
.data_out(mp7_out)
);

bn_relu_fp
#(
  .NO_CH(64),
  .BW(16),
  .R_SHIFT(6)
) bn_relu7 (
.clk(clk),
.rst(rst),
.vld_in(mp7_vld),
.data_in(mp7_out),
.a(bn7_a),
.b(bn7_b),
.vld_out(bn7_vld),
.data_out(bn7_out)
);

// flatten to dense layer
to_serial
#(
  .NO_CH(1),
  .BW_IN(1024),
  .BW_OUT(16)
  ) ts7 (
.clk(clk),
.rst(rst),
.vld_in(bn7_vld),
.data_in(ts7_in),
.vld_out(ts7_vld),
.data_out(ts7_out)
);

dense_layer_fp
#(
  .INPUT_SIZE(1),
  .NUM_CYC( D1_CYC ),
  .BW(16),
  .BW_W(2),
  .OUTPUT_SIZE(D1_CH)
) d1 (
.clk(clk),
.rst(rst),
.vld_in(ts7_vld),
.data_in(ts7_out),
.w_vec( dw_1[d1_cntr] ),
.vld_out(d1_vld),
.data_out(d1_out)
);

bn_relu_fp
#(
  .NO_CH(128),
  .BW(16),
  .R_SHIFT(6)
) bn_relu_d1 (
.clk(clk),
.rst(rst),
.vld_in(d1_vld),
.data_in(d1_out),
.a(bnd1_a),
.b(bnd1_b),
.vld_out(bnd1_vld),
.data_out(bnd1_out)
);

to_serial
#(
  .NO_CH(1),
  .BW_IN(2048),
  .BW_OUT(16)
  ) tsd1 (
.clk(clk),
.rst(rst),
.vld_in(bnd1_vld),
.data_in(tsd1_in),
.vld_out(tsd1_vld),
.data_out(tsd1_out)
);

dense_layer_fp
#(
  .INPUT_SIZE(1),
  .NUM_CYC( D2_CYC ),
  .BW(16),
  .BW_W(2),
  .OUTPUT_SIZE(D2_CH)
) d2 (
.clk(clk),
.rst(rst),
.vld_in(tsd1_vld),
.data_in(tsd1_out),
.w_vec( dw_2[d2_cntr] ),
.vld_out(d2_vld),
.data_out(d2_out)
);

bn_relu_fp
#(
  .NO_CH(128),
  .BW(16),
  .R_SHIFT(6)
) bn_relu_d2 (
.clk(clk),
.rst(rst),
.vld_in(d2_vld),
.data_in(d2_out),
.a(bnd2_a),
.b(bnd2_b),
.vld_out(bnd2_vld),
.data_out(bnd2_out)
);

to_serial
#(
  .NO_CH(1),
  .BW_IN(2048),
  .BW_OUT(16)
  ) tsd2 (
.clk(clk),
.rst(rst),
.vld_in(bnd2_vld),
.data_in(tsd2_in),
.vld_out(tsd2_vld),
.data_out(tsd2_out)
);

dense_layer_fp
#(
  .INPUT_SIZE(1),
  .NUM_CYC( D3_CYC ),
  .BW(16),
  .BW_W(16),
  .OUTPUT_SIZE(D3_CH)
) d3 (
.clk(clk),
.rst(rst),
.vld_in(tsd2_vld),
.data_in(tsd2_out),
.w_vec( dw_3[d3_cntr] ),
.vld_out(d3_vld),
.data_out(d3_out)
);

endmodule

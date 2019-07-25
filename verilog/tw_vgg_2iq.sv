`timescale 1ns / 1ps

module tw_vgg_2iq
#(
  parameter BW = 16,
  parameter L2_IMG = 10,
  parameter R_SHIFT = 8,
  parameter CH_OUT = 64
) (
input clk,
input rst,
input vld_in,
input [3:0][BW-1:0] data_in,
output vld_out,
output [CH_OUT-1:0][BW-1:0] data_out
);

`include "bn1.sv"
`include "bn2.sv"
`include "bn3.sv"
`include "bn4.sv"
`include "bn5.sv"
`include "bn6.sv"
`include "bn7.sv"

   // window lyr 1
   localparam W1L2 = $clog2( BW ) + 1;
   localparam W1_BW = 1 << W1L2;
   wire [W1_BW-1:0] 	    w1_in [1:0];
   assign w1_in[1] = data_in[3:2];
   assign w1_in[0] = data_in[1:0];
   wire [W1_BW-1:0] 	    w1_out [3:0];
   wire 	    w1_vld;
   wire [7:0][BW-1:0] window_c1;

   // window lyr 2
   localparam W2L2 = $clog2( BW );
   localparam W2_BW = 1 << W2L2;
   localparam W2_CH = BN1_CH << $clog2( W2_BW );
   wire 	      w2_vld;
   wire [W2_CH-1:0]   w2_in [0:0];
   wire [W2_CH-1:0]   w2_out [2:0];
   wire [3*BN1_CH-1:0][W2_BW-1:0] window_c2;
   wire c2_ser_rst;

   // window lyr 3
   localparam W3_SC_L2 = 1; // number of serial cycles for adders
   localparam W3L2 = $clog2( BW ) - W3_SC_L2 < 0 ? 0 : $clog2( BW ) - W3_SC_L2;
   localparam W3_BW = 1 << W3L2;
   localparam W3_CH = BN2_CH << $clog2( W3_BW );
   wire w3_vld;
   wire [W3_CH-1:0]     w3_in;
   wire [W3_CH-1:0]     w3_out [2:0];
   wire [3*BN2_CH-1:0][W3_BW-1:0] window_c3;
   wire c3_ser_rst;

   // window lyr 4
   localparam W4_SC_L2 = 2;
   localparam W4L2 = $clog2( BW ) - W4_SC_L2 < 0 ? 0 : $clog2( BW ) - W4_SC_L2;
   localparam W4_BW = 1 << W4L2;
   localparam W4_CH = BN3_CH << $clog2( W4_BW );
   wire w4_vld;
   wire [W4_CH-1:0]     w4_in;
   wire [W4_CH-1:0]     w4_out [2:0];
   wire [3*BN3_CH-1:0][W4_BW-1:0] window_c4;
   wire c4_ser_rst;

   // window lyr 5
   localparam W5_SC_L2 = 3;
   localparam W5L2 = $clog2( BW ) - W5_SC_L2 < 0 ? 0 : $clog2( BW ) - W5_SC_L2;
   localparam W5_BW = 1 << W5L2;
   localparam W5_CH = BN4_CH << $clog2( W5_BW );
   wire w5_vld;
   wire [W5_CH-1:0]     w5_in;
   wire [W5_CH-1:0]     w5_out [2:0];
   wire [3*BN4_CH-1:0][W5_BW-1:0] window_c5;
   wire c5_ser_rst;

   // window lyr 6
   localparam W6_SC_L2 = 4;
   localparam W6L2 = $clog2( BW ) - W6_SC_L2 < 0 ? 0 : $clog2( BW ) - W6_SC_L2;
   localparam W6_BW = 1 << W6L2;
   localparam W6_CH = BN5_CH << $clog2( W6_BW );
   wire w6_vld;
   wire [W6_CH-1:0]     w6_in;
   wire [W6_CH-1:0]     w6_out [2:0];
   wire [3*BN5_CH-1:0][W6_BW-1:0] window_c6;
   wire c6_ser_rst;

   // window lyr 7
   localparam W7_SC_L2 = 5;
   localparam W7L2 = $clog2( BW ) - W7_SC_L2 < 0 ? 0 : $clog2( BW ) - W7_SC_L2;
   localparam W7_BW = 1 << W6L2;
   localparam W7_CH = BN6_CH << $clog2( W7_BW );
   wire w7_vld;
   wire [W7_CH-1:0]     w7_in;
   wire [W7_CH-1:0]     w7_out [2:0];
   wire [3*BN6_CH-1:0][W6_BW-1:0] window_c7;
   wire c7_ser_rst;

   wire [BN1_CH-1:0][BW-1:0] bn1_out, mp1_out;
   wire [BN2_CH-1:0][BW-1:0] bn2_out, mp2_out;
   wire [BN3_CH-1:0][BW-1:0] bn3_out, mp3_out;
   wire [BN4_CH-1:0][BW-1:0] bn4_out, mp4_out;
   wire [BN5_CH-1:0][BW-1:0] bn5_out, mp5_out;
   wire [BN6_CH-1:0][BW-1:0] bn6_out, mp6_out;
   wire [BN7_CH-1:0][BW-1:0] bn7_out, mp7_out;
   wire 	     bn1_vld, bn2_vld, bn3_vld, bn4_vld, bn5_vld, bn6_vld, bn7_vld;
   wire 	     mp1_vld, mp2_vld, mp3_vld, mp4_vld, mp5_vld, mp6_vld, mp7_vld;
   wire [BN1_CH-1:0][W1_BW-1:0] mp1_in;
   wire [BN1_CH-1:0][BW-1:0] c1_A_out, c1_B_out;
   wire 		     c1_A_vld, c1_B_vld;
   wire [BN2_CH-1:0][W2_BW-1:0] c2_out;
   wire 			c2_vld;
   wire [BN3_CH-1:0][W3_BW-1:0]  ts2_out, c3_out;
   wire 			 ts2_vld, c3_vld;
   wire [BN4_CH-1:0][W4_BW-1:0]  ts3_out, c4_out;
   wire 			 ts3_vld, c4_vld;
   wire [BN5_CH-1:0][W5_BW-1:0]  ts4_out, c5_out;
   wire 			 ts4_vld, c5_vld;
   wire [BN6_CH-1:0][W6_BW-1:0]  ts5_out, c6_out, ts6_out, c7_out;
   wire 			 ts5_vld, c6_vld, ts6_vld, c7_vld;

   // some hackery for when throughput is too low
   wire [BN7_CH-1:0][31:0] ts6_in;
   wire 	     ts6_in_vld, w7_vld_sel;
   reg [W7_SC_L2-1:0] w7_cntr;

   always @( posedge clk ) begin
      if ( rst ) begin
	 w7_cntr <= 0;
      end else begin
	 if ( w7_vld ) begin
	    w7_cntr <= w7_cntr + 1;
	 end
      end
   end
   assign w7_vld_sel = w7_vld & (w7_cntr < BW);

   // implement windows
   genvar 	    i;
   generate
   // layer 1
   for ( i = 0; i < 4; i++ ) begin
      assign window_c1[2*i] = w1_out[3-i][15:0];
      assign window_c1[2*i+1] = w1_out[3-i][31:16];
   end
   for ( i = 0; i < BN1_CH; i++ ) begin
      assign mp1_in[i] = { c1_A_out[i], c1_B_out[i] };
      // lyr2
      assign w2_in[0][i*W2_BW +: W2_BW] = bn1_out[i];
      assign window_c2[i] = w2_out[2][W2_BW*i +: W2_BW];
      assign window_c2[i + BN1_CH] = w2_out[1][W2_BW*i +: W2_BW];
      assign window_c2[i + 2*BN1_CH] = w2_out[0][W2_BW*i +: W2_BW];
   end
   // lyr3
   for ( i = 0; i < BN2_CH; i++ ) begin
      assign w3_in[i*W3_BW +: W3_BW] = ts2_out[i];
      assign window_c3[i] = w3_out[2][W3_BW*i +: W3_BW];
      assign window_c3[i + BN2_CH] = w3_out[1][W3_BW*i +: W3_BW];
      assign window_c3[i + 2*BN2_CH] = w3_out[0][W3_BW*i +: W3_BW];
   end
   // lyr4
   for ( i = 0; i < BN3_CH; i++ ) begin
      assign w4_in[i*W4_BW +: W4_BW] = ts3_out[i];
      assign window_c4[i] = w4_out[2][W4_BW*i +: W4_BW];
      assign window_c4[i + BN3_CH] = w4_out[1][W4_BW*i +: W4_BW];
      assign window_c4[i + 2*BN3_CH] = w4_out[0][W4_BW*i +: W4_BW];
   end
   // lyr5
   for ( i = 0; i < BN4_CH; i++ ) begin
      assign w5_in[i*W5_BW +: W5_BW] = ts4_out[i];
      assign window_c5[i] = w5_out[2][i*W5_BW +: W5_BW];
      assign window_c5[i + BN4_CH] = w5_out[1][i*W5_BW +: W5_BW];
      assign window_c5[i + 2*BN4_CH] = w5_out[0][i*W5_BW +: W5_BW];
   end
   // lyr6
   for ( i = 0; i < BN5_CH; i++ ) begin
      assign w6_in[i*W6_BW +: W6_BW] = ts5_out[i];
      assign window_c6[i] = w6_out[2][i*W6_BW +: W6_BW];
      assign window_c6[i + BN5_CH] = w6_out[1][i*W6_BW +: W6_BW];
      assign window_c6[i + 2*BN5_CH] = w6_out[0][i*W6_BW +: W6_BW];
   end
   // lyr7
   for ( i = 0; i < BN6_CH; i++ ) begin
      assign ts6_in[i] = { 16'h0, bn6_out[i] };
      assign w7_in[i*W7_BW +: W7_BW] = ts6_out[i];
      assign window_c7[i] = w7_out[2][i*W7_BW +: W7_BW];
      assign window_c7[i + BN6_CH] = w7_out[1][i*W7_BW +: W7_BW];
      assign window_c7[i + 2*BN6_CH] = w7_out[0][i*W7_BW +: W7_BW];
   end
   endgenerate

   // for the dense layers
`include "dense_1.sv"
`include "bnd1.sv"
`include "dense_2.sv"
`include "bnd2.sv"
`include "dense_3.sv"

   wire [BN7_CH*BW-1:0] ts7_in;
   assign ts7_in = bn7_out;
   wire 		ts7_vld;
   wire [D1_IN_SIZE*BW-1:0] ts7_out;
   wire [D1_CH-1:0][BW-1:0] d1_out;
   wire 		    d1_vld;
   reg [LOG2_D1_CYC-1:0]    d1_cntr;
   wire [BND1_CH-1:0][BW-1:0] bnd1_out;
   wire 		      bnd1_vld;
   wire [BND1_CH*BW-1:0]      tsd1_in;
   assign tsd1_in = bnd1_out;
   wire 		      tsd1_vld;
   wire [D2_IN_SIZE*BW-1:0]   tsd1_out;
   wire [D2_CH-1:0][BW-1:0]   d2_out;
   wire 		      d2_vld;
   reg [LOG2_D2_CYC-1:0]      d2_cntr;
   wire [BND2_CH-1:0][BW-1:0] bnd2_out;
   wire 		      bnd2_vld;
   wire [BND2_CH*BW-1:0]      tsd2_in;
   assign tsd2_in = bnd2_out;
   wire 		      tsd2_vld;
   wire [D3_IN_SIZE*BW-1:0]   tsd2_out;
   wire [D3_CH-1:0][BW-1:0]   d3_out;
   wire 		  d3_vld;
   reg [LOG2_D3_CYC-1:0]  d3_cntr;
   always @( posedge clk ) begin
      if ( rst ) begin
	 d1_cntr <= 0;
	 d2_cntr <= 0;
	 d3_cntr <= 0;
      end else begin
	 if ( ts7_vld ) begin
	    if ( d1_cntr == D1_CYC - 1 ) begin
	       d1_cntr <= 0;
	    end else begin
	       d1_cntr <= d1_cntr + 1;
	    end
	 end
	 if ( tsd1_vld ) begin
	    if ( d2_cntr == D2_CYC - 1 ) begin
	       d2_cntr <= 0;
	    end else begin
	       d2_cntr <= d2_cntr + 1;
	    end
	 end
	 if ( tsd2_vld ) begin
	    if ( d3_cntr == D1_CYC - 1 ) begin
	       d3_cntr <= 0;
	    end else begin
	       d3_cntr <= d3_cntr + 1;
	    end
	 end
      end
   end

   // set the outputs
   assign vld_out = d3_vld;
   assign data_out = d3_out;

windower
#(
  .NO_CH(W1_BW),
  .LOG2_IMG_SIZE(L2_IMG),
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
  .NO_CH(BN1_CH),
  .BW_IN(BW),
  .SER_BW(W1_BW)
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
  .NO_CH(BN1_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(W2_CH),
  .LOG2_IMG_SIZE(L2_IMG-1),
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
  .NO_CH(BN2_CH),
  .BW_IN(BW),
  .SER_BW(W2_BW)
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
  .NO_CH(BN2_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(BN2_CH),
  .BW_IN(BW),
  .BW_OUT(W3_BW)
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
  .NO_CH(W3_CH),
  .LOG2_IMG_SIZE(L2_IMG-2),
  .SER_CYC(1 << W3_SC_L2)
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
  .NO_CH(BN3_CH),
  .BW_IN(BW),
  .SER_BW(W3_BW)
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
  .NO_CH(BN3_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(BN3_CH),
  .BW_IN(BW),
  .BW_OUT(W4_BW)
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
  .NO_CH(W4_CH),
  .LOG2_IMG_SIZE(L2_IMG-3),
  .SER_CYC(1 << W4_SC_L2)
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
  .NO_CH(BN4_CH),
  .BW_IN(BW),
  .SER_BW(W4_BW)
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
  .NO_CH(BN4_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(BN4_CH),
  .BW_IN(BW),
  .BW_OUT(W5_BW)
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
  .NO_CH(W5_CH),
  .LOG2_IMG_SIZE(L2_IMG-4),
  .SER_CYC(1 << W5_SC_L2)
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
  .NO_CH(BN5_CH),
  .BW_IN(BW),
  .SER_BW(W5_BW)
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
  .NO_CH(BN5_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(BN5_CH),
  .BW_IN(BW),
  .BW_OUT(W6_BW)
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
  .NO_CH(W6_CH),
  .LOG2_IMG_SIZE(L2_IMG-5),
  .SER_CYC(1 << W6_SC_L2)
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
  .NO_CH(BN6_CH),
  .BW_IN(BW),
  .SER_BW(W6_BW)
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
  .NO_CH(BN6_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .NO_CH(BN6_CH),
  .BW_IN(2*BW),
  .BW_OUT(W7_BW)
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
  .NO_CH(W7_CH),
  .LOG2_IMG_SIZE(L2_IMG-6),
  .SER_CYC(1 << W7_SC_L2)
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
  .NO_CH(BN7_CH),
  .BW_IN(BW),
  .SER_BW(W7_BW)
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
  .NO_CH(BN7_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .BW_IN(BN7_CH*BW),
  .BW_OUT(D1_IN_SIZE*BW)
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
  .INPUT_SIZE(D1_IN_SIZE),
  .NUM_CYC(D1_CYC),
  .BW(BW),
  .BW_W(D1_BW_W),
  .R_SHIFT(D1_SHIFT),
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
  .NO_CH(D1_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .BW_IN(D1_CH*BW),
  .BW_OUT(D2_IN_SIZE*BW)
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
  .INPUT_SIZE(D2_IN_SIZE),
  .NUM_CYC( D2_CYC ),
  .BW(BW),
  .BW_W(D2_BW_W),
  .R_SHIFT(D2_SHIFT),
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
  .NO_CH(D2_CH),
  .BW(BW),
  .R_SHIFT(R_SHIFT)
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
  .BW_IN(D2_CH*BW),
  .BW_OUT(D3_IN_SIZE*BW)
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
  .INPUT_SIZE(D3_IN_SIZE),
  .NUM_CYC( D3_CYC ),
  .BW(BW),
  .BW_W(D3_BW_W),
  .R_SHIFT(D3_SHIFT),
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

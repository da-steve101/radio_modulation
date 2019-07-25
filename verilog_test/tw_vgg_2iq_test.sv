`timescale 1ns / 1ps

module tw_vgg_2iq_test();

   `include "input_hex.sv"
   // `include "conv1_hex.sv"
   // `include "conv1_bn_relu_hex.sv"
   // `include "mp1_hex.sv"
   // `include "conv2_hex.sv"
   // `include "conv2_bn_relu_hex.sv"
   // `include "mp2_hex.sv"
   // `include "conv3_hex.sv"
   // `include "mp3_hex.sv"
   // `include "conv4_hex.sv"
   // `include "mp4_hex.sv"
   // `include "conv5_hex.sv"
   // `include "mp5_hex.sv"
   // `include "conv6_hex.sv"
   // `include "mp6_hex.sv"
   // `include "conv7_hex.sv"
   // `include "mp7_hex.sv"
   // `include "dense_1_hex.sv"
   // `include "dense_1_bn_hex.sv"
   // `include "dense_2_hex.sv"
   // `include "dense_2_bn_hex.sv"
   `include "dense_3_hex.sv"

   reg clk;
   reg rst;
   reg vld_in;
   reg [2*CH_IN-1:0][BW_IN-1:0] data_in;
   wire 		      vld_out;
   wire [CH_OUT-1:0][BW_OUT-1:0] data_out;
   reg [CNTR_BW_IN-2:0] 	 in_cntr;
   localparam CNTR_BW_OUT_TRIM = (( CNTR_BW_OUT - 1 ) < 0 ) ? 0 : CNTR_BW_OUT - 1;
   wire [CNTR_BW_OUT:0] 	 out_cntr_sig;
   reg [CNTR_BW_OUT:0] 		 out_cntr;
   assign out_cntr_sig = (CNTR_BW_OUT == 0) ? 0 : out_cntr[CNTR_BW_OUT_TRIM:0];
   wire [CNTR_BW_IN-1:0] 	 in_cntr_a, in_cntr_b;
   assign in_cntr_a = in_cntr << 1;
   assign in_cntr_b = in_cntr_a + 1;

always @( posedge clk ) begin
   data_in[3:2] <= signal_in[in_cntr_a];
   data_in[1:0] <= signal_in[in_cntr_b];
   if ( rst ) begin
      vld_in <= 0;
      in_cntr <= 0;
      out_cntr <= 0;
   end else begin
      vld_in <= 1;
      in_cntr <= in_cntr + 1;
      if ( vld_out ) begin
	 out_cntr <= out_cntr + 1;
	 if ( data_out != signal_out[out_cntr_sig] ) begin
	    $display( "ASSERTION FAILED: data_out = %h, expected_out = %h", data_out, signal_out[out_cntr_sig] );
	 end else begin
	    $display( "ASSERTION PASSED: data_out = %h, expected_out = %h", data_out, signal_out[out_cntr_sig]);
	 end
	 if ( out_cntr == 2*SIG_LEN_OUT - 1 ) begin
	    $finish;
	 end
      end
   end
end

tw_vgg_2iq
#(
  .BW(BW_IN),
  .L2_IMG(10),
  .R_SHIFT(8),
  .CH_OUT(CH_OUT)
) dut (
.clk(clk),
.rst(rst),
.vld_in(vld_in),
.data_in(data_in),
.vld_out(vld_out),
.data_out(data_out)
);

initial begin
   clk = 1;
   rst = 1;
   #10;
   rst = 0;
end

always begin
   #1;
   clk = !clk;
end

endmodule

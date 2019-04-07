`timescale 1ns / 1ps


module dense_layer_1
(
 input 		clk,
 input 		rst,
 input 		vld_in,
 input [127:0] 	data_in,
 output 	vld_out,
 output [127:0] data_out
);

`include "dense_1_vars.sv"

   reg [8:0] 	cntr_in;
   reg [511:0] 	w_vec;
   reg [383:0] 	data_reg;
   reg [2:0] 	q_vld;
   wire [1:0] 	data_vec;
   wire 	segment_done;
   assign segment_done = ( cntr_in % 64 ) == 0;
   assign data_vec = data_reg[383:382];
   
always @( posedge clk ) begin
   w_vec <= dense_1[cntr_in];
   if ( vld_in ) begin
      data_reg[127:0] <= data_in;
   end
   if ( !q_vld[1] | segment_done ) begin
      data_reg[255:128] <= data_reg[127:0];
   end
   if ( segment_done ) begin
      data_reg[383:256] <= data_reg[255:128];
   end
   if ( !segment_done ) begin
      data_reg[383:256] <= { data_reg[381:256], 2'h0 };
   end
   if ( rst ) begin
      cntr_in <= 0;
      q_vld <= 0;
   end else begin
      if ( vld_in ) begin
	 q_vld[0] <= 1;
      end else if ( segment_done ) begin
	 q_vld[0] <= 0;
      end 
      if ( !q_vld[1] | segment_done ) begin
	 q_vld[1] <= q_vld[0];
      end
      if ( segment_done ) begin
	 q_vld[2] <= q_vld[1];
	 if ( q_vld[1] ) begin
	    cntr_in <= cntr_in + 1;
	 end
      end
      if ( !segment_done ) begin
	 cntr_in <= cntr_in + 1;
      end
   end
end

   localparam integer C_VEC [ 128 ] = { -20, -1, 29, -34, -1, -47, 14, 20, -13, 84, 21, 13, -59, 45, -105, -89, 24, 53, 34, -9, 47, 78, -45, 66, -50, -16, 25, 20, -65, 53, -40, 56, 6, 22, -39, -56, 46, 15, -25, 23, -75, 60, 24, -41, 49, 72, -9, -73, -110, -29, 15, -61, -25, 68, 41, -30, -18, 11, -7, -15, -2, 40, -80, -58, -13, 14, 19, 46, -8, 49, 31, 3, 12, -59, -44, 22, 24, -89, -19, -71, -73, -19, -27, 23, -6, -6, -52, -15, -21, -5, -73, 18, 2, 57, 19, -4, -37, -13, 53, -48, 38, 35, 22, 76, -3, -19, 57, 4, -70, 21, -24, 19, 3, -25, -56, -32, 62, -63, -17, -40, -55, 14, -36, 17, 11, -74, -35, -6 };

dense_layer
  #(
    .INPUT_SIZE(2),
    .NUM_CYC(512),
    .OUTPUT_SIZE(128),
    .C_VEC( C_VEC )
) dense_layer_inst (
   .clk(clk),
   .rst(rst),
   .vld_in(q_vld[2]),
   .data_in(data_vec),
   .w_vec(w_vec),
   .vld_out(vld_out),
   .data_out(data_out)
);

endmodule

`timescale 1ns / 1ps

module dense_layer_2
(
 input 		clk,
 input 		rst,
 input 		vld_in,
 input [127:0] 	data_in,
 output 	vld_out,
 output [127:0] data_out
);

`include "dense_2_vars.sv"

   reg [6:0] 	cntr_in;
   reg [255:0] 	w_vec;
   reg [127:0] 	data_reg;
   wire 	data_vec;
   reg 		d_vld;
   assign data_vec = data_reg[127];
   
always @( posedge clk ) begin
   w_vec <= dense_2[cntr_in];
   if ( vld_in ) begin
      data_reg <= data_in;
   end else begin
      data_reg <= { data_reg[126:0], 1'h0 };
   end
   if ( rst ) begin
      cntr_in <= 0;
      d_vld <= 0;
   end else begin
      d_vld <= vld_in;
      if ( vld_in | cntr_in != 0 ) begin
	 cntr_in <= cntr_in + 1;
      end
   end
end

   localparam integer C_VEC [ 128 ] = { 1, 7, 3, -4, -6, 5, 4, 3, 8, 3, -3, -6, 6, 1, 2, 5, -1, 3, -1, -2, 2, -1, 7, 0, 6, 6, 7, -2, 5, -3, 1, -8, 2, -1, 6, -6, 6, 3, 4, 0, 2, 10, -8, 0, -9, 1, 4, 1, -4, 1, 0, 4, -1, -3, 5, 1, 0, 0, 5, -1, 6, 4, 0, 4, 2, 9, 1, 2, 1, -10, 2, -1, 2, 0, -3, 5, 3, 4, 8, 3, -1, 3, -2, -2, 6, -2, 1, 3, 4, 3, 3, 7, 5, 1, -4, -6, -2, 2, 2, 8, 1, -2, 4, 5, 0, -3, -1, 2, 2, -3, 0, 7, 0, 0, 0, 0, 3, -1, 5, -4, 0, -1, -1, 6, 0, -2, -3, -11 };

dense_layer
  #(
    .INPUT_SIZE(1),
    .NUM_CYC(128),
    .OUTPUT_SIZE(128),
    .C_VEC( C_VEC )
) dense_layer_inst (
   .clk(clk),
   .rst(rst),
   .vld_in(d_vld),
   .data_in(data_vec),
   .w_vec(w_vec),
   .vld_out(vld_out),
   .data_out(data_out)
);

endmodule

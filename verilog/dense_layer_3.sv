`timescale 1ns / 1ps

module dense_layer_3
(
 input 		clk,
 input 		rst,
 input 		vld_in,
 input [127:0] 	data_in,
 output logic 	vld_out,
 output [9:0] data_out [23:0]
);

`include "dense_3_vars.sv"

   reg [6:0] 	cntr_in;
   reg [191:0] 	w_vec;
   reg [127:0] 	data_reg;
   wire 	data_vec;
   reg 		d_vld;
   reg 		d_vld_out;
   assign data_vec = data_reg[127];
   
always @( posedge clk ) begin
   if ( data_vec ) begin
      w_vec <= dense_3[cntr_in];
   end else begin
      w_vec <= 0;
   end
   if ( vld_in ) begin
      data_reg <= data_in;
   end else begin
      data_reg <= { data_reg[126:0], 1'h0 };
   end
   if ( rst ) begin
      cntr_in <= 0;
      d_vld <= 0;
      d_vld_out <= 0;
      vld_out <= 0;
   end else begin
      d_vld <= vld_in;
      if ( d_vld | cntr_in != 0 ) begin
	 cntr_in <= cntr_in + 1;
      end
      d_vld_out <= ( cntr_in == ( 1 << 7 ) - 1 );
      vld_out <= d_vld_out;
   end
end
genvar i;
reg signed [9:0] bias [23:0] = { 1,  0,  0,  1, -2,  0,  0,  0, -5, -4,  0, -1, -2, -1,  1,  2,  0,  1,  1,  1,  0, -3, -2, -4 };
wire signed [9:0] zero;
assign zero = 0;
generate
for ( i = 0; i < 24; i++ ) begin
reg signed [9:0] data_out_reg;
assign data_out[i] = data_out_reg;
always @( posedge clk ) begin
   if ( d_vld ) begin
      data_out_reg <= $signed( bias[i] );
   end else begin
      data_out_reg <= $signed( w_vec[8*(i+1)-1:8*i] ) + $signed( data_out_reg );
   end
end
end
endgenerate
endmodule

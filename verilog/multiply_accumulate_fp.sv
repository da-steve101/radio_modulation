`timescale 1ns / 1ps

module multiply_accumulate_fp
  #(
    parameter LOG2_NO_VECS = 2,
    parameter BW = 16,
    parameter BW_W = 2,
    parameter R_SHIFT = 0,
    parameter NUM_CYC = 32
) (
   input 				     clk,
   input 				     new_sum,
   input [(1 << LOG2_NO_VECS)-1:0][BW-1:0]   data_in,
   input [(1 << LOG2_NO_VECS)-1:0][BW_W-1:0] w_vec,
   output [BW-1:0] 			     data_out
);
localparam LOG2_NO_IN = ( LOG2_NO_VECS - 1 > 0 ) ? LOG2_NO_VECS - 1 : 0;
reg [(1 << LOG2_NO_IN)-1:0][R_SHIFT+BW-1:0] mult_res;
wire [R_SHIFT+BW-1:0] shift_res;
assign data_out = shift_res[R_SHIFT+BW-1:R_SHIFT];
genvar i;
generate
for ( i = 0; i < 1 << LOG2_NO_IN; i++ ) begin
always @( posedge clk ) begin
   if ( LOG2_NO_VECS == 0 ) begin
      mult_res[i] <= $signed( w_vec[0] ) * $signed( data_in[0] );
   end else begin
      mult_res[i] <= $signed( w_vec[2*i] ) * $signed( data_in[2*i] )  + $signed( w_vec[2*i+1] ) * $signed( data_in[2*i+1] );
   end
end
end
endgenerate
reg new_sum_reg;
always @( posedge clk ) begin
   new_sum_reg <= new_sum;
end
pipelined_accumulator
#(
  .IN_BITWIDTH(BW+R_SHIFT),
  .OUT_BITWIDTH(BW+R_SHIFT),
  .LOG2_NO_IN(LOG2_NO_IN)
) accum (
   .clk(clk),
   .new_sum( new_sum_reg ),
   .data_in(mult_res),
   .data_out(shift_res)
);

endmodule

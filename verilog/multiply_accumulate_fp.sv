`timescale 1ns / 1ps

module multiply_accumulate_fp
  #(
    parameter LOG2_NO_VECS = 2,
    parameter BW_IN = 16,
    parameter BW_OUT = 16,
    parameter BW_W = 2,
    parameter R_SHIFT = 0,
    parameter DEBUG_FLAG = 0,
    parameter USE_UNSIGNED_DATA = 0,
    parameter NUM_CYC = 32
) (
   input 				      clk,
   input 				      new_sum,
   input [(1 << LOG2_NO_VECS)-1:0][BW_IN-1:0] data_in,
   input [(1 << LOG2_NO_VECS)-1:0][BW_W-1:0]  w_vec,
   output [BW_OUT-1:0] 			      data_out
);
reg signed [(1 << LOG2_NO_VECS)-1:0][R_SHIFT+BW_OUT-1:0] mult_res;
wire [R_SHIFT+BW_OUT-1:0] shift_res;
assign data_out = shift_res[R_SHIFT+BW_OUT-1:R_SHIFT];
genvar i;
generate
for ( i = 0; i < 1 << LOG2_NO_VECS; i++ ) begin
always @( posedge clk ) begin
   if ( USE_UNSIGNED_DATA ) begin
      mult_res[i] <= $signed( w_vec[i]*data_in[i] );
   end else begin
      mult_res[i] <= $signed( w_vec[i] ) * $signed( data_in[i] );
   end
   if ( DEBUG_FLAG ) begin
      $display( "data_in[%x] = %x, w_vec = %x, mult_res[%x] = %x", i, data_in[i], w_vec, i, mult_res );
   end
end
end
endgenerate
reg new_sum_reg;
always @( posedge clk ) begin
   new_sum_reg <= new_sum;
   if ( DEBUG_FLAG ) begin
      $display( "new_sum = %x, shift_res = %x", new_sum_reg, shift_res );
   end
end
pipelined_accumulator
#(
  .IN_BITWIDTH(R_SHIFT + BW_OUT),
  .OUT_BITWIDTH(R_SHIFT + BW_OUT),
  .LOG2_NO_IN(LOG2_NO_VECS)
) accum (
   .clk(clk),
   .new_sum( new_sum_reg ),
   .data_in(mult_res),
   .data_out(shift_res)
);

endmodule

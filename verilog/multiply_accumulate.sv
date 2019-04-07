`timescale 1ns / 1ps


module multiply_accumulate
  #(
    parameter LOG2_NO_VECS = 2,
    parameter NUM_CYC = 32
) (
   input 			   clk,
   input 			   new_sum,
   input [(1 << LOG2_NO_VECS)-1:0] data_in,
   input [(2 << LOG2_NO_VECS)-1:0] w_vec,
   output [(LOG2_NO_VECS + 2 + $clog2( NUM_CYC )):0] data_out
);
localparam LOG2_NO_IN = ( LOG2_NO_VECS - 1 > 0 ) ? LOG2_NO_VECS - 1 : 0;
reg [(1 << LOG2_NO_IN)-1:0][3:0] mult_res; // can be range (-4,4) so need 4 bits
genvar i;   
generate
for ( i = 0; i < 1 << LOG2_NO_IN; i++ ) begin
always @( posedge clk ) begin
   if ( LOG2_NO_VECS == 0 ) begin
      mult_res[i] <= $signed( w_vec[1:0] * data_in[0] );
   end else begin
      mult_res[i] <= $signed( w_vec[4*i+1:4*i] * data_in[2*i] )  + $signed( w_vec[4*i+3:4*i+2] * data_in[2*i+1] );
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
  .IN_BITWIDTH(4),
  .OUT_BITWIDTH(LOG2_NO_VECS + 2 + $clog2(NUM_CYC)),
  .LOG2_NO_IN(LOG2_NO_IN)
) accum (
   .clk(clk),
   .new_sum( new_sum_reg ),
   .data_in(mult_res),
   .data_out(data_out)
);

endmodule

`timescale 1ns / 1ps

module pipelined_accumulator
#(
  parameter IN_BITWIDTH = 8,
  parameter OUT_BITWIDTH = 10,
  parameter LOG2_NO_IN = 1
) (
   input 					clk,
   input 					new_sum,
   input signed [LOG2_NO_IN:0][IN_BITWIDTH-1:0] data_in,
   output signed [OUT_BITWIDTH-1:0] 		data_out
);

localparam INCR_BW = ( IN_BITWIDTH < OUT_BITWIDTH ) ? IN_BITWIDTH + 1 : IN_BITWIDTH;

genvar i;
generate
if ( LOG2_NO_IN <= 0 ) begin
reg signed [OUT_BITWIDTH-1:0] data_out_reg;
wire signed [OUT_BITWIDTH-1:0] zero;
assign zero = 0;
assign data_out = data_out_reg;
always @( posedge clk ) begin
   if ( new_sum ) begin
      data_out_reg <= $signed( data_in[0] ) + zero;
   end else begin
      data_out_reg <= $signed( data_in[0] ) + $signed( data_out_reg );
   end
end
end else begin
reg signed  [LOG2_NO_IN-1:0][INCR_BW-1:0] intermediate_results;
reg new_sum_reg;
for ( i = 0; i < ( 1 << LOG2_NO_IN ); i = i + 2  ) begin
   always @( posedge clk ) begin
      intermediate_results[i] <= $signed(data_in[i]) + $signed(data_in[i+1]);
   end
end
always @( posedge clk ) begin
   new_sum_reg <= new_sum;
end
pipelined_accumulator
  #(
    .IN_BITWIDTH( INCR_BW ),
    .OUT_BITWIDTH( OUT_BITWIDTH ),
    .LOG2_NO_IN( LOG2_NO_IN - 1 )
    ) summation
    (
     .clk( clk ),
     .new_sum( new_sum_reg ),
     .data_in( intermediate_results ),
     .data_out( data_out )
     );
end
endgenerate   
endmodule

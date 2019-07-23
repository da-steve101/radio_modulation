`timescale 1ns / 1ps

module bn_relu_fp
#(
  parameter NO_CH = 10,
  parameter BW = 12,
  parameter R_SHIFT = 6
) (
   input 			     clk,
   input 			     rst,
   input 			     vld_in,
   input [NO_CH-1:0][BW-1:0] 	     data_in,
   input [NO_CH-1:0][BW+R_SHIFT-1:0] a,
   input [NO_CH-1:0][BW+R_SHIFT-1:0] b,
   output 			     vld_out,
   output [NO_CH-1:0][BW-1:0] 	     data_out
);
   reg [3:0] 		      vld_sr;
   assign vld_out = vld_sr[3];
   always @( posedge clk ) begin
      if ( rst ) begin
	 vld_sr <= 0;
      end else begin
	 vld_sr <= { vld_sr[2:0], vld_in };
      end
   end
   genvar 		      i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 reg signed [BW+R_SHIFT-1:0] mult_i, bias_i;
	 reg signed [BW-1:0] 	     shift_i, relu_i;
	 assign data_out[i] = relu_i;
	 always @( posedge clk ) begin
	    mult_i <= $signed(a[i])*$signed(data_in[i]);
	    bias_i <= mult_i + $signed(b[i] << 4);
	    shift_i <= bias_i[BW+R_SHIFT-1:R_SHIFT];
	    if ( shift_i > 0 ) begin
	       relu_i <= shift_i;
	    end else begin
	       relu_i <= 0;
	    end
	 end
      end
   endgenerate
endmodule

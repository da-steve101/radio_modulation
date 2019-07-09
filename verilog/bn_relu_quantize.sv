`timescale 1ns / 1ps

module bn_relu_quantize
#(
  parameter NO_CH = 10,
  parameter AB_BW = 5,
  parameter AB_FRAC = 4,
  parameter BW_OUT = 3,
  parameter BW_IN = 12
) (
   input 				    clk,
   input 				    rst,
   input 				    vld_in,
   input [NO_CH-1:0][BW_IN-1:0] 	    data_in,
   input [NO_CH-1:0][AB_BW-1:0] 	    a,
   input [NO_CH-1:0][AB_BW-1:0] 	    b,
   input [NO_CH-1:0][BW_IN-1:0] 	    x_min,
   input [NO_CH-1:0][BW_IN-1:0] 	    x_max,
   output 				    vld_out,
   output [NO_CH-1:0][BW_OUT-1:0] 	    data_out
);
   localparam LATENCY = 2;
   reg [NO_CH-1:0][BW_OUT-1:0] 		    bits_out;
   reg [LATENCY-1:0] 			    vld_sr;
   reg [NO_CH-1:0][BW_OUT-1:0] 		    out;
   assign vld_out = vld_sr[LATENCY-1];
   assign data_out = out;
   always @( posedge clk ) begin
      if ( rst ) begin
	 vld_sr <= 0;
      end else begin
	 vld_sr <= { vld_sr[LATENCY-2:0], vld_in };
      end
   end
   genvar 				    i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin:bn_relu
	 reg is_x_max;
	 reg is_x_min;
	 reg [BW_IN-1:0] res;
	 always @( posedge clk ) begin
	    is_x_max <= ( $signed(data_in[i]) >= $signed(x_max[i]) );
	    is_x_min <= ( $signed(data_in[i]) <= $signed(x_min[i]) );
	    res <= ( a[i]*data_in[i] + b[i] );
	    if ( is_x_max ) begin
	       out[i] <= ( 1 << BW_OUT ) - 1;
	    end else if ( is_x_min ) begin
	       out[i] <= 0;
	    end else begin
	       out[i] <= res[(BW_OUT -1 + AB_FRAC):AB_FRAC];
	    end
	 end
      end
   endgenerate

endmodule

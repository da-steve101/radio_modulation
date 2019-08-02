`timescale 1ns / 1ps

module bn_relu_fp
#(
  parameter NO_CH = 10,
  parameter BW_IN = 12,
  parameter BW_OUT = 12,
  parameter BW_A = 12,
  parameter BW_B = 12,
  parameter R_SHIFT = 6,
  parameter MAXVAL = -1,
  parameter DEBUG = 0
) (
   input 			  clk,
   input 			  rst,
   input 			  vld_in,
   input [NO_CH-1:0][BW_IN-1:0]   data_in,
   input [NO_CH-1:0][BW_A-1:0] 	  a,
   input [NO_CH-1:0][BW_B-1:0] 	  b,
   output 			  vld_out,
   output [NO_CH-1:0][BW_OUT-1:0] data_out
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
	 reg signed [BW_IN+BW_A-1:0] mult_i, bias_i;
	 reg signed [BW_OUT-1:0] shift_i, relu_i;
	 reg 			 set_max, set_zero;
	 assign data_out[i] = relu_i;
	 always @( posedge clk ) begin
	    if ( DEBUG ) begin
	       $display( "vld_in = %x, data_in[%x] = %x, a[%x] = %x, b[%x] = %x, mult_i = %x, bias_i = %x, shift_i = %x, relu_i = %x",
			 vld_in, i, data_in[i], i, a[i], i, b[i], mult_i, bias_i, shift_i, relu_i );
	    end
	    mult_i <= $signed( a[i] ) * $signed( data_in[i] );
	    bias_i <= $signed(mult_i) + $signed(b[i]);
	    set_zero <= $signed( bias_i ) < 0;
	    set_max <= $signed( bias_i[BW_IN+BW_A-1:R_SHIFT] ) > MAXVAL;
	    shift_i <= bias_i[BW_OUT+R_SHIFT-1:R_SHIFT];
	    if ( set_zero ) begin
	       relu_i <= 0;
	    end else if ( MAXVAL > 0 & set_max ) begin
	       relu_i <= MAXVAL;
	    end else begin
	       relu_i <= shift_i;
	    end
	 end
      end
   endgenerate
endmodule

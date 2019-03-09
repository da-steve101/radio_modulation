`timescale 1ns / 1ps
/* This module windows the data
 It assumes that after a vld_in signal, the entire image will be sent for 2^(LOG2_IMG_SIZE) cycles
 */
module windower
#(
  parameter WINDOW_SIZE = 3, // only works for 3 and 2
  parameter NO_CH = 2,
  parameter LOG2_IMG_SIZE = 10,
  parameter STRIDE = 1,
  parameter ZERO_PADDING = 1 // width of zero padding used
) (
   input 			       clk,
   input 			       rst,
   input 			       vld_in,
   input [NO_CH-1:0] 		       data_in,
   output 			       vld_out,
   output [NO_CH-1:0] data_out [WINDOW_SIZE-1:0]
);
   reg [NO_CH-1:0]    window_mem [WINDOW_SIZE-1:0];
   reg [LOG2_IMG_SIZE-1:0] 	       cntr;
   reg 				       running;
   reg [1:0] 			       img_fill; // count until window is filled after 2 inputs
   wire [LOG2_IMG_SIZE-1:0] 	       cntr_nxt;
   wire 			       is_last;
   wire 			       is_first;
   wire 			       stride_filter;
   wire [NO_CH-1:0] 		       zero;
   assign zero = 0;
   assign cntr_nxt = cntr + 1;
   assign is_last = ( cntr_nxt == 0 );
   assign is_first = ( cntr == 0 );
   assign stride_filter = ( cntr % STRIDE == 0 );
   if ( ZERO_PADDING ) begin // only pad window size of 3
      assign data_out = is_first ? { zero, window_mem[1:0] } : ( is_last ? { window_mem[2:1], zero } : window_mem ) ;
   end else begin
      assign data_out = window_mem;
   end
   assign vld_out =  running & stride_filter;
   always @( posedge clk )
   begin
      window_mem[0] <= data_in;
      window_mem[WINDOW_SIZE-1:1] <= window_mem[WINDOW_SIZE-2:0];
      if ( rst )
      begin
	 cntr <= 0;
	 img_fill <= 0;
	 running <= 0;
      end
      else begin
	 if ( running ) begin
	    cntr <= cntr_nxt;
	    if ( cntr_nxt == 0 & !vld_in ) begin
	       // this image has finished and the next one isn't ready
	       running <= 0;
	       img_fill <= 0;
	    end
	 end else begin // if not running
	    if ( vld_in ) begin
	       img_fill <= img_fill + 1;
	       if ( img_fill > 0 ) begin
		  running <= 1;
	       end
	    end
	 end
      end
   end
endmodule

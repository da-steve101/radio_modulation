`timescale 1ns / 1ps
/* This module windows the data
 It assumes that after a vld_in signal, the entire image will be sent for 2^(LOG2_IMG_SIZE) cycles
 This windower is used to produce multiple convolutional windows depending on the THROUGHPUT
 */
module windower
#(
  parameter NO_CH = 2,
  parameter LOG2_IMG_SIZE = 10,
  parameter THROUGHPUT = 1 // must be a power of 2
) (
   input 	      clk,
   input 	      rst,
   input 	      vld_in,
   input [NO_CH-1:0]  data_in [THROUGHPUT-1:0],
   output 	      vld_out,
   output [NO_CH-1:0] data_out [THROUGHPUT+1:0]
);
   // throughput = 1 => 3, 3
   // throughput = 2 => 5, 4
   // throughput = 4 => 9, 6
   // throughput = 8 => 17, 10
   parameter NO_MEM = 2*THROUGHPUT;
   reg [NO_CH-1:0]    window_mem [NO_MEM:0];
   reg [LOG2_IMG_SIZE-1:0] 	       cntr;
   reg 				       running;
   reg [1:0] 			       img_fill; // count until window is filled after 2 inputs ( doesn't matter what the throughput is )
   wire [LOG2_IMG_SIZE-1:0] 	       cntr_nxt;
   wire [LOG2_IMG_SIZE-1:0] 	       cntr_filled;
   wire 			       is_last;
   wire 			       is_first;
   wire [NO_CH-1:0] 		       pad_first [THROUGHPUT+1:0];
   wire [NO_CH-1:0] 		       pad_last [THROUGHPUT+1:0];
   wire [NO_CH-1:0]                    no_padding [THROUGHPUT+1:0];
   wire [NO_CH-1:0] 		       zero;
   assign zero = 0;
   assign cntr_nxt = cntr + 1;
   assign cntr_filled = cntr + 2;
   assign is_last = ( cntr_nxt == 0 );
   assign is_first = ( cntr == 0 );
   // implement padding
   assign pad_first = { zero, window_mem[NO_MEM-1:THROUGHPUT-1] };
   assign pad_last = { window_mem[NO_MEM:THROUGHPUT], zero };
   assign no_padding = window_mem[NO_MEM:THROUGHPUT-1];
   assign data_out = is_first ? pad_first : ( is_last ? pad_last : no_padding );
   assign vld_out = running;
   always @( posedge clk )
   begin
      window_mem[THROUGHPUT-1:0] <= data_in[THROUGHPUT-1:0];
      window_mem[NO_MEM:THROUGHPUT] <= window_mem[NO_MEM-THROUGHPUT:0];
      if ( rst )
      begin
	 cntr <= 0;
	 img_fill <= 0;
	 running <= 0;
      end
      else begin
	 if ( running ) begin
	    cntr <= cntr_nxt;
	    if ( cntr_nxt == 0 & ( !vld_in || ( img_fill < 2 )) ) begin
	       // this image has finished and the next one isn't ready
	       running <= 0;
	    end
	    if ( ( cntr_nxt == 0 | cntr_filled == 0 ) & !vld_in ) begin
	       img_fill <= img_fill - 1;
	    end
	 end else begin // if not running
	    cntr <= 0;
	    if ( vld_in ) begin
	       img_fill <= img_fill + 1;
	       if ( img_fill > 0 ) begin
		  running <= 1;
	       end
	    end else begin
	       img_fill <= 0;
	    end
	 end
      end
   end
endmodule

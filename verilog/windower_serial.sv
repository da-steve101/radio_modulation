`timescale 1ns / 1ps
/* This module windows the data
 It assumes that after a vld_in signal, the entire image will be sent for 2^(LOG2_IMG_SIZE) cycles
 This windower is used to produce multiple convolutional windows depending on the THROUGHPUT
 */
module windower_serial
#(
  parameter NO_CH = 2,
  parameter LOG2_IMG_SIZE = 10,
  parameter WINDOW_SIZE = 3, // only works for 3 currently
  parameter SER_CYC = 1 // must be a power of 2
) (
   input 		    clk,
   input 		    rst,
   input 		    vld_in,
   input [NO_CH-1:0] 	    data_in,
   output logic 	    vld_out,
   output logic [NO_CH-1:0] data_out [WINDOW_SIZE-1:0],
   output 		    ser_rst
);
   localparam LOG2_SER = $clog2( SER_CYC );
   reg [NO_CH-1:0] 	    window_mem_a;
   reg [NO_CH-1:0] 	    window_mem_b [SER_CYC-1:0];
   reg [NO_CH-1:0] 	    window_mem_c [SER_CYC-1:0];
   reg [LOG2_IMG_SIZE+LOG2_SER-1:0] cntr;
   reg 				    running;
   reg [LOG2_SER:0] 		    img_fill; // count until window is filled after 2 inputs ( doesn't matter what the throughput is )
   wire [LOG2_IMG_SIZE+LOG2_SER-1:0] cntr_nxt;
   wire [LOG2_IMG_SIZE+LOG2_SER-1:0] cntr_filled;
   wire 			     is_last;
   wire 			     is_first;
   wire [NO_CH-1:0] 		     pad_first [WINDOW_SIZE-1:0];
   wire [NO_CH-1:0] 		     pad_last [WINDOW_SIZE-1:0];
   wire [NO_CH-1:0] 		     no_padding [WINDOW_SIZE-1:0];
   wire [NO_CH-1:0] 		     zero;
   assign zero = 0;
   assign cntr_nxt = cntr + 1;
   assign cntr_filled = cntr + 2;
   assign is_last = ( cntr >= ( 1 << ( LOG2_IMG_SIZE + LOG2_SER ) ) - SER_CYC );
   assign is_first = ( cntr < SER_CYC );
   // implement padding
   assign pad_first = { zero, window_mem_b[SER_CYC-1], window_mem_a };
   assign pad_last = { window_mem_c[SER_CYC-1], window_mem_b[SER_CYC-1], zero };
   assign no_padding = { window_mem_c[SER_CYC-1], window_mem_b[SER_CYC-1], window_mem_a };
   assign ser_rst = cntr[LOG2_SER-1:0] == 0;
   always @( posedge clk )
   begin
      if ( vld_in || ( ( cntr_nxt == 0 | cntr_filled == 0 ) & !vld_in ) ) begin
	 window_mem_a <= data_in;
	 window_mem_b[0] <= window_mem_a;
	 window_mem_b[SER_CYC-1:1] <= window_mem_b[SER_CYC-2:0];
	 window_mem_c[0] <= window_mem_b[SER_CYC-1];
	 window_mem_c[SER_CYC-1:1] <= window_mem_c[SER_CYC-2:0];
	 data_out <= is_first ? pad_first : ( is_last ? pad_last : no_padding );
      end
      if ( rst )
      begin
	 cntr <= 0;
	 img_fill <= 0;
	 running <= 0;
	 vld_out <= 0;
      end
      else begin
	 if ( running ) begin
	    if ( vld_in ) begin
	       cntr <= cntr_nxt;
	    end
	    if ( cntr_nxt == 0 & ( !vld_in || ( img_fill < SER_CYC )) ) begin
	       // this image has finished and the next one isn't ready
	       running <= 0;
	    end
	    if ( ( cntr_nxt == 0 | cntr_filled == 0 ) & !vld_in ) begin
	       img_fill <= img_fill - 1;
	       cntr <= cntr_nxt;
	       vld_out <= 1;
	    end else begin
	       vld_out <= vld_in;
	    end
	 end else begin // if not running
	    vld_out <= 0;
	    cntr <= 0;
	    if ( vld_in ) begin
	       img_fill <= img_fill + 1;
	       if ( img_fill > SER_CYC-1 ) begin
		  running <= 1;
	       end
	    end
	 end
      end
   end
endmodule

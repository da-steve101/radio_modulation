`timescale 1ns / 1ps
/**
 This module does a 1D maxpool
 It can take a serial input with least significant word first as input
 */

module maxpool
#(
  parameter NO_CH = 10,
  parameter BW_IN = 12,
  parameter SER_BW = 4
) (
   input 			  clk,
   input 			  rst,
   input 			  vld_in,
   input [NO_CH-1:0][SER_BW-1:0]  data_in,
   output 			  vld_out,
   output [NO_CH-1:0][BW_IN-1:0] data_out
);
   // compute how many cycles needed for a compare
   localparam BUF_CYC = $rtoi($ceil(2*BW_IN/SER_BW));
   localparam DATA_SIZE = $rtoi(BUF_CYC*SER_BW/2);
   localparam BUF_SIZE = BUF_CYC*SER_BW;
   localparam CNTR_SIZE = $clog2( BUF_CYC );
   localparam LATENCY = 3;
   reg [NO_CH-1:0][BUF_SIZE-1:0]  input_buffer;
   reg [NO_CH-1:0]		  max_flag;
   reg [NO_CH-1:0][BW_IN-1:0] 	  max_x;
   // need to wait until all valids from serial
   reg [CNTR_SIZE-1:0] 		  cntr_vld;
   reg [LATENCY-1:0] 		  vld_sr;
   assign vld_out = vld_sr[LATENCY-1];
   assign data_out = max_x;
   genvar 			  i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 reg [BUF_SIZE-1:0]  dly;
	 always @( posedge clk ) begin
	    if ( vld_in ) begin
	       if ( SER_BW == 2*BW_IN ) begin
		  input_buffer[i] <= data_in[i];
	       end else begin
		  assert (SER_BW <= BW_IN) else $error( "SER_BW = %x must be either 2*BW_IN or <= BW_IN = %x", SER_BW, BW_IN );
		  input_buffer[i][BUF_SIZE-1:BUF_SIZE-SER_BW] <= data_in[i];
		  input_buffer[i][BUF_SIZE-SER_BW-1:0] <= input_buffer[i][BUF_SIZE-1:SER_BW];
	       end
	    end
	    dly <= input_buffer[i];
	    if ( max_flag[i] ) begin
	       max_x[i] <= dly[BW_IN-1+DATA_SIZE:DATA_SIZE];
	    end else begin
	       max_x[i] <= dly[BW_IN-1:0];
	    end
	    max_flag[i] <= $signed( input_buffer[i][BW_IN-1+DATA_SIZE:DATA_SIZE] ) >= $signed( input_buffer[i][BW_IN-1:0] );
	 end
      end
   endgenerate
   always @( posedge clk ) begin
      if ( rst ) begin
	 cntr_vld <= 0;
	 vld_sr <= 0;
      end else begin
	 vld_sr[LATENCY-1:1] <= vld_sr[LATENCY-2:0];
	 if ( vld_in ) begin
	    if ( cntr_vld == BUF_CYC - 1 ) begin
	       cntr_vld <= 0;
	       vld_sr[0] <= 1;
	    end else begin
	       cntr_vld <= cntr_vld + 1;
	       vld_sr[0] <= 0;
	    end
	 end else begin
	    vld_sr[0] <= 0;
	 end
      end
   end

endmodule

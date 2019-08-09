`timescale 1ns / 1ps

module popcount_accumulate
#(
  parameter NO_CH = 64,
  parameter BW_IN = 12,
  parameter BW_OUT = 16,
  parameter CYC_ACC = 4,
  parameter DEBUG_FLAG = 0,
  parameter RSHIFT_CYC = 1
) (
   input 			  clk,
   input 			  rst,
   input 			  vld_in,
   input [NO_CH-1:0][BW_IN-1:0]   data_in,
   output 			  vld_out,
   output [NO_CH-1:0][BW_OUT-1:0] data_out
);
   localparam L2_CYC = $clog2( CYC_ACC );
   localparam LSHIFT = ( CYC_ACC - 1 )*RSHIFT_CYC;
   localparam RSHIFT = RSHIFT_CYC;
   reg [NO_CH-1:0][BW_OUT+LSHIFT-1:0] curr_sums;
   reg [L2_CYC-1:0] 		  cyc_cntr;
   wire 			  start, done;
   reg 				  vld_reg;
   assign vld_out = vld_reg;
   assign start = ( cyc_cntr == 0 );
   assign done = ( cyc_cntr == CYC_ACC - 1 );
   genvar 			  i;
   always @( posedge clk ) begin
      if ( rst ) begin
	 cyc_cntr <= 0;
	 vld_reg <= 0;
      end else begin
	 if ( DEBUG_FLAG ) begin
	    $display( "start = %x, vld_in = %x, done = %x, vld_out = %x, cyc_cntr = %x", start, vld_in, done, vld_out, cyc_cntr );
	 end
	 if ( vld_in ) begin
	    if ( done ) begin
	       cyc_cntr <= 0;
	    end else begin
	       cyc_cntr <= cyc_cntr + 1;
	    end
	 end
	 vld_reg <= done & vld_in;
      end
   end
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 wire [BW_OUT+LSHIFT-1:0] newsum;
	 wire [BW_OUT+LSHIFT-1:0] din;
	 wire [BW_OUT+LSHIFT-1:0] csin;
	 assign din[BW_OUT+LSHIFT-1:LSHIFT] = $signed(data_in[i]);
	 assign din[LSHIFT-1:0] = 0;
	 assign csin[BW_OUT+LSHIFT-RSHIFT-1:0] = curr_sums[i][BW_OUT+LSHIFT-1:RSHIFT];
	 assign csin[BW_OUT+LSHIFT-1:BW_OUT+LSHIFT-RSHIFT] = {RSHIFT{curr_sums[i][BW_OUT+LSHIFT-1]}};
	 assign newsum = start ? din : (din + csin);
	 assign data_out[i] = curr_sums[i][BW_OUT-1:0];
	 always @( posedge clk ) begin
	    if ( vld_in ) begin
	       if ( DEBUG_FLAG && i == 0 ) begin
		  $display( "data_in[%x] = %x, din[%x] = %x, newsum[%x] = %x, curr_sums[%x] = %x", i, data_in[i], i, din, i, newsum, i, curr_sums[i] );
	       end
	       curr_sums[i] <= newsum;
	    end
	 end
      end
   endgenerate
endmodule

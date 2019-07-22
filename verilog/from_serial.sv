`timescale 1ns / 1ps

module from_serial
#(
  parameter NO_CH = 10,
  parameter BW_IN = 8,
  parameter BW_OUT = 2
  )(
    input 			   clk,
    input 			   rst,
    input 			   vld_in,
    input [NO_CH-1:0][BW_IN-1:0]   data_in,
    output 			   vld_out,
    output [NO_CH-1:0][BW_OUT-1:0] data_out
    );
   localparam NO_CYC = int'($ceil(BW_OUT/BW_IN));
   localparam CNTR_BW = $clog2(NO_CYC);
   reg [NO_CH-1:0][BW_OUT-1:0] 	   tmp_in;
   reg [CNTR_BW-1:0] 		   vld_cntr;
   reg 				   vld_reg;
   assign vld_out = vld_reg;
   always @( posedge clk ) begin
      if ( rst ) begin
	 vld_cntr <= 0;
	 vld_reg <= 0;
      end else begin
	 if ( vld_in ) begin
	    vld_cntr <= vld_cntr + 1;
	 end
	 if ( vld_in && vld_cntr == NO_CYC - 1 ) begin
	    vld_reg <= 1;
	 end else begin
	    vld_reg <= 0;
	 end
      end
   end
   genvar 			   i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 assign data_out[i] = tmp_in[i];
	 always @( posedge clk ) begin
	    if ( vld_in ) begin
	       tmp_in[i][BW_OUT-1:BW_OUT-BW_IN] <= data_in[i];
	       tmp_in[i][BW_OUT-BW_IN-1:0] <= tmp_in[i][BW_OUT-1:BW_IN];
	    end
	 end
      end
   endgenerate
endmodule

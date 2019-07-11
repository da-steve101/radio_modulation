`timescale 1ns / 1ps

module to_serial
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
   localparam NO_CYC = $ceil(BW_IN/BW_OUT);
   reg [NO_CH-1:0][BW_IN-1:0] 	   tmp_in;
   reg [NO_CYC-1:0] 		   vld_sr;
   always @( posedge clk ) begin
      if ( rst ) begin
	 vld_sr <= 0;
      end else begin
	 if ( vld_in ) begin
	    vld_sr <= ( 1 << NO_CYC ) - 1;
	 end else begin
	    vld_sr <= ( vld_sr >> 1 );
	 end
      end
   end
   genvar 			   i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 assign data_out[i] = tmp_in[i][BW_OUT-1:0];
	 always @( posedge clk ) begin
	    if ( vld_in ) begin
	       tmp_in[i] <= data_in[i];
	    end else begin
	       tmp_in[i][BW_IN-1-BW_OUT:0] <= tmp_in[i][BW_IN-1:BW_OUT];
	    end
	 end
      end
   endgenerate
endmodule

`timescale 1ns / 1ps

module dense_layer
#(
  parameter INPUT_SIZE = 4,
  parameter NUM_CYC = 512,
  parameter OUTPUT_SIZE = 128,
  parameter integer C_VEC [128] = { -20, -1, 29, -34, -1, -47, 14, 20, -13, 84, 21, 13, -59, 45, -105, -89, 24, 53, 34, -9, 47, 78, -45, 66, -50, -16, 25, 20, -65, 53, -40, 56, 6, 22, -39, -56, 46, 15, -25, 23, -75, 60, 24, -41, 49, 72, -9, -73, -110, -29, 15, -61, -25, 68, 41, -30, -18, 11, -7, -15, -2, 40, -80, -58, -13, 14, 19, 46, -8, 49, 31, 3, 12, -59, -44, 22, 24, -89, -19, -71, -73, -19, -27, 23, -6, -6, -52, -15, -21, -5, -73, 18, 2, 57, 19, -4, -37, -13, 53, -48, 38, 35, 22, 76, -3, -19, 57, 4, -70, 21, -24, 19, 3, -25, -56, -32, 62, -63, -17, -40, -55, 14, -36, 17, 11, -74, -35, -6 }
) (
   input 				clk,
   input 				rst,
   input 				vld_in,
   input [OUTPUT_SIZE*2*INPUT_SIZE-1:0] w_vec,
   input [INPUT_SIZE-1:0] 		data_in,
   output 				vld_out,
   output [OUTPUT_SIZE-1:0] 		data_out
);

   localparam BW = $clog2( NUM_CYC );
   localparam LOG2_NO_VECS = $clog2( INPUT_SIZE );

   reg [OUTPUT_SIZE-1:0] res_out;
   reg [BW-1:0] cntr;
   reg [LOG2_NO_VECS+1:0] vld_sr;
   assign vld_out = vld_sr[LOG2_NO_VECS+1];
   assign data_out = res_out;

   always @( posedge clk ) begin
      if ( rst ) begin
	 cntr <= 0;
	 vld_sr <= 0;
      end else begin
	 if ( vld_in & cntr == 0 ) begin
	    cntr <= 1;
	 end
	 if ( cntr != 0 ) begin
	    cntr <= cntr + 1;
	 end
	 vld_sr <= { vld_sr[LOG2_NO_VECS:0], cntr == NUM_CYC - 1 };
      end
   end

   genvar i;
   generate
      for ( i = 0; i < OUTPUT_SIZE; i++ ) begin
	 wire [LOG2_NO_VECS + 2 + BW:0] tmp_out;
	 multiply_accumulate
	   #(
	     .LOG2_NO_VECS( LOG2_NO_VECS ),
	     .NUM_CYC( NUM_CYC )
	     ) mac (
		.clk(clk),
		.new_sum(cntr == 0 ),
		.w_vec( w_vec[(i+1)*2*INPUT_SIZE-1:i*2*INPUT_SIZE] ),
		.data_in( data_in ),
		.data_out( tmp_out )
		);
	 always @( posedge clk ) begin
	    res_out[i] <= ( $signed(tmp_out) >= $signed(C_VEC[i]) );
	 end
      end
   endgenerate

endmodule

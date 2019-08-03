`timescale 1ns / 1ps

module dense_layer_fp
#(
  parameter INPUT_SIZE = 4,
  parameter NUM_CYC = 512,
  parameter BW_IN = 16,
  parameter BW_OUT = 16,
  parameter BW_W = 16,
  parameter R_SHIFT = 0,
  parameter USE_UNSIGNED_DATA = 0,
  parameter DEBUG_FLAG = 0,
  parameter OUTPUT_SIZE = 128
) (
   input 					clk,
   input 					rst,
   input 					vld_in,
   input [OUTPUT_SIZE-1:0][INPUT_SIZE*BW_W-1:0] w_vec,
   input [INPUT_SIZE-1:0][BW_IN-1:0] 		data_in,
   output 					vld_out,
   output [OUTPUT_SIZE-1:0][BW_OUT-1:0] 	data_out
);
   localparam LOG2_NO_VECS = $clog2( INPUT_SIZE );
   localparam LOG2_CYC = $clog2( NUM_CYC );
   reg [OUTPUT_SIZE-1:0][BW_OUT-1:0] 		res_out;
   reg [LOG2_CYC-1:0] cntr;
   reg [LOG2_NO_VECS+2:0] vld_sr;
   assign vld_out = vld_sr[LOG2_NO_VECS+2];
   assign data_out = res_out;

   always @( posedge clk ) begin
      if ( DEBUG_FLAG ) begin
	 $display( "vld_in = %x, data_in = %x, w_vec = %x", vld_in, data_in, w_vec );
	 $display( "vld_out = %x, data_out = %x", vld_out, data_out );
      end
      if ( rst ) begin
	 cntr <= 0;
	 vld_sr <= 0;
      end else begin
	 if ( vld_in ) begin
	    cntr <= cntr + 1;
	 end
	 vld_sr <= { vld_sr[LOG2_NO_VECS+1:0], cntr == NUM_CYC - 1 };
      end
   end
   genvar i;
   generate
      for ( i = 0; i < OUTPUT_SIZE; i++ ) begin
	 wire [BW_OUT-1:0] tmp_out;
	 wire [INPUT_SIZE-1:0][BW_W-1:0] w_or_zero;
	 assign w_or_zero = vld_in ? w_vec[i] : 0;
	 multiply_accumulate_fp
	   #(
	     .LOG2_NO_VECS( LOG2_NO_VECS ),
	     .BW_IN(BW_IN),
	     .BW_OUT(BW_OUT),
	     .BW_W(BW_W),
	     .R_SHIFT(R_SHIFT),
	     .NUM_CYC( NUM_CYC ),
	     .USE_UNSIGNED_DATA( USE_UNSIGNED_DATA ),
	     .DEBUG_FLAG( DEBUG_FLAG & i == 0 )
	     ) mac (
		.clk(clk),
		.new_sum(cntr == 0 ),
		.w_vec( w_or_zero ),
		.data_in( data_in ),
		.data_out( tmp_out )
		);
	 always @( posedge clk ) begin
	    res_out[i] <= tmp_out;
	 end
      end
   endgenerate

endmodule

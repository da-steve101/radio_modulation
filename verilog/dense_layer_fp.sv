`timescale 1ns / 1ps

module dense_layer_fp
#(
  parameter INPUT_SIZE = 4,
  parameter NUM_CYC = 512,
  parameter BW = 16,
  parameter BW_W = 16,
  parameter OUTPUT_SIZE = 128
) (
   input 					clk,
   input 					rst,
   input 					vld_in,
   input [OUTPUT_SIZE*INPUT_SIZE-1:0][BW_W-1:0] w_vec,
   input [INPUT_SIZE-1:0][BW-1:0] 		data_in,
   output 					vld_out,
   output [OUTPUT_SIZE-1:0][BW-1:0] 		data_out
);
   localparam LOG2_NO_VECS = $clog2( INPUT_SIZE );
   localparam LOG2_CYC = $clog2( NUM_CYC );
   reg [OUTPUT_SIZE-1:0][BW-1:0] res_out;
   reg [LOG2_CYC-1:0] cntr;
   reg [LOG2_NO_VECS+1:0] vld_sr;
   assign vld_out = vld_sr[LOG2_NO_VECS+1];
   assign data_out = res_out;

   always @( posedge clk ) begin
      if ( rst ) begin
	 cntr <= 0;
	 vld_sr <= 0;
      end else begin
	 if ( vld_in ) begin
	    cntr <= cntr + 1;
	 end
	 vld_sr <= { vld_sr[LOG2_NO_VECS:0], cntr == NUM_CYC - 1 };
      end
   end

   genvar i;
   generate
      for ( i = 0; i < OUTPUT_SIZE; i++ ) begin
	 wire [BW-1:0] tmp_out;
	 wire [INPUT_SIZE-1:0][BW_W-1:0] w_or_zero;
	 assign w_or_zero = vld_in ? w_vec[i*INPUT_SIZE +: INPUT_SIZE] : 0;
	 
	 multiply_accumulate_fp
	   #(
	     .LOG2_NO_VECS( LOG2_NO_VECS ),
	     .BW(BW),
	     .BW_W(BW_W),
	     .NUM_CYC( NUM_CYC )
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

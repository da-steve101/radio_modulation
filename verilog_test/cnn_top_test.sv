`timescale 1ns / 1ps

module cnn_top_test
#(
) ();

   reg clk;
   reg rst;
   reg vld_in;
   reg [1:0][7:0] data_in [1:0];
   wire 	  vld_out;
   wire [9:0] 	  data_out [23:0];
   reg [3:0] 	  out_cntr;

   /*
    // input into dense layers
   wire [127:0]   expected_out [8] = { 128'h8f515259842b10daf0a9ec50e9f1d281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9fd15219842b10da70a96450e8d19281, 128'h9f51d259842910daf0a9e416e9d1d281 };
    */
   // dense1 output
   // wire [127:0]   expected_out = 128'h303bc9ef0fbc41d0792f05d84374ca9e;
   // dense2 output
   // wire [127:0]   expected_out = 128'he589a4176481eafb7821f7221100023f;
   // pred output
   wire [9:0] expected_out [23:0] = { 10'h36c, 10'h3a5, 10'h3a9, 10'h364, 10'h31e, 10'h34a, 10'h34c, 10'h358, 10'h387, 10'h3a9, 10'h3a9, 10'h3a5, 10'h39a, 10'h3a1, 10'h3b0, 10'h3af, 10'h3ae, 10'h3ef, 10'h7, 10'h336, 10'h357, 10'h2df, 10'h32f, 10'h2f5 };

always @( posedge clk ) begin
   if ( rst ) begin
      data_in[0] <= 16'h002;
      data_in[1] <= 16'h001;
      vld_in <= 0;
      out_cntr <= 0;
   end else begin
      vld_in <= 1;
      if ( vld_in ) begin
	 data_in[0] <= ( data_in[0] + 2 ) % 64;
	 data_in[1] <= ( data_in[1] + 2 ) % 64;
      end
      if ( vld_out ) begin
	 out_cntr <= out_cntr + 1;
	 if ( data_out != expected_out ) begin
	    $display( "ASSERTION FAILED: data_out = %h, expected_out = %h", data_out[0], expected_out[0] );
	 end else begin
	    $display( "ASSERTION PASSED: data_out = %h, expected_out = %h", data_out[0], expected_out[0]);
	 end
	 if ( out_cntr == 8 ) begin
	    $finish;
	 end
      end
   end
end

cnn_top
#(
  .FILTER_WIDTH(128)
) cnn_top_inst (
.clk(clk),
.rst(rst),
.vld_in(vld_in),
.data_in(data_in),
.vld_out(vld_out),
.data_out(data_out)
);

initial begin
   clk = 1;
   rst = 1;
   #10;
   rst = 0;
end

always begin
   #1;
   clk = !clk;
end

endmodule

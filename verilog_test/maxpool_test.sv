`timescale 1ns / 1ps

module maxpool_test
#(
) ();

   parameter NO_CH = 10;
   parameter BW_IN = 8;
   parameter SER_BW = 16;
   parameter ADDR_BW = $clog2( 2*BW_IN );
   parameter CNTR_BW = $clog2( 2*BW_IN/SER_BW );
   reg clk;
   reg rst;
   reg vld_in;
   reg [NO_CH-1:0][SER_BW-1:0] data_in;
   reg [NO_CH-1:0][2*BW_IN-1:0] all_data = { 16'h900, 16'h801, 16'h702, 16'h603, 16'h504, 16'h405, 16'h306, 16'h207, 16'h108, 16'h9 };
   reg [NO_CH-1:0][BW_IN-1:0] expected_out = { 8'h9, 8'h8, 8'h7, 8'h6, 8'h5, 8'h5, 8'h6, 8'h7, 8'h8, 8'h9 };
   reg [CNTR_BW-1:0] 	      start_cntr;
   wire [NO_CH-1:0][BW_IN-1:0] data_out;
   wire vld_out;
   genvar i;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 always @( posedge clk ) begin
	    data_in[i] <= all_data[i][SER_BW*start_cntr +: SER_BW];
	    $display( "data_out[%x] = %h, vld_out = %h",i, data_out[i], vld_out );
	 end
      end
   endgenerate
   always @( posedge clk ) begin
      $display( "data_in = %h, vld_in = %h", data_in, vld_in );
      if ( rst ) begin
	 start_cntr <= 0;
	 vld_in <= 0;
      end else begin
	 vld_in <= 1;
	 if ( start_cntr == (2*BW_IN/SER_BW) - 1 ) begin
	    start_cntr <= 0;
	 end else begin
	    start_cntr <= start_cntr + 1;
	 end
	 if ( vld_out ) begin // need to wait a cycle for out reg
	    if ( data_out != expected_out ) begin
	       $display( "ASSERTION FAILED: out = %h, expected_out = %h", data_out, expected_out );
	    end else begin
	       $display( "ASSERTION PASSED: out = %h, expected_out = %h", data_out, expected_out );
	    end
	    $finish;
	 end
      end
   end

maxpool
#(
  .NO_CH(NO_CH),
  .BW_IN(BW_IN),
  .SER_BW(SER_BW)
) dut (
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

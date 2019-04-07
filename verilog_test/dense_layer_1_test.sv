`timescale 1ns / 1ps

module dense_layer_1_test ();
   reg clk;
   reg rst;
   reg [62:0] vld_in;
   reg [127:0] data_in;
   wire      vld_out;
   wire [127:0] data_out;
   wire [127:0] expected_out;
   assign expected_out = 128'he5ee530b87f7e611dd9bc94c5348d13b;

genvar i;
generate
   for ( i = 0; i < 32; i++ ) begin
      always @( posedge clk ) begin
	 data_in[4*(32 - i)-1:4*(31 - i)] <= 0; // i % 16;
      end
   end
endgenerate
   
always @( posedge clk ) begin
   if ( rst ) begin
      vld_in <= 1 << 58;
   end else begin
      vld_in <= { vld_in[61:0], vld_in == 0 };
   end
   if ( vld_out ) begin
      if ( data_out != expected_out ) begin
	 $display( "ASSERTION FAILED: data_out = %h, expected_out = %h", data_out, expected_out );
      end else begin
	 $display( "data_out = %h matched", data_out );
      end
   end
end

dense_layer_1 dut
(
   .clk(clk),
   .rst(rst),
   .vld_in(vld_in[62]),
   .data_in(data_in),
   .vld_out(vld_out),
   .data_out(data_out)
);

initial begin
   clk = 1;
   rst = 1;
   data_in = 0;
   #10;
   rst = 0;
   #2200;
   $finish;
end

always begin
   #1;
   clk = !clk;
end

endmodule

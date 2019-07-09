
module bn_relu_quantize_test ();
   parameter NO_CH = 10;
   parameter BW_OUT = 3;
   parameter BW_IN = 12;
   parameter AB_BW = 12;
   parameter AB_FRAC = 4;

   reg clk;
   reg rst;
   reg 					   vld_in;
   reg [NO_CH-1:0][BW_IN-1:0] 		   data_in;
   wire 				   vld_out;
   wire [NO_CH-1:0][BW_OUT-1:0] 	   data_out;
   // AB_FRAC = 4
   wire [NO_CH-1:0][AB_BW-1:0] 		   a;
   assign a = { 12'd7, 12'd7, 12'd7, 12'd7, 12'd7, 12'd7, 12'd7, 12'd7, 12'd7, 12'd7 };
   wire [NO_CH-1:0][AB_BW-1:0] 		   b;
   assign b = { 12'd17, 12'd17, 12'd17, 12'd17, 12'd17, 12'd17, 12'd17, 12'd17, 12'd17, 12'd17 };
   wire [NO_CH-1:0][BW_IN-1:0] 		   x_min;
   assign x_min = { 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095, 12'd4095 };
   wire [NO_CH-1:0][BW_IN-1:0] 		   x_max;
   assign x_max = { 12'd41, 12'd41, 12'd41, 12'd41, 12'd41, 12'd41, 12'd41, 12'd41, 12'd41, 12'd41 };
   genvar 				   i,j;
   generate
      for ( i = 0; i < NO_CH; i++ ) begin
	 always @(posedge clk ) begin
	    if ( vld_out ) begin
	       $display( "data_out[%h] = %h\n", i, data_out[i] );
	    end
	    if ( vld_in ) begin
	       $display( "data_in[%h] = %h\n", i, data_in[i] );
	    end
	 end	    
      end
   endgenerate

always @( posedge clk ) begin
   if ( rst ) begin
      vld_in <= 0;
   end else begin
      if ( vld_in ) begin
	 vld_in <= 0;
	 data_in <= { 12'd0, 12'd0, 12'd0, 12'd0, 12'd0, 12'd0, 12'd0,12'd0,12'd0,12'd0 };
      end else begin
	 vld_in <= 1;
	 data_in <= { 12'd4094, 12'd4095, 12'd0, 12'd1, 12'd2, 12'd3, 12'd4, 12'd5, 12'd6, 12'd7 };
      end
   end      
end
   
bn_relu_quantize
#(
  .NO_CH(NO_CH),
  .BW_OUT(BW_OUT),
  .BW_IN(BW_IN),
  .AB_BW( AB_BW ),
  .AB_FRAC( AB_FRAC )
) dut (
       .clk(clk),
       .rst(rst),
       .vld_in(vld_in),
       .data_in(data_in),
       .a(a),
       .b(b),
       .x_min( x_min ),
       .x_max( x_max ),
       .vld_out(vld_out),
       .data_out(data_out)
);

initial begin
   clk = 1;
   rst = 1;
   vld_in = 0;
   #10;
   rst = 0;
   #100;
   $finish;
end

always begin
   #1;
   clk = !clk;
end

endmodule

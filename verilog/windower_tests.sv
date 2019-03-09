`timescale 1ns / 1ps

module windower_tests
#(
   // supported combos are ( 3, X, X, 1, 1 ) and ( 2, X, X, 2, 0 ) where X is any > 0
   parameter WINDOW_SIZE = 2, // only works for 3 and 2
   parameter NO_CH = 10,
   parameter LOG2_IMG_SIZE = 10,
   parameter STRIDE = 2,
   parameter ZERO_PADDING = 0, // width of zero padding used
   parameter RUN_MODE = 1 // 0 = run continuously, X = run with a gap of ( 2^X - 1 ) cycles
) ();
   reg clk;
   reg rst;
   reg vld_in;
   reg [NO_CH-1:0] data_in;
   wire 	   vld_out;
   wire [NO_CH-1:0] data_out[WINDOW_SIZE-1:0];
   reg [LOG2_IMG_SIZE:0] 	     cntr;
   reg [LOG2_IMG_SIZE-1:0] 	     out_cntr;
   reg [NO_CH-1:0]  window_test[WINDOW_SIZE-1:0];
   reg [RUN_MODE:0] 		     wait_cnt;
   genvar 			     i;

   always @( posedge clk ) begin
      if ( rst ) begin
	 data_in <= 0;
	 vld_in <= 0;
	 cntr <= 0;
	 out_cntr <= 0;
      end else begin
	 if ( cntr < 1024 ) begin
	    cntr <= cntr + 1;
	    vld_in <= 1;
	    wait_cnt <= 0;
	 end else begin
	    if ( RUN_MODE != 0 ) begin
	       vld_in <= 0;
	       wait_cnt <= wait_cnt + 1;
	       if ( wait_cnt >= ( 1 << RUN_MODE ) - 1 ) begin
		  cntr <= 0;
	       end
	    end
	 end
	 if ( vld_in ) begin
	    data_in <= data_in + 1;
	 end
	 if ( vld_out ) begin
	    out_cntr <= out_cntr + 1;
	 end
      end
   end // always @ ( posedge clk )
   generate
      for ( i = 0; i < WINDOW_SIZE; i = i + 1 ) begin:window_init
	 always @( posedge clk ) begin
	    if ( rst ) begin
	       window_test[i] <= WINDOW_SIZE - 1 - ZERO_PADDING - i;
	    end else begin
	       if ( vld_out ) begin
		  window_test[i] <= window_test[i] + STRIDE;
		  if ( data_out[i] != window_test[i] ) begin
		     if ( ( out_cntr == 0 | out_cntr == -1 ) & ZERO_PADDING ) begin
			if ( data_out[i] != 0 ) begin
			   $display("ASSERTION FAILED: data_out[", i ,"] = ", data_out[i], " and should be 0" );
			end
		     end else begin
			$display("ASSERTION FAILED: data_out[", i , "] =", data_out[i], " and should be window_test[", i ,"] =", window_test[i]);
		     end
		  end
	       end
	    end
	 end // always @ ( posedge clk )
      end // block: window_init
   endgenerate


windower #(
	   .WINDOW_SIZE(WINDOW_SIZE),
	   .NO_CH(NO_CH),
	   .STRIDE( STRIDE ),
	   .LOG2_IMG_SIZE(LOG2_IMG_SIZE),
	   .ZERO_PADDING(ZERO_PADDING)
) win_3_pad
(
 .clk( clk ),
 .rst( rst ),
 .vld_in( vld_in ),
 .data_in( data_in ),
 .vld_out( vld_out ),
 .data_out( data_out )
 );

initial begin
   clk = 1;
   rst = 1;
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

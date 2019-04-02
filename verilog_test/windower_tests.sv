`timescale 1ns / 1ps

module windower_tests
#(
  parameter NO_CH = 8,
  parameter LOG2_IMG_SIZE = 7,
  parameter THROUGHPUT = 1,
  parameter RUN_MODE = 1 // 0 = run continuously, X = run with a gap of ( 2^X - 1 ) cycles
) ();
   parameter NO_MEM = 2*THROUGHPUT;
   reg clk;
   reg rst;
   reg vld_in;
   reg [NO_CH-1:0] data_in [THROUGHPUT-1:0];
   wire 	   vld_out;
   wire [NO_CH-1:0] data_out [THROUGHPUT+1:0];
   reg [LOG2_IMG_SIZE:0] 	     cntr;
   reg [LOG2_IMG_SIZE-1:0] 	     out_cntr;
   reg [NO_CH-1:0]  window_test[THROUGHPUT+1:0];
   reg [RUN_MODE:0] 		     wait_cnt;
   genvar 			     i;

   generate
      for ( i = 0; i < THROUGHPUT; i = i + 1 ) begin : data_in_update
	 always @( posedge clk ) begin
	    if ( rst ) begin
	       data_in[i] <= THROUGHPUT - 1 - i;
	    end else begin
	       if ( vld_in ) begin
		  data_in[i] <= data_in[i] + THROUGHPUT;
	       end
	    end
	 end
      end
   endgenerate
   always @( posedge clk ) begin
      if ( rst ) begin
	 vld_in <= 0;
	 cntr <= 0;
	 out_cntr <= 0;
      end else begin
	 if ( cntr < ( 1 << LOG2_IMG_SIZE ) ) begin
	    cntr <= cntr + 1;
	    vld_in <= 1;
	    wait_cnt <= 0;
	 end else begin
	    if ( RUN_MODE != 0 ) begin
	       vld_in <= 0;
	       wait_cnt <= wait_cnt + 1;
	       if ( wait_cnt >= ( 1 << ( RUN_MODE - 1 ) ) - 1 ) begin
		  cntr <= 0;
	       end
	    end
	 end
	 if ( vld_out ) begin
	    out_cntr <= out_cntr + 1;
	 end
      end
   end // always @ ( posedge clk )
   generate
      for ( i = 0; i < THROUGHPUT+2; i = i + 1 ) begin:window_init
	 always @( posedge clk ) begin
	    if ( rst ) begin
	       window_test[i] <= THROUGHPUT - i;
	    end else begin
	       if ( vld_out ) begin
		  window_test[i] <= window_test[i] + THROUGHPUT;
		  if ( i == THROUGHPUT + 1 & out_cntr == 0 ) begin
		     if ( data_out[i] != 0 ) begin
			$display("ASSERTION FAILED: data_out[", out_cntr, ", ", i ,"] = ", data_out[i], " and should be 0 on leading padding" );
		     end
		  end else if ( i == 0 & out_cntr == ( 1 << LOG2_IMG_SIZE ) - 1 ) begin
		     if ( data_out[i] != 0 ) begin
			$display("ASSERTION FAILED: data_out[", out_cntr, ", ", i ,"] = ", data_out[i], " and should be 0 on trailing padding" );
		     end
		  end else if ( data_out[i] != window_test[i] ) begin
		     $display("ASSERTION FAILED: data_out[", out_cntr, ", ", i , "] =", data_out[i], " and should be window_test[", i ,"] =", window_test[i]);
		  end
	       end
	    end
	 end // always @ ( posedge clk )
      end // block: window_init
   endgenerate


windower #(
	   .NO_CH(NO_CH),
	   .LOG2_IMG_SIZE(LOG2_IMG_SIZE),
	   .THROUGHPUT( THROUGHPUT )
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

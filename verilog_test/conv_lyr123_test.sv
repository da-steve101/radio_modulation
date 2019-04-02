`timescale 1ns / 1ps

module conv_lyr123_test
#(
) ();

   reg clk;
   reg rst;
   reg vld_in;
   reg [1:0][7:0] data_in [1:0];
   wire 	  vld_out;
   wire 	  lyr1_vld;
   wire [255:0]   lyr1_data [0:0];
   wire 	  lyr2_vld;
   wire [255:0]   lyr2_data;
   wire [255:0]   data_out;
   reg [3:0] 	  out_cntr;

   wire [255:0]   expected_out [16] = { 256'h4b85e06a1b1939328e12003b3802107902228482f23570233191e8064c060501, 256'h4b05406a031129228a12001b1802006889229420602530a19991880244820001, 256'h0205404a002039228a1a000b1802006c81201420422530a1b9918c0284820001, 256'h0a05804b0820996a8a1a04cb981e027c91a01420422530a9b9b1ae0294021001, 256'h0c85804b0822916b8b1604eb981e2238952014a04225b6f1b9b1ae02b4021600, 256'h2885804b080291638a1600eb181a2228912116a04225b2e1b9b1a70234021200, 256'h8885024a08020120881600cb3a180028832114a00224a2839990a30214021208, 256'h0d95894808068721080704cb7a580018832114a00220b0819994a30204021408, 256'h0d85800800068531200204894a488019822015600041b0c1a910a30a04021400, 256'h1585800821029531200006890a08801902201460024110818910a30a04021400, 256'h158580082102953120001489080800080220346002411081c910a30804021400, 256'h108500082102017920001409090900080220364000411081c8188140040a0420, 256'h118500082103013c20001009080300082020366000500283c818814114080020, 256'h50c500082103013420001019080300082022364020500a83c2188141140800a0, 256'h53c51000a10381b420001219280301482026764420500a82c2188141141802a8, 256'hd3c912780343193a2216101f2c4510690432e7e731402ab08a4a9043549c6229 };

always @( posedge clk ) begin
   if ( rst ) begin
      data_in[0] <= 16'h002;
      data_in[1] <= 16'h001;
      vld_in <= 0;
      out_cntr <= 0;
   end else begin
      vld_in <= 1;
      data_in[0] <= data_in[0] + 2;
      data_in[1] <= data_in[1] + 2;
      if ( vld_out ) begin
	 out_cntr <= out_cntr + 1;
	 if ( data_out != expected_out[out_cntr] ) begin
	    $display( "ASSERTION FAILED: data_out = %h, expected_out = %h", data_out, expected_out[out_cntr] );
	 end
	 if ( out_cntr == 15 ) begin
	    $finish;
	 end
      end
   end
end

lyr1 lyr1_inst
(
.clk(clk),
.rst(rst),
.vld_in(vld_in),
.data_in(data_in),
.vld_out(lyr1_vld),
.data_out(lyr1_data)
);

lyr2 lyr2_inst
(
.clk(clk),
.rst(rst),
.vld_in(lyr1_vld),
.data_in(lyr1_data[0]),
.vld_out(lyr2_vld),
.data_out(lyr2_data)
);

lyr3 lyr3_inst
(
.clk(clk),
.rst(rst),
.vld_in(lyr2_vld),
.data_in(lyr2_data),
.vld_out(vld_out),
.data_out(data_out)
);

initial begin
   clk = 1;
   rst = 1;
   #10;
   rst = 0;
   #50;
   $finish;
end

always begin
   #1;
   clk = !clk;
end

endmodule

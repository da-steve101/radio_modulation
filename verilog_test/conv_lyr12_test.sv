`timescale 1ns / 1ps

module conv_lyr12_test
#(
) ();

   reg clk;
   reg rst;
   reg vld_in;
   reg [1:0][7:0] data_in [1:0];
   wire 	  vld_out;
   wire 	  lyr1_vld;
   wire [255:0]   lyr1_data [0:0];
   wire [255:0]   data_out;
   reg [3:0] 	  out_cntr;

   /*
    python code:
def ary_to_hex( x ):
  hex_str = ""
  for i in range( int( len(x) / 4 ) ):
    total = 0
    for j in range( 4 ):
      total += x[4*i + j] << ( 3 - j )
    hex_str += hex( total )[-1]
  return hex_str

# input_arys = [ np.array( [ i + 4, 0, i + 3, 0, i + 2, 0 ] ) for i in range( 32 ) ]
input_arys = [ np.array( [ 0, i + 2, 0, i + 3, 0, i + 4 ] ) for i in range( 32 ) ]
input_arys[0][1] = 0
res = [ list( reversed( 1*(np.matmul( w, lyr1_w ) >= lyr1_c) ) )  for w in input_arys ]
mp_res = [ [ a | b for a, b in zip( res[2*j], res[2*j+1] ) ] for j in range(16) ]
mp_hex = [ "256'h" + ary_to_hex( x ) for x in mp_res ]
", ".join( mp_hex )
   */
   /*
   wire [255:0]   expected_out [16] = { 256'hc9c8183080801112a6db002500c49da6108c10050bc024368dd401400a11136e, 256'hc9c8183080801116a49b202520c49da6108c100509c024368dd401480a11136e, 256'hc9c8183080801116a40b242520c49da6108c100509c02436add401488a11136e, 256'hc9c8183080801116a50b642520c49ca61088100501802432add0010886111b6e, 256'hc9d8183084901116a50a640520c49ca610891005018024b2add0010886101b6e, 256'hc9d8183084901116850a640520449ca610891005018024b2add0011886101b6e, 256'hc9d8183084901116850a640520449c261089500111802692add0011896101b6e, 256'hc9d818388cb01116850a64052044dc2612894001119026d2add0011896103b6e, 256'hc9d8183a8cb01116850a64052144dc2412994001119426d2add0411c96123b6e, 256'hc9d8183a8cb01117c50a64052144dc24129b4081119426d2add0411c96923b6e, 256'hc9d8183a8cb01137c50a64052144dc24129b408111b426d2add0411cd6923b6e, 256'hc9d9183eccb81137c50a64052144de24129b408115b426d3add2511cd6923b6e, 256'hc9d9593eccb81537c50a64052144de24129b408115b626d3add2511cd6923b6e, 256'hc9d9593eccb81537c50a64052144de24129b408115b626d3add2511cd6923b6e, 256'hc9d9593eccb81537c50a64052144de24129b408115b626d3add2511cd6923b6e, 256'hc9d9593edcb815b5c50a64052144de24129b408115b626d3add2511cd69a3b6e };
    */
   wire [255:0] expected_out [16] = { 256'h7eb87bfce2ea30a27d60276dc8f8fdd2fedb5bbdbc22d0cf873da7c838876a13, 256'h7ef81a6ce2eb30a24d20274d49f8ddb2d6c9528dbc22d0cf973787ca3882aa30, 256'h7ef8184ce0eb34a24520254d49f855b2d7cb528ddc22d0cb973587c83882aa10, 256'h6ee8084ce0eb3422652025cd49f855b2d5cb528ddc22d0c31f7587c81082aa10, 256'h6ee80848e0eb3422652025cd49f855f2d5cbd28ddc22d2c31f7587c81082ea14, 256'h6e280a4ce2eb3420652025cd49f815f2d5cbd28dcc22c2d31b7587cc1082ea15, 256'hee280848e2eb34226520258d49f815f2d5cfd28dcca2c2d31b7187cc1082e815, 256'hee280848a5cb34226520258d49f015f2dd4fd28dc8a202d31971864c12c2e815, 256'hce280848e5c134206530208d48f015f29d47d28dc8a20283197386441282e805, 256'hce280848e5c134206530208d48f015f29d47d28cc8a20283197386441283e905, 256'hce2908c9e5c134206510208d49f015f29d47c28cc8a20283197386441283e905, 256'hce2908c9a5c135206710208d48d017e2bd47c28cc8aa0283997386441283e906, 256'h9c2948c9a5c135226790008f09d017e2bd47c2ac48aa0283996382443283ed07, 256'h982948c9a5c135267790288e09d017e2bf4783ac48aa0283196380453281cd06, 256'h982948c985c135266790288e09c007eabf4783ac48a8028119c3804532c1ed04, 256'h990149d9a5c137067710080e08c0046abb0783ac40a802a119c380450249cc04 };

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

#! /usr/bin/python3

import csv
import sys
import math

'''
no_pos = (2^no_bits) - 1, no_neg = 0
or
no_pos = (2^(no_bits-1)) - 1, no_neg = 2^(no_bits-1)
'''
def get_no_bits_needed( no_pos, no_neg ):
    if no_pos == 0 and no_neg == 0:
        return 0
    return math.ceil( math.log2( max( no_pos + 1, no_neg ) ) ) + 1

'''
int bits(uint32 n)
{
    n = (n & 0x55555555) + ((n >>  1) & 0x55555555);
    n = (n & 0x33333333) + ((n >>  2) & 0x33333333);
    n = (n & 0x0f0f0f0f) + ((n >>  4) & 0x0f0f0f0f); // max 4 but has 4 bits so can remove top bit
    n = (n & 0x00ff00ff) + ((n >>  8) & 0x00ff00ff); // remove top 3
    n = (n & 0x0000ffff) + (n >> 16); // remove top 7
    return n; // remove top 15 bits
}
'''

def make_pattern( pattern_len, lyr_idx ):
    no_ones = ( 1 << lyr_idx )
    total = 0
    for i in range( int( math.ceil( pattern_len/no_ones) ) ):
        total = total << (2*no_ones)
        total += ( 2**no_ones ) - 1
    return total

# this can accumulate 4 bits in one slice
def generate_bitcount_tree( prefix, bitwidth ):
    if bitwidth == 0:
        return ""
    no_lyrs = math.ceil( math.log2( bitwidth ) )
    orig_bw = bitwidth
    all_ones = ( 1 << bitwidth ) - 1
    declare = ""
    for lyr in range( no_lyrs ):
        pattern = make_pattern( orig_bw, lyr )
        # compute the worst case to trim bits
        all_ones = ( all_ones & pattern ) + ( ( all_ones >> ( 1 << lyr ) ) & pattern )
        bitwidth = len(bin(all_ones)) - 2
        # dont need the giant carry chains: find a way to partiion into good blocks for FPGA
        declare += "wire [" + str(bitwidth - 1 ) + ":0] " + prefix + str(lyr + 1) + ";\n"
        declare += "assign " + prefix + str(lyr + 1) + " = "
        declare += "( " + prefix + str(lyr) + " & " + str( pattern ) + " ) + ("
        declare += "( " + prefix + str(lyr) + " >> " + str( 1 << lyr ) + ") & " + str( pattern ) + " );\n"
    assert all_ones == orig_bw, "should compute max bit count correctly: " + str( orig_bw ) + " != " + str( all_ones )
    declare += "wire [" + str(bitwidth-1) + ":0] " + prefix + "res;\n"
    declare += "assign " + prefix + "res = " + prefix + str(no_lyrs) + ";\n"
    return declare, bitwidth

def make_module_header( no_out, pixels_per_cycle, img_size, mod_name ):
    assert no_out == 256, "Currently can only be used with 256"
    module_header = """
module """ + mod_name + """ (
input clk,
input rst,
input vld_in,
input ["""
    input_bw = max( [ ( pixels_per_cycle * 256 ), 256 ] )
    module_header += str( input_bw - 1 ) + ":0] data_in,\n"
    module_header += "output logic vld_out,\n"
    module_header += "output [" + str( no_out - 1) + ":0] data_out\n);\n"
    module_header += "wire [" + str( input_bw - 1 ) + ":0] window_in_data;\n"
    module_header += "wire window_in_vld;\n"
    if pixels_per_cycle < 1:
        # TODO: add a FIFO or some buffer here
        cycles_per_pixel = int( 1 / pixels_per_cycle )
        cntr_bits = math.log2( img_size )
        start_threshold = int( math.ceil( cycles_per_pixel * img_size / ( cycles_per_pixel + 1 ) ) )
        module_header += """
reg [""" + str( cntr_bits + 1 ) + """:0] in_cntr;
reg [""" + str( cntr_bits - 1 ) + """:0] out_cntr;
reg rd_img;
reg start;
wire fifo_vld;
always @( posedge clk ) begin
if ( rst ) begin
  in_cntr <= 0;
  out_cntr <= 0;
  rd_img <= 0;
  start <= 0;
end else begin
  if ( vld_in ) begin
    in_cntr <= in_cntr + 1;
  end else if ( in_cntr >= """ + str( start_threshold ) + """ & out_cntr == 0 ) begin
    out_cntr <= 1;
    rd_img <= 1;
    in_cntr <= in_cntr - start_threshold;
  end else if ( out_cntr == 0 ) begin
    rd_img <= 0;
  end
  if ( out_cntr != 0 ) begin
    out_cntr <= out_cntr + 1;
  end
end
end
fifo_256 (
.clk(clk),
.srst( rst ),
.din( data_in ),
.wr_en( vld_in ),
.rd_en( rd_img ),
.dout( window_in_data ),
.valid( fifo_vld )
);
assign window_in_vld = fifo_vld & rd_img;
"""
        pixels_per_cycle = 1
    else:
        module_header += "assign window_in_data = data_in;\n"
        module_header += "assign window_in_vld = vld_in;\n"
    module_header += """
wire [255:0] pixel_in [""" + str( pixels_per_cycle - 1 ) + """:0];
wire [255:0] window_out_raw [""" + str( pixels_per_cycle + 1 ) + """:0];
wire [""" + str( (pixels_per_cycle + 2)*256 - 1 ) + """:0] window_out_data;
wire window_out_vld;
"""
    # assign packed to unpacked etc
    for i in range( pixels_per_cycle + 2 ):
        t_low = i*256
        t_high = 256*(i+1) - 1
        if i < pixels_per_cycle:
            module_header += "assign pixel_in[" + str(i) + "] = window_in_data[" + str( t_high  ) + ":" + str( t_low ) + "];\n"
        module_header += "assign window_out_data[" + str( t_high ) + ":" + str( t_low ) + "] = window_out_raw[" + str(i) + "];\n"
    module_header += """
windower
#(
  .NO_CH(256),
  .LOG2_IMG_SIZE(""" + str( img_size ) + """),
  .THROUGHPUT(""" + str( pixels_per_cycle ) + """)
) lyr1_window (
   .clk(clk),
   .rst(rst),
   .vld_in( window_in_vld ),
   .data_in( pixel_in ),
   .vld_out( window_out_vld ),
   .data_out( window_out_raw )
);
"""
    return module_header

# method 1) no sharing -> compute using adders
def generate_module_basic( no_pos, no_neg, C ):
    module_header = make_module_header( no_pos, no_neg, 1 )
    if module_header == "":
        return ""
    # first compute the bitcount of pos_bits
    pos_compute, pos_bw = generate_bitcount_tree( "pos_", no_pos )
    module_header += pos_compute
    neg_compute, neg_bw = generate_bitcount_tree( "neg_", no_neg )
    module_header += neg_compute
    # if neg <= -C or pos >= neg + C
    if no_neg <= -C: # then is always true
        module_header += "assign data_out = 1;\n"
    else:
        out_cond = ""
        if C < 0:
            # check if ( neg <= -C )
            out_cond += " ( neg_res <= " + str( -C ) + " ) ? 1 :"
        out_cond += "( pos_res >= neg_res + (" + str( C ) + ") );\n"
        module_header += "assign data_out = " + out_cond
    module_header += "endmodule\n"
    return module_header

def get_name( op_idx, no_inputs ):
    if op_idx == -1:
        return ""
    if op_idx < no_inputs:
        return "data_in[" + str(op_idx) + "]"
    return "tmp_" + str(op_idx)

# method 2) no sharing -> compute using basic adds
def generate_module_add_all( adder_ops, output_idxs, no_inputs, c_vec ):
    # adder_op = [ res_idx, in_idx_a, in_idx_b, op_code ]
    # in_idx is [0 to no_pos-1] for pos inputs, [no_pos to no_pos+no_neg-1] for neg inputs
    # res_idx >= no_pos + no_neg
    # op_code = 0 => ( -a - b )
    # op_code = 1 => ( -a + b )
    # op_code = 2 => ( a - b )
    # op_code = 3 => ( a + b )
    module_header = make_module_header( no_inputs, len(c_vec) )
    total_needed = {}
    for i in range( no_inputs ):
        total_needed[i] = ( 1, 0 )
    for op in adder_ops:
        p_used = total_needed[op[1]][1 - 1*( op[3] >= 2 )]
        n_used = total_needed[op[1]][1*( op[3] >= 2 )]
        if op[2] > -1:
            p_used += total_needed[op[2]][1 - ( op[3] % 2 )]
            n_used += total_needed[op[2]][op[3] % 2]
        total_needed[op[0]] = ( p_used, n_used )
        no_bits = get_no_bits_needed( p_used, n_used )
        add_op = "wire [" + str( no_bits - 1 ) + ":0] tmp_" + str(op[0]) + ";\n"
        op_a = "" if op[3] >= 2 else "- "
        op_b = "+" if op[3] % 2 == 1 else "-"
        add_op += "assign tmp_" + str(op[0]) + " = " + op_a + " $signed(" + get_name( op[1], no_inputs ) + ") "
        arg_b = get_name( op[2], no_inputs )
        if arg_b != "":
            add_op += op_b + " $signed(" + arg_b + ")"
        add_op += ";\n"
        module_header += add_op
    for i, idx in enumerate( output_idxs ):
        output_assign = "assign data_out[" + str(i) + "] = $signed( " + get_name( idx, no_inputs ) + " ) >= $signed( " + str( c_vec[i] ) + ");\n"
        module_header += output_assign
    module_header += "endmodule\n"
    return module_header

def compute_total( total_needed, op_idx, op_code ):
    if op_idx == -1:
        return 0, 0
    p_used = total_needed[op_idx][0]
    n_used = total_needed[op_idx][1]
    if op_code == 1:
        return p_used, n_used
    return n_used, p_used

def get_name_func( prefix, offset ):
    def get_name_pad( op_idx, no_inputs ):
        if op_idx == -1:
            return ""
        if op_idx < no_inputs:
            return "{ 1'h0, window_out_data[" + str( ( no_inputs - 1 - op_idx ) + offset) + "]}"
        return prefix + "op_" + str(op_idx)
    return get_name_pad

def generate_simple_tree( adder_ops, output_idxs, no_inputs, c_vec, prefix, get_name_pad ):
    total_needed = {}
    depth_tracker = {}
    for i in range( no_inputs ):
        total_needed[i] = ( 1, 0 )
        depth_tracker[i] = 0
    declarations = ""
    computations = "always @(posedge clk) begin\n"
    existing_delays = {}
    for op in adder_ops:
        if len( op ) < 3:
            continue
        p_used = 0
        n_used = 0
        for i in range( len(op) - 2 ):
            p_used_s, n_used_s = compute_total( total_needed, op[i+2], ( op[1] >> ( len(op) - 3 - i ) ) & 1 )
            p_used += p_used_s
            n_used += n_used_s
        total_needed[op[0]] = ( p_used, n_used )
        depths = [ depth_tracker[op[i+2]] for i in range( len(op) - 2 ) ]
        depth_tracker[op[0]] = max( depths ) + 1
        last_d = [ get_name_pad( add_idx, no_inputs ) for add_idx in op[2:] ]
        for i, d in enumerate( depths ):
            bw = get_no_bits_needed( total_needed[op[2+i]][0], total_needed[op[2+i]][1] )
            for dly in range( 0, depth_tracker[op[0]] - d - 1 ):
                op_name = prefix + "delay_" + str(op[2+i]) + "_" + str(dly)
                if op_name not in existing_delays:
                    existing_delays[op_name] = True
                    declarations += "reg [" + str(bw-1) + ":0] " + op_name + ";\n"
                    computations += op_name + " <= " + last_d[i] + ";\n"
                last_d[i] = op_name
        no_bits = get_no_bits_needed( p_used, n_used )
        op_name = get_name_pad( op[0], no_inputs )
        declarations += "reg [" + str( no_bits - 1 ) + ":0] " + op_name + ";\n"
        computations += op_name + " <= "
        # pad zeros on the front till no_bits
        op_str = "" # dont need + for first op
        for i, add_idx in enumerate( op[2:] ):
            op_name = last_d[i]
            pad_op_name = "$signed(" + op_name + ")"
            op_code = ( op[1] >> ( len(op) - 3 - i ) ) & 1
            if op_code != 1:
                op_str = " - "
            computations += op_str
            computations += pad_op_name
            op_str = " + "
        computations += ";\n"
    computations += "end\n"
    module_header = declarations
    module_header += computations
    agg_name = prefix + "output_idxs"
    module_header += "reg [" + str( len( output_idxs ) - 1 ) + ":0] " + agg_name + ";\n"
    computations = "always @(posedge clk) begin\n"
    max_depth = max( [ depth_tracker[o] for o in output_idxs ] )
    for i, idx in enumerate( output_idxs ):
      computations += agg_name + "[" + str(i) + "] <= $signed( " + get_name_pad( idx, no_inputs ) + " ) >= $signed( " + str( c_vec[i] ) + ");\n"
    # align all the delays with shift registers
    module_header += "wire [" + str( len( output_idxs ) - 1 ) + ":0] " + agg_name + "_final;\n"
    for i, o in enumerate( output_idxs ):
        dly = max_depth - depth_tracker[o]
        if dly > 0:
            reg_name = agg_name + "_delay_" + str( o )
            module_header += "reg [" + str( dly - 1 ) + ":0] " + reg_name + ";\n"
            module_header += "assign " + agg_name + "_final[" + str( len(output_idxs) - i - 1 ) + "] = " + reg_name + "[" + str( dly - 1 ) + "];\n"
            if dly > 1:
                computations += reg_name + " <= {" + reg_name + "[" + str(dly - 2) + ":0], " + agg_name + "[" + str(i) + "] };\n"
            else:
                computations += reg_name + " <= " + agg_name + "[" + str(i) + "];\n"
        else:
            module_header += "assign " + agg_name + "_final[" + str( len(output_idxs) - i - 1 ) + "] = " + agg_name + "[" + str( i ) + "];\n"
    computations += "end\n"
    module_header += computations
    return module_header, max_depth

def generate_layer_module( pixels_per_cycle, adder_ops, output_idxs, no_inputs, c_vec, prefix = "lyr2_" ):
    module_body = ""
    for i in range( int(math.ceil( pixels_per_cycle )) ):
        prefix_tmp = prefix + str(i) + "_"
        get_name_pad = get_name_func( prefix_tmp, 256*i )
        module_txt, max_depth = generate_simple_tree( adder_ops, output_idxs, no_inputs, c_vec, prefix_tmp, get_name_pad )
        module_body += module_txt
    # set up the valid sr
    module_body += "reg [" + str( max_depth ) + ":0]  vld_sr;"
    module_body += """
wire vld_sr_last;
assign vld_sr_last = vld_sr[""" + str( max_depth ) + """];
always @( posedge clk ) begin
if ( rst ) begin
  vld_sr <= 0;
end else begin
  vld_sr <= { vld_sr[""" + str(max_depth-1) + """:0], window_out_vld };
end
end
"""
    # do the max pool and assign output
    if pixels_per_cycle >= 2:
        # do the max pool in 1 cycle
        module_body += "assign vld_out = vld_sr_last;\n"
        for i in range( int( pixels_per_cycle / 2 ) ):
            mp_a = prefix + str(2*i) + "_output_idxs_final"
            mp_b = prefix + str(2*i + 1) + "_output_idxs_final"
            module_body += "assign data_out[" + str(256*(i+1)-1) + ":" + str(256*i) + "] = " + mp_a + " | " + mp_b + ";\n"
    else:
        # do the max pool with 2 inputs buffering in a reg
        module_body += """
reg [255:0] mp_reg;
reg first_is_in;
reg vld_final;
assign vld_out = vld_final;
assign data_out = mp_reg;
always @( posedge clk ) begin
if ( rst ) begin
  first_is_in <= 0;
  vld_final <= 0;
end else begin
  if ( vld_sr_last ) begin
     if ( first_is_in ) begin
       vld_final <= 1;
       first_is_in <= 0;
     end else begin
       vld_final <= 0;
       first_is_in <= 1;
     end
  end else begin
    vld_final <= 0;
  end
end
if ( vld_sr_last ) begin
   if ( first_is_in ) begin
     mp_reg <= mp_reg | """ + prefix + """0_output_idxs_final;
   end else begin
     mp_reg <= """ + prefix + """0_output_idxs_final;
   end
end
end
"""
    module_body += "endmodule\n"
    return module_body

# method 3) sharing tree -> compute in a tree with minimum number of bits

if __name__ == "__main__":
    pixels_per_cycle = 1
    img_size = 512
    mod_name = "lyr2"
    f = open( sys.argv[1] )
    rdr = csv.reader( f )
    data = [ [ int(x) for x in y ] for y in rdr ]
    output_idxs = data[0]
    adder_ops = data[1:]
    no_inputs = data[1][0]
    f = open( sys.argv[2] )
    rdr = csv.reader( f )
    c_vec = [ [ int(x) for x in y ] for y in rdr ][0]
    module_header = make_module_header( 256, pixels_per_cycle, img_size, mod_name )
    module_txt = generate_layer_module( pixels_per_cycle, adder_ops, output_idxs, no_inputs, c_vec, mod_name + "_" )
    f = open( sys.argv[3], "w" )
    f.write( module_header )
    f.write( module_txt )
    f.close()

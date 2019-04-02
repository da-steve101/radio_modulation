#! /usr/bin/python3

import sys
import csv
import numpy as np
import math

def make_module_header( pixels_per_cycle, input_bw, no_out, module_name = "lyr1" ):
    module_header = """
module """ + module_name + """
(
input clk,
input rst,
input vld_in,
input [1:0][""" + str(input_bw - 1 ) + """:0] data_in [""" + str( pixels_per_cycle - 1 ) + """:0],
output vld_out,
output [""" + str( no_out - 1 ) + ":0] data_out [""" + str( int(pixels_per_cycle/2) - 1 ) + """:0]
);

wire [""" + str( 2*input_bw - 1 ) + """:0] pixel_in [""" + str( pixels_per_cycle - 1 ) + """:0];
wire [""" + str( 2*input_bw - 1 ) + """:0] window_out_raw [""" + str( pixels_per_cycle + 1 ) + """:0];
wire [1:0][""" + str( input_bw - 1 ) + """:0] window_out [""" + str( pixels_per_cycle + 1 ) + """:0];
wire window_vld;
assign pixel_in = data_in;
assign window_out = window_out_raw;

windower
#(
  .NO_CH(""" + str( input_bw*2 ) + """),
  .LOG2_IMG_SIZE(""" + str( 10 - int(math.log2( pixels_per_cycle ))) + """),
  .THROUGHPUT(""" + str( pixels_per_cycle ) + """)
) lyr1_window (
   .clk(clk),
   .rst(rst),
   .vld_in(vld_in),
   .data_in( pixel_in ),
   .vld_out( window_vld ),
   .data_out( window_out_raw )
);
"""
    return module_header

def compute_conv( input_bw, ops, output_idxs, c_vec, get_name, out_name ):
    # each layer add another bit
    total_bits = {}
    depths = {}
    no_inputs = ops[0][0]
    for i in range( no_inputs ):
        total_bits[i] = input_bw
        depths[i] = 0
    total_bits[-1] = 0
    declarations = "wire [" + str( len(output_idxs) - 1 ) + ":0] " + out_name +";\n"
    assignations = ""
    computations = ""
    for op in ops:
        no_ops = len([ x for x in op[1:4] if x != -1 ])
        op_code = op[4]
        op_name = get_name( op[0], no_inputs )
        depths[op[0]] = depths[op[1]] + 1
        if no_ops == 1:
            in_name_A = get_name( op[1], no_inputs )
            in_bw = total_bits[ op[1] ]
            total_bits[ op[0] ] = in_bw
            declarations += "reg [" + str( in_bw - 1 ) + ":0] " + op_name  + ";\n"
            computations += op_name + " <= "
            if ( op_code >> 2 ) % 2 == 0:
                computations += "- "
            computations += in_name_A + ";\n"
        else:
            total_bits[ op[0] ] = max( [ total_bits[ op_i ] for op_i in op[1:4] ] ) + 1
            in_bw = total_bits[ op[0] ]
            declarations += "reg [" + str( in_bw - 1 ) + ":0] " + op_name + ";\n"
            sign = ""
            computations += op_name + " <= "
            for i in range( no_ops ):
                in_name = get_name( op[i+1], no_inputs )
                in_bw = total_bits[ op[i+1] ]
                if ( op_code >> ( 2 - i ) ) % 2 == 0:
                    sign = " - "
                computations += sign + "$signed(" + in_name + ")"
                sign = " + "
            computations += ";\n"
    max_d = max([depths[i] for i in depths ] )
    for i, c, o in zip( range( len(output_idxs) ), c_vec, output_idxs ):
        op_name = get_name( o, no_inputs )
        mod_idx = len(output_idxs) - 1 - i
        if op_name == "":
            assignations += "assign " + out_name + "[" + str(mod_idx) + "] = " + str( 1*(0 >= c)) + ";\n"
        else:
            op_name_base = op_name
            op_computation = "( $signed( " + op_name + " ) >= $signed( " + str( c ) + " ) );\n"
            for j in range( max_d - depths[o] ):
                op_name = op_name_base + "_" + str(j)
                declarations += "reg " + op_name + ";\n"
                computations += op_name + " <= " + op_computation
                op_computation = op_name + ";\n"
            assignations += "assign " + out_name + "[" + str(mod_idx ) + "] = " + op_computation
    total_txt = declarations + assignations
    total_txt += "always @( posedge clk ) begin\n"
    total_txt += computations
    total_txt += "end\n"
    return total_txt

def get_name_func( prefix, offset ):
    def get_name( op_idx, no_inputs ):
        if op_idx < 0:
            return ""
        if op_idx < no_inputs:
            op_idx_trans = no_inputs - 1 - op_idx
            op_idx_iq = str( op_idx_trans % 2 )
            return "window_out[" + str( int(op_idx_trans/2) + offset ) + "][" + op_idx_iq + "]"
        return prefix + "_op_" + str( op_idx )
    return get_name


def get_max_depth( ops, output_idxs ):
    depths = {}
    for i in range( ops[0][0] ):
        depths[i] = 0
    for op in ops:
        depths[op[0]] = depths[op[1]] + 1
    return max([ depths[i] for i in depths ])

def make_conv_mp( pixels_per_cycle, input_bw, ops, output_idxs, c_vec ):
    reg_depth = get_max_depth( ops, output_idxs ) + 3
    module_body = ""
    for i in range( pixels_per_cycle ):
        get_name = get_name_func( "lyr1_" + str(i), i )
        out_name = "lyr1_" + str(i) + "_output"
        module_body += compute_conv( input_bw, ops, output_idxs, c_vec, get_name, out_name )
    # do the max pooling
    declarations = "reg [" + str(reg_depth - 1) + ":0] vld_sr;\n"
    declarations += "assign vld_out = vld_sr[" + str( reg_depth - 1) + "];\n"
    computations = ""
    for i in range( int( pixels_per_cycle / 2 ) ):
        declarations += "reg [" + str( len(output_idxs) - 1 ) + ":0] mp_" + str(i) + ";\n"
        computations += "mp_" + str(i) + " <= lyr1_" + str(2*i) + "_output | lyr1_" + str(2*i + 1) + "_output;\n"
    module_body += declarations
    module_body += "always @( posedge clk ) begin\n"
    # note: if throughput is less than 2 this is going to break
    module_body += "if ( rst ) begin \nvld_sr <= 0;\nend else begin\n"
    module_body += "vld_sr <= { vld_sr[" + str(reg_depth - 2) + ":0], vld_in };\n"
    module_body += "end\n"
    module_body += computations
    module_body += "end\n"
    # finally get the output
    for i in range( int( pixels_per_cycle / 2 ) ):
        module_body += "assign data_out[" + str(i) + "] = mp_" + str(i) + ";\n"
    module_body += "endmodule\n"
    return module_body

if __name__ == "__main__":
    pixels_per_cycle = 2
    input_bw = 8
    fname_w = sys.argv[1]
    fname_c = sys.argv[2]
    with open( fname_w ) as f:
        rdr = csv.reader( f )
        ops = [ [ int(x) for x in y ] for y in rdr ]
    output_idxs = ops[0]
    ops = ops[1:]
    with open( fname_c ) as f:
        rdr = csv.reader( f )
        c_vec = np.array([ [ float(x) for x in y ] for y in rdr ][0])
    c_vec = np.ceil( c_vec * ( 1 << ( input_bw - 2 ) ) ).astype( int )
    f = open( sys.argv[3], "w" )
    module_txt = make_module_header( pixels_per_cycle, input_bw, len(output_idxs) )
    f.write( module_txt )
    module_txt = make_conv_mp( pixels_per_cycle, input_bw, ops, output_idxs, c_vec )
    f.write( module_txt )
    f.close()

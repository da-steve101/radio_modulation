
import csv
import argparse

def make_module_header( module_name, no_inputs, no_outputs ):
    header = ""
    header += "module " + module_name + "(\n"
    header += "input clk,\n"
    header += "input rst,\n"
    header += "input[" + str( no_inputs - 1 ) + ":0] conv_in,\n"
    header += "output[" + str( no_outputs - 1 ) + ":0][7:0] conv_out\n"
    header += ");\n"
    header += "reg[" + str( no_inputs - 1 ) + ":0] conv_in_reg;\n"
    header += "reg[" + str( no_outputs - 1 ) + ":0][7:0] conv_out_reg;\n"
    header += "assign conv_out = conv_out_reg;\n"
    header += "always @( posedge clk ) begin\n"
    header += "conv_in_reg <= conv_in;\n"
    header += "end"
    return header

def get_var_name( idx, no_inputs ):
    if int( idx ) < no_inputs:
        return "conv_in_reg[" + idx + "]", False
    return "tmp_" + idx, True

def build_conv( no_inputs, ops, f ):
    # just build full combinational first ...
    for op in ops:
        out_name, declare = get_var_name( op[0], no_inputs )
        if declare:
            f.write( "wire signed [7:0] " + out_name + ";\n" )
        op_1_name, _ = get_var_name( op[1], no_inputs )
        op_2_name, _ = get_var_name( op[2], no_inputs )
        # op_3_name = get_var_name( op[3] )
        op_type = int(op[4])
        f.write( "assign " + out_name + " = " )
        if op_type < 4:
            f.write( " - " + op_1_name )
        else:
            f.write( op_1_name )
        if int( op[2] ) >= 0:
            if op_type % 2 == 0:
                f.write( " - " + op_2_name )
            else:
                f.write( " + " + op_2_name )
        f.write( ";\n" )
        
def make_mp_bn_relu_block( a, b, suffix, input_ary_0, input_ary_1 ):
    '''
    do the max pool by comparing two values x and y, z = max( x, y )
    then determine if is above the threshold based on a and b
    output = ( a * z + b >= 0 )
    z >= (-b/a) # as a > 0
    c = -b/a
    max( x >= c, y >= c )
    output = ( x >= c ) | ( y >= c ) # only need to compare top bits?
    '''
    c = int( math.ceil( -b/a ) )
    output_str = "wire mp_bn_relu_res_" + suffix + ";\n"
    output_str += "assign mp_bn_relu_res_" + suffix + " = ( " +
    input_ary_0 + " >= " + str( c ) + " ) | ( " +
    input_ary_1 + " >= " + str( c ) + " );\n"
    return output_str

def aggregate_outputs( no_inputs, outputs, f ):
    f.write( "always @( posedge clk ) begin\n" )
    for i, idx in enumerate( outputs ):
        if int( idx ) < 0:
            f.write( "conv_out_reg[" + str(i) + "] <= 0;\n" )
        else:
            var_name, _ = get_var_name( idx, no_inputs )
            f.write( "conv_out_reg[" + str(i) + "] <= " + var_name + ";\n" )
    f.write( "end\n" )

def build_module( csv_ops, module_name ):
    outputs = csv_ops[0]
    no_inputs = int( csv_ops[1][0] )
    header = make_module_header( module_name, no_inputs, len(outputs) )
    f = open( module_name + ".v", "w" )
    f.write( header )
    build_conv( no_inputs, csv_ops[1:], f )
    aggregate_outputs( no_inputs, outputs, f )
    f.write( "endmodule\n" )
    f.close()

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument( "--input_file", type = str, required = True,
                         help="CSV to get the structure from")
    parser.add_argument( "--output_name", type = str, required = True,
                         help = "Filename to output the verilog" )
    return parser.parse_args()    

if __name__ == "__main__":
    args = get_args()
    f = open( args.input_file )
    rdr = csv.reader( f )
    ops = [ x for x in rdr ]
    module_name = args.output_name.split( ".v" )[0]
    build_module( ops, module_name )

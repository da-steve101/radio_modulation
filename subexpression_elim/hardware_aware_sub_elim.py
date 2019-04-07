#! /usr/bin/python3

import csv
import numpy as np
import sys
import math

'''
# can group a set of seven bits in a slice ( 7 => 4 )
# can group 3 into 2 bits in a LUT6_2 if all same sign
# can group 2 into 2 bits in a LUT6_2 if different sign
# can add 3 groups of numbers in next layer if max 15 pos and 6 neg in a slice
'''

'''
Algorithm:
First Layer:
  Search for all common sets of 7 bits
  Search for all groups of 3 with same sign
  Search for groups of 2
  Group the rest in 3 or 2
  Keep track of the number of pos and negative
Second Layer:
  Add with ternary adds if all of one sign or <= 15 pos and <= 16 neg
  Otherwise two input adds with CARRY4 block
Third Layer onwards:
  Still try to group the same sign with 3 for ternary adds
  Otherwise 2 input adds
'''

def implement_lyr1_op( no_in, op_cntr, op_code, input_idxs ):
    assert sum([ x < no_in for x in input_idxs ]) == len( input_idxs ), "Can only be used in first layer"
    no_ops = len(input_idxs)
    if no_ops < 7:
        # pass all into one op
        op = [ op_cntr] + input_idxs + [ -1 ]*(6 - no_ops) + [ op_code ]
        op_cntr += 1
        return op_cntr, [ op ]
    ops = []
    while len( input_idxs ) > 0:
        op_cntr, ops_new = implement_lyr1_op( no_in, op_cntr, op_code & (( 1 << 6 ) - 1), input_idxs[:6] )
        ops += ops_new
        input_idxs = input_idxs[6:]
        op_code = op_code >> 6
    return op_cntr, ops

def count_inputs( weights_vec ):
    return np.sum( np.abs( weights_vec ) )

def duplicate_sub_expr( weights_tree, no_in = 384, no_out = 128 ):
    get_idxs = [ i for i in range( weights_tree.shape[1] ) if count_inputs( weights_tree[:no_in,i] ) > 0 ]
    sd = weights_tree.shape[0]-weights_tree.shape[1]
    # check amount of reuse => if low reuse and small number of bits then push down into next layer
    reuse = [ ( i, count_inputs( weights_tree[sd+i,:] )) for i in get_idxs if count_inputs( weights_tree[no_in:,i] ) == 0 and i >= no_out  ]
    push_down_idxs = [ i for i, r in reuse if r == 2 ]
    for idx in push_down_idxs:
        to_change = np.where( weights_tree[idx+sd,:] != 0 )[0]
        weights_vec = weights_tree[:,idx]
        no_inputs = count_inputs( weights_vec )
        for i in to_change:
            no_blocks = math.ceil( count_inputs( weights_tree[:no_in,i] ) / 6 )
            if math.ceil( (no_inputs + count_inputs( weights_tree[:no_in,i] )) / 6 ) == no_blocks:
                # push the weights down
                sign = weights_tree[idx+sd,i]
                weights_tree[idx+sd,i] = 0
                weights_tree[:,i] = weights_tree[:,i] + sign*weights_vec
        # if no longer used, remove that row
        if count_inputs( weights_tree[idx+sd,:] ) == 0:
            weights_tree[:,idx] = 0
    return weights_tree

def make_first_layer( weights_tree ):
    # take the weights tree from subexpression elim and generate a better tree
    weights_tree = duplicate_sub_expr( weights_tree )
    get_idxs = [ i for i in range( weights_tree.shape[1] ) if count_inputs( weights_tree[:384,i] ) > 0 ]
    op_cntr = 384
    ops = []
    mapping = {}
    for idx in get_idxs:
        pos_idx = np.where( weights_tree[:384,idx] == 1 )[0]
        neg_idx = np.where( weights_tree[:384,idx] == -1 )[0]
        input_idxs = np.concatenate( [ pos_idx, neg_idx ] ).tolist()
        op_code = ( ( 1 << len( pos_idx ) ) - 1 ) << len( neg_idx )
        mapping[idx] = op_cntr
        op_cntr, new_ops = implement_lyr1_op( no_in, op_cntr, op_code, input_idxs )
        mapping[idx] = list( range( mapping[idx], op_cntr ) ) # may have more than one op so get range
        ops += new_ops
    weights_tree[:384,:] = 0
    return ops, op_cntr, mapping, weights_tree

def make_next_layer( op_cntr, weights_tree, mapping ):
    # just do binary tree from now on
    # find complete indexs
    complete_idxs = [ i for i in range( weights_tree.shape[1] ) if count_inputs( weights_tree[:,i] ) == 0 and len(mapping[i]) <= 1 ]
    # find indexs to compute
    sd = weights_tree.shape[0] - weights_tree.shape[1]
    sel_idxs = np.array( complete_idxs ) + sd
    computeable = [ i for i in range( weights_tree.shape[1] ) if count_inputs( weights_tree[sel_idxs,i] ) + len(mapping[i]) >= 2 ]
    ops = []
    return ops, op_cntr, mapping, weights_tree

def make_raw_weights_tree( weights_tree, no_in, no_out ):
    weights_tree = duplicate_sub_expr( weights_tree, no_in, no_out )
    op_cntr = no_in
    ops = []
    mapping = {}
    complete_idxs = []
    lyrs = []
    while len(ops) < weights_tree.shape[1]:
        complete = np.array( [ i for i in complete_idxs if i >= no_out ] ).astype( int ) - no_out
        print( len( complete ), op_cntr )
        for idx in range( weights_tree.shape[1] ):
            weights_vec = weights_tree[no_in:,idx]
            if idx not in mapping and count_inputs( weights_vec[complete] ) == count_inputs( weights_vec ):
                # can be computed
                pos_idx = np.where( weights_tree[:no_in,idx] == 1 )[0]
                neg_idx = np.where( weights_tree[:no_in,idx] == -1 )[0]
                complete_pos = np.where( weights_vec == 1 )[0]
                complete_neg = np.where( weights_vec == -1 )[0]
                complete_pos_op = [ mapping[i+no_out] for i in complete_pos ]
                complete_neg_op = [ mapping[i+no_out] for i in complete_neg ]
                op_code = ( ( 1 << ( len(pos_idx) + len( complete_pos_op ) ) ) - 1 ) << ( len(neg_idx) + len( complete_neg_op ) )
                op = [ op_cntr, op_code ] + pos_idx.tolist() + complete_pos_op + neg_idx.tolist() + complete_neg_op
                ops += [ op ]
                mapping[idx] = op_cntr
                complete_idxs += [ idx ]
                op_cntr += 1
    return ops, [ mapping[i] for i in range( no_out ) ]

def get_matrix( fname ):
    f = open( fname )
    rdr = csv.reader( f )
    data = [ [ int(y) for y in x ] for x in rdr ]
    matrix = np.array( data, dtype = np.int16 )
    no_in = matrix.shape[0]
    no_out = matrix.shape[1]
    print( "no_in = " + str(no_in) + ", no_out = " + str(no_out) )
    return matrix, no_in, no_out

def verify_ops( fname_w, fname_ops ):
    weights, no_in, no_out = get_matrix( fname_w )
    f = open( fname_ops )
    rdr = csv.reader( f )
    ops = [ [ int(x) for x in y] for y in rdr ]
    output_idxs = np.array( ops[0] )
    ops = ops[1:]
    inputs = np.random.randint( -64, 63, [ no_in ] )
    expected_outputs = np.matmul( inputs, weights )
    ops_computation = np.zeros( [len(ops) + no_in] )
    ops_computation[0:no_in] = inputs
    for op in ops:
        idx = op[0]
        op_code = op[1]
        all_inputs = [ ops_computation[i] for i in op[2:] ]
        op_code = [ int(x) for x in bin( op_code )[2:]  ]
        op_code = [0]*( len( all_inputs ) - len( op_code ) ) + op_code
        op_code = [ -1 if x == 0 else 1 for x in op_code ]
        total = 0
        for a, b in zip( all_inputs, op_code ):
            total += ( a * b )
        ops_computation[idx] = total
    return np.sum( expected_outputs == ops_computation[ output_idxs ] ) == no_out

if __name__=="__main__":
    fname = sys.argv[1]
    fname_out = fname.split("_weights.csv")[0].split(".csv")[0] + "_all_input_op.csv"
    fname_w = fname.split( "_weights_tree.csv" )[0] + ".csv"
    _, no_in, no_out = get_matrix( fname_w )
    weights_tree, _, _ = get_matrix( fname )
    ops, output_idxs = make_raw_weights_tree( weights_tree, no_in, no_out )
    f = open( fname_out, "w" )
    wrt = csv.writer( f )
    wrt.writerow( output_idxs )
    for x in ops:
        wrt.writerow( x )
    f.close()
    if "_weights_tree.csv" in fname:
        fname_w = fname.split( "_weights_tree.csv" )[0] + ".csv"
        print( "checking ops result ... " )
        res = verify_ops( fname_w, fname_out )
        if res:
            print( "VERIFIED" )
        else:
            print( "VERIFICATION FAILED" )

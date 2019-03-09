#! /usr/bin/python3

import csv
import numpy as np
import sys
import math

def get_pattern_mat( matrix, pattern_matrix, update_idxs, rm_idxs ):
    rm_idxs = [ x for x in rm_idxs ]
    rm_idxs = sorted( rm_idxs, reverse=True )
    for idx in rm_idxs:
        del pattern_matrix[idx]
        for i in range( 0, idx ):
            del pattern_matrix[i][0][idx - i - 1]
            del pattern_matrix[i][1][idx - i - 1]
    # change update_idxs now those idxs have been removed
    for idx in rm_idxs:
        update_idxs = [ x if x < idx else x - 1 for x in update_idxs ]
    for idx in update_idxs:
        if len(pattern_matrix) <= idx:
            pattern_matrix += [[[-1],[-1],-1]] # just filler
        res_mat_pos = np.absolute( matrix + np.tile( matrix[idx,:], [ matrix.shape[0], 1 ] ) ) > 1
        res_mat_pos_sum = np.sum( res_mat_pos, 1 )
        res_mat_neg = np.absolute( matrix - np.tile( matrix[idx,:], [ matrix.shape[0], 1 ] ) ) > 1
        res_mat_neg_sum = np.sum( res_mat_neg, 1 )
        for i in range( idx ):
            if len( pattern_matrix[i][0] ) == idx - i - 1:
                pattern_matrix[i][0] += [ res_mat_pos_sum[i] ]
                pattern_matrix[i][1] += [ res_mat_neg_sum[i] ]
            else:
                pattern_matrix[i][0][idx - i - 1] = res_mat_pos_sum[i]
                pattern_matrix[i][1][idx - i - 1] = res_mat_neg_sum[i]
        for i in range( idx ):
            pattern_matrix[i][2] = max( pattern_matrix[i][0] + pattern_matrix[i][1] )
        if matrix.shape[0] > idx + 1:
            pattern_matrix[idx] = [ res_mat_pos_sum.tolist()[idx+1:],
                                    res_mat_neg_sum.tolist()[idx+1:],
                                    np.max( res_mat_pos_sum.tolist()[idx+1:] + res_mat_neg_sum.tolist()[idx+1:] ) ]
    return pattern_matrix

def get_common_idx( pattern_matrix ):
    max_common = np.max( [ x[2] for x in pattern_matrix ] )
    common_idxs = []
    for idx, x in enumerate( pattern_matrix ):
        if x[2] >= max_common:
            for j, x in enumerate( pattern_matrix[idx][0] ):
                if x >= max_common:
                    common_idxs += [ (idx, j + idx + 1, True) ]
            for j, x in enumerate( pattern_matrix[idx][1] ):
                if x >= max_common:
                    common_idxs += [ (idx, j + idx + 1, False) ]
    return max_common, common_idxs

def find_finished_idxs( pattern_matrix ):
    rm_idxs = set( range( len( pattern_matrix ) ) )
    for i, row in enumerate( pattern_matrix ):
        # not the last row ...
        if ( row[2] < 0 or row[2] > 1 ) and i in rm_idxs:
            rm_idxs.remove(i)
    for i, row in enumerate( pattern_matrix ):
        for rowidx in [0,1]:
            for j in [ j for j in rm_idxs if i < j ]:
                x = row[rowidx][j-i-1]
                if x > 1:
                    rm_idxs.remove(j)
    return rm_idxs

def reorder_pattern( pattern ):
    # flip so the first number is positive
    for x in pattern:
        if x > 0:
            return ( pattern, False )
        if x < 0:
            return ( -pattern, True )
    return ( pattern, False )

def get_patterns_and_negations( matrix, common_idxs ):
    patterns = []
    negations = []
    for idx_a, idx_b, is_pos in common_idxs:
        sign = -1
        if is_pos:
            sign = 1
        pattern = (np.absolute( matrix[idx_a] + sign*matrix[idx_b] ) > 1)*matrix[idx_a]
        pattern, neg = reorder_pattern( pattern )
        negations += [ neg ]
        patterns += [ pattern ]
    # find most common
    patterns = [ list(x) for x in patterns ]
    patterns = sorted( enumerate( patterns ), key=lambda x:x[1] )
    return patterns, negations

def get_pos_neg( common_idx, negation ):
    res_pos = []
    res_neg = []
    if common_idx[2]:
        if negation:
            res_neg = common_idx[:2]
        else:
            res_pos = common_idx[:2]
    else:
        if negation:
            res_pos = [ common_idx[1] ]
            res_neg = [ common_idx[0] ]
        else:
            res_pos = [ common_idx[0] ]
            res_neg = [ common_idx[1] ]
    return list(set(res_pos)), list(set(res_neg))

def find_most_common( matrix, common_idxs ):
    patterns, negations = get_patterns_and_negations( matrix, common_idxs )

    # group and find largest group ...
    best_idx = 0
    best_size = 0
    curr_start = 0
    curr_size = 0
    for idx, pattern in enumerate( [ x[1] for x in patterns ] ):
        if patterns[curr_start][1] == pattern:
            curr_size += 1
        else:
            curr_size = 1
            curr_start = idx
        if curr_size > best_size:
            best_idx = curr_start
            best_size = curr_size
    pattern = patterns[best_idx][1]
    idxs = [ x for x in [ patterns[i][0] for i in range( best_idx, best_idx + best_size ) ] ]

    res_pos = []
    res_neg = []
    for i in idxs:
        tmp_pos, tmp_neg = get_pos_neg( common_idxs[i], negations[i] )
        res_pos += tmp_pos
        res_neg += tmp_neg
    return pattern, list(set(res_pos)), list(set(res_neg))

def update_matrix( matrix, idxs_pos, idxs_neg, pattern, rm_idxs ):
    # first eliminate common expr
    for i in idxs_pos:
        matrix[i,:] = matrix[i,:] - pattern
    for i in idxs_neg:
        matrix[i,:] = matrix[i,:] + pattern
    # add new row to matrix
    matrix = np.vstack( [ matrix, pattern ] )
    # add new col to matrix
    matrix = np.hstack( [ matrix, np.zeros( ( matrix.shape[0], 1 ), dtype = np.int16 ) ] )
    for i in idxs_pos:
        matrix[i,-1] = 1
    for i in idxs_neg:
        matrix[i,-1] = -1
    return_mat = [ ( matrix[i,:], i ) for i in rm_idxs ]
    matrix = matrix[np.array( [ i for i in range( matrix.shape[0] ) if i not in set(rm_idxs) ] ),:]
    return matrix, return_mat

def is_intersection( existing_patterns, new_pattern ):
    p = np.absolute( np.array( new_pattern ) )
    for ep in existing_patterns:
        res = p.dot( np.absolute( np.array(ep) ) )
        if res > 0:
            return True
    return False

def fast_update_pat_2_join( matrix, pattern_matrix ):
    print( "Only subexpressions of size 2 left ..." )
    max_common, common_idxs = get_common_idx( pattern_matrix )
    if max_common < 2:
        return max_common, matrix, []
    patterns, negations = get_patterns_and_negations( matrix, common_idxs )
    # determine non-intersecting patterns
    idx_to_pattern = {}
    chosen_idxs = []
    for p in patterns:
        idx_a, idx_b, neg = common_idxs[p[0]]
        if idx_a not in idx_to_pattern:
            idx_to_pattern[idx_a] = []
        if idx_b not in idx_to_pattern:
            idx_to_pattern[idx_b] = []
        if not is_intersection( idx_to_pattern[idx_a], p[1] ) and not is_intersection( idx_to_pattern[ idx_b ], p[1] ):
            idx_to_pattern[ idx_a ] += [ p[1] ]
            idx_to_pattern[ idx_b ] += [ p[1] ]
            chosen_idxs += [ p ]
    print( "There are " + str(len(chosen_idxs)) + " non intersecting patterns of size 2 that can be removed" )
    no_pad = 0
    update_idxs = []
    for i, p in chosen_idxs:
        res_pos, res_neg = get_pos_neg( common_idxs[i], negations[i] )
        pattern = np.concatenate( ( np.array( p, dtype = np.int16 ), np.array( [0]*no_pad, dtype = np.int16 ) ) )
        no_pad += 1
        matrix, return_mat = update_matrix( matrix, res_pos, res_neg, pattern, [] )
        update_idxs += res_pos + res_neg
    update_idxs = list(set(update_idxs)) + list(range( matrix.shape[0] - no_pad, matrix.shape[0] ))
    update_idxs.sort()
    return max_common, matrix, update_idxs

def subexpression_elimination( matrix ):
    pattern_matrix = []
    finished_rows = []
    update_idxs = list( range( matrix.shape[0] ) )
    rm_idxs = []
    most_common_count = 3
    pattern_pos = []
    pattern_neg = []
    # orig_mat = matrix.copy()
    while most_common_count > 1:
        pattern_matrix = get_pattern_mat( matrix, pattern_matrix, update_idxs, rm_idxs )
        if most_common_count > 2 or len(pattern_pos) + len(pattern_neg) > 2:
            most_common_count, common_idxs = get_common_idx( pattern_matrix )
            pattern, pattern_pos, pattern_neg = find_most_common( matrix, common_idxs )
            rm_idxs = find_finished_idxs( pattern_matrix )
            matrix, return_mat = update_matrix( matrix, pattern_pos, pattern_neg, pattern, rm_idxs )
            finished_rows = return_mat + finished_rows
            ''' verify result
            new_mat = matrix.copy()
            for x, i in finished_rows:
                tmp = np.concatenate( ( np.array( x, dtype=np.int16 ),  np.zeros( ( new_mat.shape[1] - len(x) ), dtype = np.int16 ) ) )
                new_mat = np.vstack( [ new_mat[:i,:], tmp, new_mat[i:,:] ] )
            assert reverse_check_result( orig_mat, new_mat ), "must have same matrix originally"
            '''
            update_idxs = pattern_pos + pattern_neg + [matrix.shape[0] + len(return_mat) - 1]
            print( str(len(pattern_pos) + len(pattern_neg)) +
                   " expressions have a common subexpression of size "
                   + str(most_common_count) + " to be eliminated"  )
        else:
            rm_idxs = []
            most_common_count, matrix, update_idxs = fast_update_pat_2_join( matrix, pattern_matrix )
    for x, i in finished_rows:
        tmp = np.concatenate( ( np.array( x, dtype=np.int16 ),  np.zeros( ( matrix.shape[1] - len(x) ), dtype = np.int16 ) ) )
        matrix = np.vstack( [ matrix[:i,:], tmp, matrix[i:,:] ] )
    return matrix

def size_of_tree( matrix ):
    return np.sum( np.absolute( matrix ) ) - matrix.shape[1]

def create_stage( curr_idx, idxs ):
    # group by 2 and create ops
    op_list = []
    for i in range( int( math.ceil( len(idxs) / 2 ) ) ):
        a = idxs[2*i]
        if len(idxs) < 2*i+2:
            b = [ -1, 0, False ]
        else:
            b = idxs[2*i + 1]
        add_op = 4*a[2] + 2*b[2]
        op_new = [ curr_idx, a[0], b[0], -1, add_op, 0, 0, 0 ]
        curr_idx += 1
        op_list += [ op_new ]
    return op_list, curr_idx

def create_stage_ternary( curr_idx, idxs ):
    # group by 3 and create ops
    op_list = []
    for i in range( int( math.ceil( len(idxs) / 3 ) ) ):
        a = idxs[3*i]
        if len(idxs) < 3*i+2:
            b = [ -1, 0, False ]
        else:
            b = idxs[3*i + 1]
        if len(idxs) < 3*i+3:
            c = [ -1, 0, False ]
        else:
            c = idxs[3*i + 2]
        add_op = 4*a[2] + 2*b[2] + 1*c[2]
        op_new = [ curr_idx, a[0], b[0], c[0], add_op, 0, 0, 0 ]
        curr_idx += 1
        op_list += [ op_new ]
    return op_list, curr_idx

def create_ops_for_tree( curr_idx, curr_idxs ):
    # curr_idxs = [ ( idx, depth_avail, is_pos ) ]
    if len(curr_idxs) == 0:
        return ( [], curr_idx, -1, 0 )
    curr_d = 0
    op_list = []
    reserves = []
    while len(reserves) > 0 or len(curr_idxs) > 1 or len(op_list) < 1:
        reserves = [ x for x in curr_idxs if x[1] > curr_d ]
        to_reduce = [ x for x in curr_idxs if x[1] <= curr_d ]
        reduced_ops, curr_idx = create_stage( curr_idx, to_reduce )
        # reduced_ops, curr_idx = create_stage_ternary( curr_idx, to_reduce )
        curr_idxs = [ ( x[0], curr_d + 1, True )  for x in reduced_ops ] + reserves
        op_list += reduced_ops
        curr_d += 1
    output_idx = op_list[-1][0]
    return op_list, curr_idx, output_idx, curr_d

def combine_dep( dep_a, dep_b ):
    for x in dep_b:
        dep_a[x] = dep_b[x]
    return dep_a

def get_dependancies( idxs, matrix, no_in, no_out ):
    dependancies = {}
    for i in idxs:
        dependancies[ i ] = list( np.nonzero( matrix[no_in:,i] )[0] + no_out )
        dependancies = combine_dep( dependancies,
                                    get_dependancies( dependancies[ i ], matrix, no_in, no_out )
        )
    return dependancies

def make_tree( matrix, no_in, no_out ):
    dependancies = {}
    output_depths = {}
    for j in range( no_out ):
        idxs = list( np.nonzero( matrix[no_in:,j] )[0] + no_out )
        dependancies[j] = idxs
        dependancies = combine_dep( dependancies,
                                    get_dependancies( idxs, matrix, no_in, no_out ) )
    outputs = {}
    op_list = []
    op_idx = no_in
    while len( outputs ) < len(dependancies):
        for x in dependancies:
            if x not in outputs: # haven't already done
                # check all dependancies are resolved otherwise skip for now
                dep_depths = [ output_depths[ y ] for y in dependancies[x] if y in output_depths ]
                if len( dep_depths ) == len(dependancies[x]):
                    idxs = np.nonzero( matrix[:,x] )[0]
                    idxs_in = []
                    for i in idxs:
                        j = i
                        d = 0
                        if i >= no_in:
                            j = outputs[ i + no_out - no_in ]
                            d = output_depths[ i + no_out - no_in ]
                        assert matrix[i,x] != 0, "has dependancy with zero?"
                        idxs_in += [ (j, d, matrix[i,x] > 0) ]
                    new_ops, op_idx, output_idx, curr_d = create_ops_for_tree( op_idx, idxs_in )
                    outputs[ x ] = output_idx
                    output_depths[ x ] = curr_d
                    op_list += new_ops
    return op_list, [ outputs[i] for i in range( no_out ) ]

def reverse_check_result( orig_mat, new_mat ):
    no_in = orig_mat.shape[1]
    no_out = orig_mat.shape[0]
    # replace elim outputs with full expression
    for i in range( new_mat.shape[0] - no_out ):
        vec_idx_orig = np.nonzero( new_mat[no_out+i,:] )[0]
        update_idx = np.nonzero( new_mat[:,no_in+i] )[0]
        vec_idx = np.tile( vec_idx_orig, len(update_idx) )
        update_idx = np.repeat( update_idx, len(vec_idx_orig) )
        vec = new_mat[no_out+i,vec_idx]
        new_mat[update_idx,vec_idx] += vec*new_mat[update_idx,no_in+i]
        new_mat[no_out+i,vec_idx_orig] -= new_mat[no_out+i,vec_idx_orig]
    return np.sum( new_mat[:no_out,:no_in] == orig_mat ) == no_in*no_out

def get_matrix( fname ):
    f = open( fname )
    rdr = csv.reader( f )
    data = [ [ int(y) for y in x ] for x in rdr ]
    matrix = np.transpose( np.array( data, dtype = np.int16 ) )
    no_in = matrix.shape[1]
    no_out = matrix.shape[0]
    print( "no_in = " + str(no_in) + ", no_out = " + str(no_out) )
    initial_no_adds = size_of_tree( matrix )
    print( "initial matrix is " + str( initial_no_adds  ) )
    return matrix, no_in, no_out, initial_no_adds

def write_output( fname, matrix, initial_no_adds, no_in, no_out ):
    final_no_adds = size_of_tree( matrix )
    print( "improvement is from " + str( initial_no_adds ) + " to " +
           str( final_no_adds ) + " or " + str( final_no_adds*100/initial_no_adds ) + "%" )
    f_out = open( fname + "_weights_tree.csv", "w" )
    wrt = csv.writer( f_out )
    for x in np.transpose( matrix ):
        tmp = wrt.writerow( x )
    f_out.close()
    f_out = open( fname + "_tern_op_list.csv", "w" )
    wrt = csv.writer( f_out )
    tree_ops, outputs = make_tree( np.transpose( matrix ), no_in, no_out )
    tmp = wrt.writerow( outputs )
    for x in tree_ops:
        tmp = wrt.writerow( x )
    f_out.close()
    verify_tree( fname )

def compute_op( a, b, c, op_code ):
    if op_code == 0:
      return - a - b - c
    if op_code == 1:
      return - a - b + c
    if op_code == 2:
      return - a + b - c
    if op_code == 3:
      return - a + b + c
    if op_code == 4:
      return a - b - c
    if op_code == 5:
      return a - b + c
    if op_code == 6:
      return a + b - c
    return a + b + c

def verify_tree( fname ):
    matrix, no_in, no_out, initial_no_adds = get_matrix( fname + "_weights.csv" )
    f_t = open( fname + "_tern_op_list.csv" )
    rdr = csv.reader( f_t )
    ops = [ [ int(y) for y in x ] for x in rdr ]
    outputs = ops[0]
    tmp_inputs = np.random.randint( -(1<<12), 1 << 12, no_in )
    expected_out = np.matmul( matrix, tmp_inputs )
    tmp_vals = {}
    for op in ops[1:]:
        a = tmp_inputs[op[1]] if op[1] not in tmp_vals else tmp_vals[op[1]]
        if op[2] >= 0:
            b = tmp_inputs[op[2]] if op[2] not in tmp_vals else tmp_vals[op[2]]
        else:
            b = 0
        if op[3] >= 0:
            c = tmp_inputs[op[3]] if op[3] not in tmp_vals else tmp_vals[op[3]]
        else:
            c = 0
        tmp_vals[op[0]] = compute_op( a, b, c, op[4] )
    for i, o in enumerate( outputs ):
        if o < 0:
            continue
        assert expected_out[i] == tmp_vals[o], "must match expected output from tree for output " + str(o)
    return True
    
if __name__ == "__main__":
    fname = sys.argv[1]
    fname_out = fname.split("_weights.csv")[0].split(".csv")[0]
    # fname_out = "../resources/mat" + str(conv_idx)
    # fname = fname_out + ".csv"
    # fname = "../resources/fc_1024_weights.csv"
    # fname = "../resources/softmax_weights.csv"

    matrix, no_in, no_out, initial_no_adds = get_matrix( fname )
    matrix = subexpression_elimination( matrix )
    write_output( fname_out, matrix, initial_no_adds, no_in, no_out )

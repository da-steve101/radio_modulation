import subexpression_elimination as se
import numpy as np
import math
import sys

def get_idx( i, j, no_in ):
    assert i != j and i < j, "Invalid index"
    return int(i*no_in - i*(i+1)/2 + j - i - 1)

def idx_to_ij( idx, no_in ):
    i = 0
    for i in range(no_in):
        if idx < i*no_in - i*(i+1)/2:
            break
    i = i - 1
    j = int(idx - i*no_in + i*(i+1)/2 + i + 1)
    return i, j

def copy_across( same_in, diff_in, no_in ):
    same_out = np.ones( int(no_in * ( no_in - 1 ) / 2), dtype=np.int16 )
    diff_out = np.ones( int(no_in * ( no_in - 1 ) / 2), dtype=np.int16 )
    for i in range( 0, no_in - 1 ):
        start_out = get_idx( i, i + 1, no_in )
        stop_out = get_idx( i, no_in - 1, no_in )
        start_in = get_idx( i, i + 1, no_in - 1 )
        stop_in = get_idx( i, no_in - 1, no_in - 1 )
        same_out[start_out:stop_out] = same_in[start_in:stop_in]
        diff_out[start_out:stop_out] = diff_in[start_in:stop_in]
    return same_out, diff_out

# find the most common subexpression with 2 inputs
def find_common_2( matrix, update_idxs = [], prev_cnts_same = None, prev_cnts_diff = None ):
    no_in = matrix.shape[1]
    no_out = matrix.shape[0]
    if prev_cnts_same is not None and prev_cnts_diff is not None:
        # fill from prev to avoid recounting
        counts_same, counts_diff = copy_across( prev_cnts_same, prev_cnts_diff, no_in )
    else:
        counts_same = np.ones( int(no_in * ( no_in - 1 ) / 2), dtype=np.int16 )
        counts_diff = np.ones( int(no_in * ( no_in - 1 ) / 2), dtype=np.int16 )
    # build the combinations to compute
    col_1_idxs = []
    col_2_idxs = []
    idxs = []
    for i in update_idxs:
        col_1_idx = list(range(0,i)) + list(range(i + 1,no_in))
        for j in update_idxs:
            if i == j:
                break
            else:
                col_1_idx.remove(j)
        # can filter out values that have zero. can only decrease the number in common ( except last )
        col_2_idx = [i]*len(col_1_idx)
        idx = [ get_idx( i, j, no_in ) if i < j else get_idx( j, i, no_in ) for i, j in zip(col_1_idx, col_2_idx) ]
        idxs += idx
        col_1_idxs += col_1_idx
        col_2_idxs += col_2_idx
    # look at the computed indexes and find the final
    idxs = np.array(idxs, dtype = np.int32 )
    filt_idx = ( counts_same[idxs] + counts_diff[idxs] ) > 0
    idxs = idxs[filt_idx]
    col_1_idxs = np.array( col_1_idxs )[filt_idx]
    col_2_idxs = np.array( col_2_idxs )[filt_idx]
    col_1 = matrix[:,col_1_idxs]
    col_2 = matrix[:,col_2_idxs]
    same_cnt = np.sum( ( col_1 == col_2 ) * np.abs(col_1), 0 )  # either (1,1) or (-1,-1)
    diff_cnt = np.sum( ( col_1 == -col_2 ) * np.abs(col_1), 0 ) # either (1,-1) or (-1,1)
    counts_same[idxs] = same_cnt
    counts_diff[idxs] = diff_cnt
    print( "updated " + str(len(idxs)) + " values, skipped " + str(len(filt_idx) - len(idxs)) )
    # determine the most common subexpression
    max_idx_same = np.argmax( counts_same )
    max_idx_diff = np.argmax( counts_diff )
    max_idx = max_idx_diff
    same = False
    counts = counts_diff
    if max_idx_same >= max_idx_diff:
        max_idx = max_idx_same
        same = True
        counts = counts_same
    n, m = idx_to_ij( max_idx, no_in ) # n and m are the indexs of the inputs for the most common subexpression
    # get the indexs of matrix rows that contain this subexpression
    if same:
        pos_idxs = np.arange(no_out)[ ( np.abs( matrix[:,n] + matrix[:,m] ) == 2 ) * (  matrix[:,n] > 0 ) ]
        neg_idxs = np.arange(no_out)[ ( np.abs( matrix[:,n] + matrix[:,m] ) == 2 ) * (  matrix[:,n] < 0 ) ]
    else:
        pos_idxs = np.arange(no_out)[ ( np.abs( matrix[:,n] - matrix[:,m] ) == 2 ) * (  matrix[:,n] > 0 ) ]
        neg_idxs = np.arange(no_out)[ ( np.abs( matrix[:,n] - matrix[:,m] ) == 2 ) * (  matrix[:,n] < 0 ) ]
    return n, m, pos_idxs, neg_idxs, same, counts_same, counts_diff

def b_CSE( matrix ):
    orig_mat = matrix.copy() # copy for later verification
    new_rows = [] # to store removed subexpressions
    # nothing is precomputed so update everything
    cnts_same = None
    cnts_diff = None
    update_idxs = list(range(matrix.shape[1]))
    while True:
        n, m, pos_idxs, neg_idxs, same, cnts_same, cnts_diff = find_common_2( matrix, update_idxs, cnts_same, cnts_diff )
        if len(pos_idxs) + len(neg_idxs) <= 1:
            break
        update_idxs = [ n, m, matrix.shape[1] ]
        pattern = np.zeros( matrix.shape[1], dtype = np.int16 )
        pattern[n] = 1
        if same:
            pattern[m] = 1
        else:
            pattern[m] = -1
        for i in pos_idxs:
            matrix[i,:] = matrix[i,:] - pattern
        for i in neg_idxs:
            matrix[i,:] = matrix[i,:] + pattern
        matrix = np.hstack( [ matrix, np.zeros( ( matrix.shape[0], 1 ), dtype = np.int16 ) ] )
        for i in pos_idxs:
            matrix[i,-1] = 1
        for i in neg_idxs:
            matrix[i,-1] = -1
        new_rows += [ pattern ]
    print( "Finalizing matrix ... " )
    # put the removed subexpressions back into the matrix
    for i, x in enumerate( new_rows ):
        tmp = np.concatenate( ( np.array( x, dtype=np.int16 ),  np.zeros( ( matrix.shape[1] - len(x) ), dtype = np.int16 ) ) )
        matrix = np.vstack( [ matrix, tmp ] )
    print( "Checking ... " )
    assert se.reverse_check_result( orig_mat, matrix.copy() ), "must have same matrix originally"
    print( "Verifed correctness" )
    return matrix

if __name__ == "__main__":
    fname = sys.argv[1]
    fname_out = fname.split("_weights.csv")[0].split(".csv")[0]
    matrix, no_in, no_out, initial_no_adds = se.get_matrix( fname )
    matrix = b_CSE( matrix )
    se.write_output( fname_out, matrix, initial_no_adds, no_in, no_out )

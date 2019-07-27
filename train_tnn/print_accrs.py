#! /usr/bin/python3
import csv
import sys

if __name__ == "__main__":
  accrs = []
  test_ptn = sys.argv[1]
  for i in range( -20, 32, 2 ):
    f = open( test_ptn % i )
    rdr = csv.reader( f )
    is_correct = [ x[1] == x[2] for x in rdr ]
    accrs += [ sum(is_correct)/len(is_correct) ]
  print( accrs )

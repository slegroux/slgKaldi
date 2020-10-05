#!/usr/bin/env python
# 2020 slegroux@ccrma.stanford.edu

import argparse
import sys

def compute_duration(fn):
    t = 0
    with open(fn,'r') as f:
        for line in f:
            t += float(line.split(sep=' ')[1])
    return(t / 3600.)

def get_args():
    parser = argparse.ArgumentParser('get total duration from kaldi data dir')
    parser.add_argument('data_dir')
    return(parser.parse_args())

if __name__ == "__main__":
    args = get_args()
    try:
        print(compute_duration(args.data_dir + '/utt2dur'))
    except:
        sys.exit(1)
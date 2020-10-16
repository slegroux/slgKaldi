#!/usr/bin/env python3

import argparse
from pathlib import Path
import logging
logging.basicConfig(level=logging.DEBUG)

def split(source:str, split:float = 0.2):
    src = Path(source)

    with open(source, mode='r') as f:
        res = f.readlines()
    
    test = res[:int(len(res)*split)]
    logging.info("test size %i", len(test))
    train = res[int(len(res)*split):]
    logging.info("train size %i", len(train))
    
    test_file = src.with_suffix(".tst")
    train_file = src.with_suffix(".trn")
    with open(str(test_file), 'w') as f:
        f.write(''.join(test))
    with open(str(train_file), 'w') as f:
        f.write(''.join(train))
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser('split train/test set')
    parser.add_argument('source')
    parser.add_argument('--split', type=float)
    args = parser.parse_args()
    split(args.source, args.split)
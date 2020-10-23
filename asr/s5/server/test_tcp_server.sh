#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

port_num=5050

. utils.sh
. path.sh
. utils/parse_options.sh

# wav=/data/librifrench/test/13/1410/13-1410-0001.wav
# wav=/home/syl20/data/en/free-spoken-digit-dataset/recordings/0_george_32.wav 
wav=$1
sox $wav -t raw -c 1 -b 16 -r 16k -e signed-integer - | nc localhost ${port_num}
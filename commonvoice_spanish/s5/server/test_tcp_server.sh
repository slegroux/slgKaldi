#!/usr/bin/env bash
wav=/data/librifrench/test/13/1410/13-1410-0001.wav
sox $wav -t raw -c 1 -b 16 -r 16k -e signed-integer - | nc localhost 5050
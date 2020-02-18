#!/usr/bin/env bash
for stage in {0,1,2,3,4,5,6,7,8,9}; do
    ./run.sh --stage $stage --njobs 36
done

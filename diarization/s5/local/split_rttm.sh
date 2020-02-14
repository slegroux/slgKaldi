#!/usr/bin/env bash


dataset=test
ext=rttm

. utils/parse_options.sh

rttm=$1

if [ ! -d data/${dataset}/rttm ]; then
    mkdir -p data/${dataset}/rttm
fi
#set -x
while IFS= read -r line; do
    id=$(echo $line | cut -d' ' -f1)
    # replace channel by 1 for der computations to work
    cat $rttm | awk '{ $3=1; print $0 }' |grep -w $id > data/${dataset}/rttm/${id}.${ext}
done <data/$dataset/wav.scp
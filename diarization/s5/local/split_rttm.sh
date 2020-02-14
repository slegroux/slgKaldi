#!/usr/bin/env bash

dataset=test
rttm=$(find . -type f -name rttm)

. utils/parse_options.sh

if [ ! -d data/${dataset}/rttm ]; then
    mkdir -p data/${dataset}/rttm
fi

while IFS= read -r line; do
    id=$(echo $line | cut -d' ' -f1)
    cat $rttm | grep -w $id > data/${dataset}/rttm/${id}.rttm
done <data/$dataset/wav.scp
#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

compute_graph=False

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
graph=$2
online_decode_dir=$3


nj=$(get_njobs $dataset)

steps/online/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --nj $nj --cmd "run.pl" \
        ${graph} ${dataset} ${online_decode_dir}

log_wer ${online_decode_dir}
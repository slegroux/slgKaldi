#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

njobs=$(($(nproc)-1))
gmm=tri3b
online_cmvn_iextractor=true
nnet3_affix=_online_cmn
train_set=train
test_sets=test_35
stage=0

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt| wc -l)

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 11" if you have already
# run those things.
local/nnet3/run_ivector_common.sh --stage $stage \
                                  --njobs $njobs \
                                  --n_speakers_test $n_speakers_test \
                                  --online_cmvn_iextractor $online_cmvn_iextractor \
                                  --train_set $train_set \
                                  --test_sets $test_sets \
                                  --gmm $gmm \
                                  --nnet3-affix "$nnet3_affix" || exit 1;

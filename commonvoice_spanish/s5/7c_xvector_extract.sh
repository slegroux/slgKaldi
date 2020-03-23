#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

njobs=$(($(nproc)-1))

stage=0

#nnet_dir=$DATA/0003_sre16_v2_1a/exp
xvector_extractor=$DATA/voxceleb/0007_voxceleb_v2_1a/exp/xvector_nnet_1a
ngpu=8

sudo nvidia-smi -c 0

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

dataset=$1

xvector_dir=data/${dataset}_x/xvectors
n_speakers_test=$(cat data/${dataset}/spk2utt| wc -l)

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if [ $stage -le 0 ]; then
    # mfcc for xvectors (dim 30)
    utils/copy_data_dir.sh data/${dataset} data/${dataset}_x
    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_xvector.conf \
        --cmd "run.pl" data/${dataset}_x
    steps/compute_cmvn_stats.sh data/${dataset}_x
    utils/fix_data_dir.sh data/${dataset}_x
    utils/validate_data_dir.sh data/${dataset}_x
fi

if [ $stage -le 1 ]; then
    # get xvectors
    sid/compute_vad_decision.sh --vad_config conf/vad.conf --nj $nj --cmd "run.pl" data/${dataset}_x
    sid/nnet3/xvector/extract_xvectors.sh --use-gpu true --cmd "run.pl" --nj $ngpu \
        $xvector_extractor data/${dataset}_x $xvector_dir
fi

sudo nvidia-smi -c 3
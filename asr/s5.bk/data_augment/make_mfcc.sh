#!/usr/bin/env bash

stage=0

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

dataset=$1

njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${dataset}/spk2utt| wc -l)
if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if [ $stage -le 1 ]; then
  # Create MFCC features 13).
  echo "$0: creating MFCC features from conf/mfcc.conf"

  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc.conf \
    --cmd "$train_cmd" data/${dataset} || exit 1;
  steps/compute_cmvn_stats.sh data/${dataset} || exit 1;
  utils/fix_data_dir.sh data/${dataset}
  utils/validate_data_dir.sh data/${dataset}
fi
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
  # Create high-resolution MFCC features (with 40 cepstra instead of 13).
  # this shows how you can split across multiple file-systems.
  echo "$0: creating high-resolution MFCC features"
  
  utils/copy_data_dir.sh data/$dataset data/${dataset}_hires
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" data/${dataset}_hires || exit 1;
  steps/compute_cmvn_stats.sh data/${dataset}_hires || exit 1;
  utils/fix_data_dir.sh data/${dataset}_hires

fi
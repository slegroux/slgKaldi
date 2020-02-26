#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

njobs=$(($(nproc)-1))

stage=0
nnet3_affix=_online_cmn
ivector_extractor=exp/nnet3${nnet3_affix}/extractor

echo "$0 $@"  # Print the command line for logging

. cmd.sh
. path.sh
. utils/parse_options.sh

dataset=$1
ivector_dir=data/${dataset}_hires/ivectors
n_speakers_test=$(cat data/${dataset}/spk2utt| wc -l)

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if [ $stage -le 0 ]; then
  echo "ivector high res mfcc in dataset_hires"
  utils/copy_data_dir.sh data/$dataset data/${dataset}_hires
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
    --cmd "run.pl" data/${dataset}_hires
  steps/compute_cmvn_stats.sh data/${dataset}_hires
  utils/fix_data_dir.sh data/${dataset}_hires
fi


if [ $stage -le 1 ]; then
  steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj 40 \
    data/${dataset}_hires $ivector_extractor $ivector_dir
fi
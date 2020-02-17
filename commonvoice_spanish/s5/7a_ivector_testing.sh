#!/bin/bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

njobs=$(($(nproc)-1))
gmm=tri3b
online_cmvn_iextractor=true
nnet3_affix=_online_cmn
train_set=train
test_set=test_35
stage=0

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

n_speakers_test=$(cat data/${test_set}/spk2utt| wc -l)

utils/copy_data_dir.sh data/$test_set data/${test_set}_hires
steps/make_mfcc.sh --nj $n_speakers_test --mfcc-config conf/mfcc_hires.conf \
  --cmd "$train_cmd" data/${test_set}_hires || exit 1;
steps/compute_cmvn_stats.sh data/${test_set}_hires || exit 1;
utils/fix_data_dir.sh data/${test_set}_hires || exit 1;

# Also extract iVectors for the test data, but in this case we don't need the speed
# perturbation (sp).
if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
  data/${test_set}_hires exp/nnet3${nnet3_affix}/extractor \
  exp/nnet3${nnet3_affix}/ivectors_${test_set}_hires

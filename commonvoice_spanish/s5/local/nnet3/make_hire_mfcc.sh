#!/bin/bash

set -euo pipefail

# This script is called from local/nnet3/run_tdnn.sh and
# local/chain/run_tdnn.sh (and may eventually be called by more
# scripts).  It contains the common feature preparation and
# iVector-related parts of the script.  See those scripts for examples
# of usage.

stage=3
test_sets=test
nnet3_affix=_online_cmn

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${test_set}_hires/spk2utt | wc -l)

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if [ $stage -le 3 ]; then
    # Create high-resolution MFCC features (with 40 cepstra instead of 13).
    # this shows how you can split across multiple file-systems.
    echo "$0: creating high-resolution MFCC features"
    
    utils/copy_data_dir.sh data/${test_set} data/${test_set}_hires
  
    steps/make_mfcc.sh --nj $njobs --mfcc-config conf/mfcc_hires.conf \
      --cmd "$train_cmd" data/${test_set}_hires || exit 1;
    steps/compute_cmvn_stats.sh data/${test_set}_hires || exit 1;
    utils/fix_data_dir.sh data/${test_set}_hires || exit 1;

    steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
      data/${test_set}_hires exp/nnet3${nnet3_affix}/extractor \
      exp/nnet3${nnet3_affix}/ivectors_${test_set}_hires
  done


fi


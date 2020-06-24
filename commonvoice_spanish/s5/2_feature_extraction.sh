#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
stage=5
train_set=train
test_set=test
subset=4000

# end configuration section
. ./path.sh
. utils/parse_options.sh


if [ $stage == 5 ]; then
  echo ============================================================================
  echo " MFCC extraction "
  echo ============================================================================

  mfccdir=mfcc
  for x in ${train_set} ${test_set}; do
    if [ -e data/$x/cmvn.scp ]; then
      rm data/$x/cmvn.scp
    fi

    n_speakers_test=$(cat data/${x}/spk2utt | wc -l)
    if [ $njobs -le $n_speakers_test ]; then
      nj=$njobs
    else
      nj=$n_speakers_test
    fi
    
    steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj $nj data/$x
    steps/compute_cmvn_stats.sh data/$x
    utils/fix_data_dir.sh data/$x
    utils/validate_data_dir.sh data/$x
  done
  
  # utils/subset_data_dir.sh data/${train_set} $subset data/${train_set}_${subset}
fi

if [ $stage == 51 ]; then
  echo ============================================================================
  echo " PLP extraction "
  echo ============================================================================

  plpdir=plp
  for x in ${train_set} ${test_set}; do
    steps/make_plp.sh --nj $njobs data/$x exp/plp/$x $plpdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/plp/$x $plpdir || exit 1;
  done
  utils/subset_data_dir.sh data/${train_set} $subset data/${train_set}_${subset}
fi
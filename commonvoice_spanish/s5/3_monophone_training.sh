#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
stage=6
training_set=train
subset=4000
decode=true


. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)


if [ $stage == 6 ]; then
  echo ============================================================================
  echo " MonoPhone Training "
  echo ============================================================================

  if [ ! -d data/${training_set}_${subset} ]; then
    utils/subset_data_dir.sh data/${training_set} $subset data/${training_set}_${subset}
  fi

  #Train monophone model
  time steps/train_mono.sh \
    --nj $njobs \
    --config conf/monophone.conf \
    data/${training_set}_${subset} data/lang exp/mono

  #Align the train data using mono-phone model
  steps/align_si.sh --nj $njobs data/${training_set} data/lang exp/mono exp/mono_ali
fi
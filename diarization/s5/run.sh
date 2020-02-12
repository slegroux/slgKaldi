#!/usr/bin/env bash
# 2020 sylvain.legroux@gmail.com

. path.sh

stage=0
audio_dir=data/audio
dataset=test
mfccdir=mfcc
vaddir=mfcc

. ./utils/parse_options.sh

np=$(( nproc - 1 ))

set -x

# data preprocessing
if [ $stage -eq 0 ]; then
    model_sr=8000
    ./local/make_kaldi_dir.sh $audio_dir --model_sr $model_sr --dataset $dataset
    ./utils/fix_data_dir.sh data/$dataset
fi

# feature extraction
if [ $stage -eq 1 ]; then
    n_utts=$(cat data/$dataset/utt2spk |wc -l)
    if [ $np -lt $n_utts ]; then
        nj=$n_utts
    else
        nj=$np
    fi

    steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj $nj \
      --cmd "run.pl" \
      data/$dataset exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/$dataset
fi

# vad
if [ $stage -eq 2 ]; then
    sid/compute_vad_decision.sh --nj $(( nproc -1 )) --cmd "run.pl" \
        --vad-config conf/vad.conf \
        data/$dataset exp/make_vad $vaddir
    # utils/fix_data_dir.sh data/$dataset
fi
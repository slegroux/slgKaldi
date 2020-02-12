#!/usr/bin/env bash

# kaldi diarization tutorial
# 2020 sylvain.legroux@gmail.com

set -x
. path.sh

stage=0
audio_dir=data/audio
dataset=test
mfccdir=mfcc
vaddir=mfcc

. ./utils/parse_options.sh

np=$(( $(nproc) - 1 ))

set -x

# data preprocessing
if [ $stage -eq 0 ]; then
    model_sr=8000
    ./local/make_kaldi_dir.sh $audio_dir --model_sr $model_sr --dataset $dataset
    ./utils/fix_data_dir.sh data/$dataset
fi

# set up parallel computations
if [ -f data/$dataset/utt2spk ]; then
    n_utts=$(cat data/$dataset/utt2spk |wc -l)
    if (( $np > $n_utts )); then
        nj=$n_utts
    else
        nj=$np
    fi
else
    echo "need utt2spk file. run stage 0"
fi

# feature extraction
if [ $stage -eq 1 ]; then
    steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj $nj \
      --cmd "run.pl" --write-utt2num-frames true \
      data/$dataset exp/make_mfcc $mfccdir
    steps/compute_cmvn_stats.sh data/$dataset exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/$dataset
fi

# vad
if [ $stage -eq 2 ]; then
    sid/compute_vad_decision.sh --nj $nj --cmd "run.pl" \
        --vad-config conf/vad.conf \
        data/$dataset exp/make_vad $vaddir
    utils/fix_data_dir.sh data/$dataset
fi

# segment
if [ $stage -eq 3 ]; then
    diarization/vad_to_segments.sh --nj $nj --cmd "run.pl" \
    data/$dataset data/${dataset}_segmented
    utils/fix_data_dir.sh data/${dataset}_segmented
fi

# xvectors
if [ $stage -eq 4 ]; then
    diarization/nnet3/xvector/extract_xvectors.sh --nj $nj --cmd "run.pl" \
        --window 1.5 --period 0.75 --apply-cmn false --min-segment 0.5 \
        $nnet_dir $cmn_dir $nnet_dir/exp/xvectors
fi

# scoring
if [ $stage -eq 5 ]; then
    diarization/nnet3/xvector/score_plda.sh \
        --cmd "run.pl" \
        --target-energy 0.9 --nj 20 $nnet_dir/xvectors_sre_combined/ \
        $nnet_dir/xvectors $nnet_dir/xvectors/plda_scores
fi
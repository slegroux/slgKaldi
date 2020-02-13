#!/usr/bin/env bash

# kaldi diarization tutorial
# 2020 sylvain.legroux@gmail.com


. path.sh

stage=-1
audio_dir=data/audio
dataset=test
mfccdir=mfcc
vaddir=mfcc
nnet_dir=/home/workfit/Sylvain/Data/kaldi_models/0003_sre16_v2_1a/exp

. ./utils/parse_options.sh

np=$(( $(nproc) - 1 ))
set -x


# link to utils
if [ $stage -eq -1 ]; then
    ./create_links.sh
fi

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
        $nnet_dir/xvector_nnet_1a data/${dataset}_segmented exp/xvectors_${dataset}
fi

# scoring
if [ $stage -eq 5 ]; then
    diarization/nnet3/xvector/score_plda.sh \
        --cmd "run.pl" \
        --target-energy 0.9 --nj $nj $nnet_dir/xvectors_sre_combined/ \
        exp/xvectors_${dataset} exp/xvectors_${dataset}/plda_scores
fi

# supervised clustering
if [ $stage -eq 6 ]; then
    diarization/cluster.sh --cmd "run.pl" --nj $nj \
        --reco2num-spk $data_dir/reco2num_spk \
        $nnet_dir/xvectors/plda_scores \
        $nnet_dir/xvectors/plda_scores_speakers
fi

# unsupervised clustering
if [ $stage -eq 61 ]; then
    threshold=0.5
    diarization/cluster.sh --cmd "run.pl" --nj $nj \
        --threshold $threshold \
        exp/xvectors_${dataset}/plda_scores \
        exp/xvectors_${dataset}/plda_scores_speakers
fi
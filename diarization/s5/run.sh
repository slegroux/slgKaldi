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
#set -x


# link to utils
if [ $stage -eq -1 ]; then
    ./create_links.sh
fi

# data preprocessing
if [ $stage -le 0 ]; then
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

# mfcc
if [ $stage -le 1 ]; then
    steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj $nj \
      --cmd "run.pl" --write-utt2num-frames true \
      data/$dataset exp/make_mfcc $mfccdir
    #steps/compute_cmvn_stats.sh data/$dataset exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/${dataset}
fi

# vad
if [ $stage -le 2 ]; then
    sid/compute_vad_decision.sh --nj $nj --cmd "run.pl" \
        --vad-config conf/vad.conf \
        data/$dataset exp/make_vad $vaddir
    utils/fix_data_dir.sh data/${dataset}
fi

# cmn xvectors
if [ $stage -le 3 ]; then
    ./local/nnet3/xvector/prepare_feats.sh --nj $nj \
        --cmd "run.pl" data/$dataset data/${dataset}_cmn exp/make_xvectors
    cp data/$dataset/vad.scp data/${dataset}_cmn/
    utils/fix_data_dir.sh data/${dataset}_cmn
fi

# segment on cmn data
if [ $stage -le 4 ]; then
    diarization/vad_to_segments.sh --nj $nj --cmd "run.pl" \
    data/${dataset}_cmn data/${dataset}_cmn_segmented
    utils/fix_data_dir.sh data/${dataset}_cmn_segmented
fi

# xvectors
if [ $stage -le 5 ]; then
    diarization/nnet3/xvector/extract_xvectors.sh --nj $nj --cmd "run.pl" \
        --window 1.5 --period 0.75 --apply-cmn false --min-segment 0.5 \
        $nnet_dir/xvector_nnet_1a data/${dataset}_cmn_segmented exp/xvectors_${dataset}_cmn_segmented
fi

# scoring
if [ $stage -le 6 ]; then
    diarization/nnet3/xvector/score_plda.sh \
        --cmd "run.pl" \
        --target-energy 0.9 --nj $nj $nnet_dir/xvectors_sre_combined/ \
        exp/xvectors_${dataset}_cmn_segmented exp/xvectors_${dataset}_cmn_segmented/plda_scores
fi

# supervised clustering
if [ $stage -le 7 ]; then
    diarization/cluster.sh --cmd "run.pl" --nj $nj \
        --reco2num-spk data/reco2num_spk \
        exp/xvectors_${dataset}_cmn_segmented/plda_scores \
        exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_supervised
    cat exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_supervised/rttm
fi

# eval
if [ $stage -eq 71 ]; then
    hyp=exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_supervised/rttm
    cat data/test/rttm/fullref.rttm| awk '{ $3=0; print $0 }' > data/test/rttm/fullref_0.rttm
    ref=data/test/rttm/fullref_0.rttm
    md-eval.pl -1 -c 0.25 -r $ref -s $hyp > DER.txt
    der=$(grep -oP 'DIARIZATION\ ERROR\ =\ \K[0-9]+([.][0-9]+)?' \
        DER.txt)
    echo "Using the oracle number of speakers, DER: $der%"
fi

# unsupervised clustering
if [ $stage -eq 8 ]; then
    threshold=0.5
    diarization/cluster.sh --cmd "run.pl" --nj $nj \
        --threshold $threshold \
        exp/xvectors_${dataset}_cmn_segmented/plda_scores \
        exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_unsupervised
fi

# generate sv
if [ $stage -eq 9 ]; then
    rttm_supervised=exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_supervised/rttm
    rttm_unsupervised=exp/xvectors_${dataset}_cmn_segmented/plda_scores_speakers_unsupervised/rttm
    
    ./local/split_rttm.sh --ext 's.rttm' $rttm_supervised
    ./local/split_rttm.sh --ext 'u.rttm' $rttm_unsupervised

    for i in data/${dataset}/rttm/*.rttm; do
        ./local/rttm2sv.sh $i
    done
fi
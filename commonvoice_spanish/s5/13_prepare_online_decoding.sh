#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu
stage=0
mfcc_conf=conf/mfcc_hires.conf
cmvn_conf=conf/online_cmvn.conf
lang=data/lang_test
extractor=exp/nnet3_online_cmn/extractor
#model=exp/chain/cnn_tdnn1a76b_sp
model=exp/chain_online_cmn/tdnn64k_sp
#online_model=exp/chain/cnn_tdnn1a76b_sp_online
online_model=exp/chain_online_cmn/tdnn64k_sp_online
graph=exp/chain/tree_train_sp/graph_tgsmall
test_set=test_35

. cmd.sh
. path.sh
. utils/parse_options.sh

if [ $stage -le 0 ]; then
    steps/online/nnet3/prepare_online_decoding.sh \
        --mfcc-config $mfcc_conf \
        --online-cmvn-config $cmvn_conf \
        $lang $extractor $model $online_model
fi

if [ ! -d $online_model/graph ]; then
    utils/mkgraph.sh \
        --self-loop-scale 1.0 \
        $lang $online_model $online_model/graph
fi

if [ $stage -le 1 ]; then
    echo "Online decoding" | tee -a WER.txt
    njobs=$(($(nproc)-1))
    n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)

    if [ $njobs -le $n_speakers_test ]; then
        nj=$njobs
    else
        nj=$n_speakers_test
    fi
    steps/online/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --nj 40 --cmd "run.pl" \
        $graph data/${test_set}_hires $online_model/decode_${test_set}_hires || exit 1

    for x in $online_model/decode_${test_set}_hires; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done |tee -a WER.txt
fi

# steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
#     data/lang_test_{tgsmall,tglarge} \
#     data/${data}_hires ${dir}_online/decode_{tgsmall,tglarge}_${data} || exit 1
      
# for x in ${dir}_online/decode_tglarge_${data}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
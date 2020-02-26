#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

mfcc_conf=conf/mfcc_hires.conf
cmvn_conf=conf/online_cmvn.conf
lang=data/lang_test
extractor=exp/nnet3_online_cmn/extractor
#model=exp/chain/cnn_tdnn1a76b_sp
model=exp/chain_online_cmn/tdnn64k_sp
#online_model=exp/chain/cnn_tdnn1a76b_sp_online
online_model=exp/chain_online_cmn/tdnn64k_sp_online

data_test=test_35

steps/online/nnet3/prepare_online_decoding.sh \
    --mfcc-config $mfcc_conf \
    --online-cmvn-config $cmvn_conf \
    $lang $extractor $model $online_model

utils/mkgraph.sh \
    --self-loop-scale 1.0 \
    $lang $online_model $online_model/graph

echo "Online decoding" | tee -a WER.txt
nspk=$(wc -l <data/${data_test}_hires/spk2utt)
steps/online/nnet3/decode.sh \
    --acwt 1.0 --post-decode-acwt 10.0 \
    --nj $nspk --cmd "run.pl" \
    exp/chain_online_cmn/tree_sp/graph_tgsmall data/${data_test}_hires $online_model/decode_${data_test}_hires || exit 1

for x in $online_model/decode_${data_test}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done |tee -a WER.txt

# steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
#     data/lang_test_{tgsmall,tglarge} \
#     data/${data}_hires ${dir}_online/decode_{tgsmall,tglarge}_${data} || exit 1
      
# for x in ${dir}_online/decode_tglarge_${data}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
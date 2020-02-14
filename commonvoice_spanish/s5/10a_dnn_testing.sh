#!/bin/bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail
#set -x

stage=16

gmm=tri3b
nnet3_affix=_online_cmn
affix=64k #tdnn
#affix=1a76b #cnntdnn
tree_affix=
chunk_width=140,100,160

lang=data/lang_test

train_set=train
test_set=test_35
test_online_decoding=true

online_cmvn=true #tdnn
#online_cmvn=false #cnn-tdnn

compute_graph=true


echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${test_set}_hires/spk2utt | wc -l)
# nspk=$(wc -l <data/${dataset}_hires/spk2utt)
frames_per_chunk=$(echo $chunk_width | cut -d, -f1)

dir=exp/chain${nnet3_affix}/tdnn${affix}_sp
tree_dir=exp/chain${nnet3_affix}/tree_sp${tree_affix:+_$tree_affix}

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if $compute_graph; then
  # Note: it's not important to give mkgraph.sh the lang directory with the
  # matched topology (since it gets the topology file from the model).
  utils/mkgraph.sh \
    --self-loop-scale 1.0 $lang \
    $tree_dir $tree_dir/graph_tgsmall || exit 1;
fi

if [ $stage -le 16 ]; then

  steps/nnet3/decode.sh \
      --acwt 1.0 --post-decode-acwt 10.0 \
      --frames-per-chunk $frames_per_chunk \
      --nj 35 --cmd "$decode_cmd"  --num-threads 4 \
      --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${test_set}_hires \
      $tree_dir/graph_tgsmall data/${test_set}_hires ${dir}/decode_tgsmall_${test_set} || exit 1
  
  echo "TDNN Decoding" | tee -a WER.txt
  for x in ${dir}/decode_tgsmall_${test_set}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done | tee -a WER.txt

fi

exit 1
if [$stage -le 17 ]; then
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
  data/${lang}_{tgsmall,tglarge} \
  data/${test_set}_hires ${dir}/decode_{tgsmall,tglarge}_${test_set} || exit 1
  
  echo "large lm rescoring" | tee -a WER.txt
  for x in ${dir}/decode_tglarge_${data}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done | tee -a WER.txt

fi

# Not testing the 'looped' decoding separately, because for
# TDNN systems it would give exactly the same results as the
# normal decoding.



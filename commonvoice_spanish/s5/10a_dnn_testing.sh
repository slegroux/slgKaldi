#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail
#set -x

stage=16

gmm=tri3b
dir=exp/chain/tdnnf_tedlium_train
tree_dir=exp/chain/tree_train
ivector_extractor=exp/nnet3_train_sp_vp/extractor
# test_set=test35
lang=data/lang_test

#online_cmvn=true #tdnn
online_cmvn=false #cnn-tdnn
# chunk_width=140,100,160
chunk_width=150,110,100 #tedlium

compute_graph=true

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

test_set=$1

njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)

frames_per_chunk=$(echo $chunk_width | cut -d, -f1)

ivector_dir=data/${test_set}_hires/ivectors
#ivector_dir=exp/nnet3_test35/

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
  #Decoder

  set -x
  if [ ! -d $ivector_dir ]; then
    echo "compute dataset hires ivecs"
    ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor ${test_set}
  fi
  steps/nnet3/decode.sh \
      --acwt 1.0 --post-decode-acwt 10.0 \
      --frames-per-chunk $frames_per_chunk \
      --nj $nj --cmd "run.pl" \
      --online-ivector-dir $ivector_dir \
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



#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

stage=16

gmm=tri3b
# nnet3_affix=_online_cmn
nnet3_affix=
train_set=train
dir=exp/chain${nnet3_affix}/tdnn_${train_set}
tree_dir=exp/chain${nnet3_affix}/tree_${train_set}
ivector_extractor=exp/nnet3_${train_set}/extractor

#chunk_width=140,100,160 #rdi
chunk_width=150,110,100 #tedlium

lang=data/lang_test
compute_graph=true

echo "$0 $@"  # Print the command line for logging

. cmd.sh
. path.sh
. utils/parse_options.sh

test_set=$1
# set -x
njobs=$(($(nproc)-1))
n_speakers_test=$(cat data/${test_set}_hires/spk2utt | wc -l)
# nspk=$(wc -l <data/${dataset}_hires/spk2utt)
frames_per_chunk=$(echo $chunk_width | cut -d, -f1)


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
  if [ $njobs -le $n_speakers_test ]; then
    nj=$njobs
  else  
    nj=$n_speakers_test
  fi
  ivector_dir=data/${test_set}_hires/ivectors
  xvector_dir=data/${test_set}_x/xvectors
  xivector_dir=data/${test_set}_x/xivectors

  if [ ! -d $ivector_dir ]; then
    echo "compute dataset hires ivecs"
    ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor \
      ${test_set}
  fi
  if [ ! -d $xvector_dir ]; then
    echo "compute xvectors"
    ./7c_xvector_extract.sh $test_set
  fi
  if [ ! -d $xivector_dir ]; then
    echo "compute xievectors"
    ./7d_concat_xivectors.sh $ivector_dir $xvector_dir $xivector_dir
  fi

  steps/nnet3/decode.sh \
      --acwt 1.0 --post-decode-acwt 10.0 \
      --frames-per-chunk $frames_per_chunk \
      --nj $nj --cmd "run.pl" \
      --online-ivector-dir $xivector_dir \
      $tree_dir/graph_tgsmall data/${test_set}_hires ${dir}/decode_tgsmall_${test_set} || exit 1
  
  echo "TDNN Decoding" | tee -a WER.txt
  for x in ${dir}/decode_tgsmall_${test_set}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh | tee -a WER.txt; done

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



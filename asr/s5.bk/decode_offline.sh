#!/usr/bin/env bash

if [ $stage -le 16 ]; then
  #Decoder
  if [ $njobs -le $n_speakers_test ]; then
    nj=$njobs
  else  
    nj=$n_speakers_test
  fi
  if [ ! -d exp/nnet3${nnet3_affix}/ivectors_${test_set}_hires ]; then
    echo "compute dataset hires ivecs"
    ./7a_ivector_testing.sh --test_set ${test_set}
  fi
  steps/nnet3/decode.sh \
      --acwt 1.0 --post-decode-acwt 10.0 \
      --frames-per-chunk $frames_per_chunk \
      --nj $nj --cmd "run.pl" \
      --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${test_set}_hires \
      $tree_dir/graph_tgsmall data/${test_set}_hires ${dir}/decode_tgsmall_${test_set} || exit 1
  
  echo "TDNN Decoding" | tee -a WER.txt
  for x in ${dir}/decode_tgsmall_${test_set}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done | tee -a WER.txt

fi
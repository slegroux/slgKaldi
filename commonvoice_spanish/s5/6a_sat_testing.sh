#!/bin/bash

njobs=$(($(nproc)-1))
test_set=test_35
lang=data/lang_test
compute_graph=true

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)
graph_dir=exp/tri3b/graph

echo ============================================================================
echo " SAT Decoding "
echo ============================================================================

#Decoder
if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if $compute_graph; then
  utils/mkgraph.sh data/lang_test exp/tri3b $graph_dir
fi

steps/decode_fmllr.sh --nj $nj $graph_dir data/${test_set} exp/tri3b/decode_${test_set}


echo "SAT training" | tee -a WER.txt
for x in exp/tri3b/decode_${test_set}; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh  |tee -a WER.txt
done

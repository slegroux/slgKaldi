#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
test_set=test_35
lang=data/lang_test
compute_graph=true

. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)
graph_dir=exp/tri2b/graph


echo ============================================================================
echo " LDA MLLT Decoding "
echo ============================================================================

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi

if $compute_graph; then
  time utils/mkgraph.sh $lang exp/tri2b $graph_dir
fi

#Decoder
steps/decode.sh --nj $n_speakers_test $graph_dir data/${test_set} exp/tri2b/decode_${test_set}

echo "LDA MLLT training" | tee -a WER.txt
for x in exp/tri2b/decode_${test_set}; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
done



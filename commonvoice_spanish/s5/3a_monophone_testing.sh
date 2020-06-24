#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
test_set=test
lang=data/lang_test
compute_graph=true


. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)
graph_dir=exp/mono/graph

echo ============================================================================
echo " MonoPhone Testing "
echo ============================================================================

if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi


if $compute_graph; then
  time utils/mkgraph.sh --mono $lang exp/mono $graph_dir
fi
  
time steps/decode.sh \
  --nj $nj \
  ${graph_dir} data/${test_set} exp/mono/decode_${test_set}

echo "Monophone training" | tee -a WER.txt
for x in exp/mono/decode_${test_set}; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
done
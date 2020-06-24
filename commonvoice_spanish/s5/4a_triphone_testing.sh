#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
mono_ali_set=mono_ali
test_set=test
lang=data/lang_test
compute_graph=true

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/${test_set}/spk2utt | wc -l)
graph_dir=exp/tri1/graph

echo ============================================================================
echo " tri1 : TriPhone with delta delta-delta features Decoding      "
echo ============================================================================

#Train Deltas + Delta-Deltas model based on mono_ali
# parameters from heroico
cluster_thresh=100
num_leaves=1500
tot_gauss=25000


if [ $njobs -le $n_speakers_test ]; then
  nj=$njobs
else
  nj=$n_speakers_test
fi
#Decoder
if $compute_graph; then
  time utils/mkgraph.sh $lang exp/tri1 $graph_dir
fi
  
time steps/decode.sh \
  --nj $nj \
  ${graph_dir} data/${test_set} exp/tri1/decode_${test_set}

echo "Monophone testing" | tee -a WER.txt
#cat conf/monophone.conf | tee -a WER.txt
for x in exp/tri1/decode_${test_set}; do
  [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
done
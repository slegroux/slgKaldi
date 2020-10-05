#!/usr/bin/env bash
# (c) 2019 voicea <sylvainlg@voicea.ai>

ngram_order=4

rnnlm_dir=exp/rnnlm
lang_dir=data/lang_test_SRILM
data_dir=data/test
source_dir=exp/chain/cnn_tdnn1a76b_sp/decode_tgsmall_test


. ./cmd.sh
. ./utils/parse_options.sh

output_dir=${source_dir}_nbest

# Nbest rescoring
rnnlm/lmrescore_nbest.sh \
    --cmd "run.pl --mem 8G" --N 20 \
    0.4 $lang_dir $rnnlm_dir \
    $data_dir $source_dir \
    $output_dir

for i in ${source_dir}*; do
  #local/score.sh --decode_mbr true $data_dir $lang_dir $i
  [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh;
done

exit 0

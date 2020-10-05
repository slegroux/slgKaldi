#!/usr/bin/env bash
# (c) 2019 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=0

ngram_order=3
rnnlm_dir=exp/rnnlm_averaged
lang_dir=data/lang_test
test_set=test
data_dir=data/${test_set}
model=tdnnf_tedlium_train_sp_vp_xvec
#model=tdnnf_tedlium_train_combined
source_dir=exp/chain/${model}/decode_tgsmall_${test_set}

. ./utils/parse_options.sh

output_dir=${source_dir}_$(basename $rnnlm_dir)

if [ $stage -le 0 ]; then
  ./rnnlm/lmrescore_pruned.sh \
    --cmd "run.pl --mem 4G" \
    --weight 0.5 --max-ngram-order $ngram_order \
    $lang_dir $rnnlm_dir \
    $data_dir $source_dir \
    $output_dir
fi

if [ $stage -le 1 ]; then
  echo "RNNLM rescoring" | tee -a WER.txt
  for x in ${source_dir}_$(basename ${rnnlm_dir}); do
    #local/score.sh --decode_mbr true $data_dir $lang_dir $x
    [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh | tee -a WER.txt;
  done
fi

exit 0
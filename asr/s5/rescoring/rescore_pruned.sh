#!/usr/bin/env bash
# (c) 2019 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

ngram_order=4

. utils.sh
. utils/parse_options.sh

lang_dir=$1
rnnlm_dir=$2
data_dir=$3
source_dir=$4
output_dir=$5


log_time rnnlm/lmrescore_pruned.sh \
  --cmd "run.pl --mem 4G" \
  --weight 0.5 --max-ngram-order $ngram_order \
  $lang_dir $rnnlm_dir \
  $data_dir $source_dir \
  $output_dir

log_wer $output_dir

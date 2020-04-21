#!/usr/bin/env bash
#
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
#

set -ex

. ./cmd.sh
. ./path.sh

order=3
fold=true
stage=0
num_words=0 #all words
max_memory=200G
size=50000

echo "$0 $@"

. ./utils/parse_options.sh

POCOLM=$KALDI_ROOT/tools/pocolm

if [ ! -d data/local/lm ]; then
    mkdir -p data/local/lm
fi

corpus=$1

if [ ! -d $corpus ]; then
  echo "$0: input data $corpus not found."
  exit 1
fi

pocolm_dir=data/local/lm

min_count_opt=''

pocolm_arpa_file=${pocolm_dir}/${order}g_poco.arpa.gz

pocolm_data_dir=$corpus

lm_work_dir=${pocolm_dir}/unpruned_work
mkdir -p $lm_work_dir

unpruned_model_dir=${pocolm_dir}/unpruned
mkdir -p $unpruned_model_dir

pruned_model_dir=${pocolm_dir}/pruned
mkdir -p $pruned_model_dir

if [ $stage -le 0 ]; then

  $POCOLM/scripts/train_lm.py \
    --num-splits=5 \
    --num-words=$num_words \
    --warm-start-ratio=10 \
    --keep-int-data=true \
    --limit-unk-history=true \
      ${fold_dev_opt} \
    --min-counts=${min_count_opt} \
      ${pocolm_data_dir} ${order} ${lm_work_dir} ${unpruned_model_dir}

  $POCOLM/scripts/format_arpa_lm.py ${unpruned_model_dir} | gzip -c > $pocolm_arpa_file
  $POCOLM/scripts/get_data_prob.py $pocolm_data_dir/dev.txt $unpruned_model_dir 2>&1 | grep -F '[perplexity'
fi

if [ $stage -le 1 ]; then
  # pruning by size.
  $POCOLM/scripts/prune_lm_dir.py --target-num-ngrams=${size} --max-memory ${max_memory} ${unpruned_model_dir} ${pruned_model_dir} 2>&1 | tail -n 8 | head -n 6 | grep -v 'log-prob changes'
  $POCOLM/scripts/get_data_prob.py ${pocolm_data_dir}/dev.txt --max-memory ${max_memory} ${pruned_model_dir} 2>&1 | grep -F '[perplexity'
  $POCOLM/scripts/format_arpa_lm.py --max-memory ${max_memory} ${pruned_model_dir} | gzip -c > ${pocolm_dir}/${order}g_poco_pruned_${size}.arpa.gz
fi


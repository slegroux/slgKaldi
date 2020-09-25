#!/usr/bin/env bash

# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

compile_graph=true
mono=false

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
am=$3
graph=$4

nj=$(get_njobs $dataset)

if $compile_graph; then
  log_info "Compile HCLG"
  if [ "$mono" = true ]; then
    log_time utils/mkgraph.sh --mono ${lang} ${am} ${graph}
  else
    log_time utils/mkgraph.sh ${lang} ${am} ${graph}
  fi
fi

decode_dir=${am}/decode_$(basename ${dataset})
log_info "Decode test set $dataset"
log_time steps/decode.sh --nj $nj ${graph} ${dataset} ${decode_dir}
log_wer $decode_dir
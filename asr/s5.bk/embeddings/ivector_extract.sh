#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
ivector_extractor=$2
ivector_dir=$3

log_info "i-vector computation"
nj=$(get_njobs $dataset)

log_time steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj \
  ${dataset} ${ivector_extractor} ${ivector_dir}



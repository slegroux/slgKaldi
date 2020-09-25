#!/usr/bin/env bash

# Monophone training
# Arguments:
#   dataset, lang
# Outputs:
#   mono, (mono_ali)
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

mono_conf=conf/monophone.conf
# TODO: give subset option for monophone training on short utterances
subset=

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
mono=$3

log_info "MonoPhone Training"
nj=$(($(nproc)-2))

log_time steps/train_mono.sh \
  --nj $nj \
  --config ${mono_conf} \
  ${dataset} ${lang} ${mono}

log_info "Align MonoPhone"
log_time steps/align_si.sh --nj $nj ${dataset} ${lang} ${mono} ${mono}_ali

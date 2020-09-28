#!/usr/bin/env bash

# Monophone training
# Arguments:
#   dataset, lang
# Outputs:
#   mono, (mono_ali)
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

mono_config=conf/monophone.conf
# TODO(slegroux): give subset option for monophone training on short utterances
subset=
boost_silence=1.0
nj=100

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
mono=$3


log_info "MonoPhone Training"

if [ $subset ]; then
  log_info "train on ${subset} shortest utts only"
  utils/subset_data_dir.sh --shortest ${dataset} ${subset} ${dataset}_${subset}

  log_time steps/train_mono.sh --boost-silence ${boost_silence} \
  --nj $nj \
  --config ${mono_config} \
  ${dataset}_${subset} ${lang} ${mono}
else
  log_time steps/train_mono.sh --boost-silence ${boost_silence} \
    --nj $nj \
    --config ${mono_config} \
    ${dataset} ${lang} ${mono}
fi

log_info "Align MonoPhone"
log_time steps/align_si.sh --nj $nj --boost-silence ${boost_silence} ${dataset} ${lang} ${mono} ${mono}_ali
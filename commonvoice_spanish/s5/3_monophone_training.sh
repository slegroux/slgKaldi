#!/usr/bin/env bash

# Monophone training
# Arguments:
#   dataset, lang
# Outputs:
#   mono, (mono_ali)
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

mono_conf=conf/monophone.conf

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
mono=$3

echo "[INFO] MonoPhone Training "
nj=$(get_njobs $dataset)
# Train monophone model
time steps/train_mono.sh \
  --nj $nj \
  --config ${mono_conf} \
  ${dataset} ${lang} ${mono}

#Align the train data using mono-phone model
steps/align_si.sh --nj $nj ${dataset} ${lang} ${mono} ${mono}_ali

#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

set -euo pipefail

online_cmvn_iextractor=false

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
lang=$2
tri3=$3

nj=$(get_njobs $dataset)

# speed perturb
if [ ! -d ${dataset}_sp ]; then
  log_info "SP + alignment + mfcc"
  ./data_augment/make_sp.sh ${dataset}
fi

if [ ! -f ${dataset}_sp/feats.scp ]; then
  log_info "sp+mfcc"
  ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc.conf ${dataset}_sp
fi

if [ ! -d ${tri3}_sp_ali ]; then
  log_info "sp+mfcc+alig"
  steps/align_fmllr.sh --nj $nj \
    ${dataset}_sp ${lang} ${tri3} ${tri3}_sp_ali
fi

# volume perturb
if [ ! -d ${dataset}_sp_vp ]; then
  echo "VP"
  ./data_augment/make_vp.sh ${dataset}_sp
fi

# hires
if [ ! -d ${dataset}_sp_vp_hires ]; then
  echo "HIRES of sp_vp"
  mv ${dataset}_sp_vp ${dataset}_sp_vp_hires
  log_time ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${dataset}_sp_vp_hires
fi


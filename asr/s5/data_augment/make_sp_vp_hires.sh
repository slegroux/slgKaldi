#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1


if [ ! -d ${dataset}_sp ]; then
  log_info "Speed perturb"
  ./data_augment/make_sp.sh ${dataset}
fi

if [ ! -d ${dataset}_sp_vp ]; then
  log_info "Volume perturb: sp+vp -> mfcc"
  ./data_augment/make_vp.sh ${dataset}_sp
fi

if [ ! -d ${dataset}_sp_vp_hires ]; then
  echo "sp+vp->mfcc hires"
  utils/data/copy_data_dir.sh ${dataset}_sp_vp ${dataset}_sp_vp_hires
  log_time ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${dataset}_sp_vp_hires
fi
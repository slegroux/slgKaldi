#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# input:
#  train
# output:
#  lores train_sp & train_sp_ali
#  hires train_sp_vp_hires 

set -euo pipefail

online_cmvn_iextractor=false

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
lang=$2
tri3=$3

nj=$(get_njobs $dataset)

# speed perturb (for alignments)
if [ ! -d ${dataset}_sp ]; then
  log_info "Speed perturb"
  ./data_augment/make_sp.sh ${dataset}
fi

if [ ! -f ${dataset}_sp/feats.scp ]; then
  log_info "sp -> mfcc"
  log_time ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc.conf ${dataset}_sp
  utils/fix_data_dir.sh ${dataset}_sp
fi

if [ ! -f ${tri3}_sp_ali/ali.1.gz ]; then
  log_info "sp -> mfcc -> alig"
  log_time steps/align_fmllr.sh --nj $nj \
    ${dataset}_sp ${lang} ${tri3} ${tri3}_sp_ali
else
  log_info "alignments in ${tri3}_sp_ali appear to already exist"
fi

# add volume perturb to sp (for training ivec on hires)
# do volume-perturbation on the training data prior to extracting hires
# features; this helps make trained nnets more invariant to test data volume.

if [ ! -d ${dataset}_sp_vp ]; then
  log_info "Volume perturb: sp+vp -> mfcc"
  ./data_augment/make_vp.sh ${dataset}_sp
  log_time ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc.conf ${dataset}_sp_vp
fi

# hires
if [ ! -d ${dataset}_sp_vp_hires ]; then
  echo "sp+vp->mfcc hires"
  utils/data/copy_data_dir.sh ${dataset}_sp_vp ${dataset}_sp_vp_hires
  log_time ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${dataset}_sp_vp_hires
  utils/fix_data_dir.sh ${dataset}_sp_vp_hires
fi

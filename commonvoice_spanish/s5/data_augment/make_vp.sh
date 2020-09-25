#!/usr/bin/env bash

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1

log_info "volume perturb"
utils/copy_data_dir.sh $dataset ${dataset}_vp
# do volume-perturbation on the training data prior to extracting hires
# features; this helps make trained nnets more invariant to test data volume.
log_time utils/data/perturb_data_dir_volume.sh ${dataset}_vp 

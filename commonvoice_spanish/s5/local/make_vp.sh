#!/usr/bin/env bash

stage=0

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

dataset=$1

for f in data/${dataset}/feats.scp; do
  if [ ! -f $f ]; then
    echo "$0: expected file $f to exist"
    exit 1
  fi
done

if [ $stage -le 1 ]; then
 
  echo "$0: creating volume pertubations"
  utils/copy_data_dir.sh data/$dataset data/${dataset}_vp
  # do volume-perturbation on the training data prior to extracting hires
  # features; this helps make trained nnets more invariant to test data volume.
  utils/data/perturb_data_dir_volume.sh data/${dataset}_vp || exit 1;

fi
#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>
# train on hires data

set -euo pipefail

train_stage=-10
num_epochs=5

srand=0
chunk_width=150,110,100 #tedlium s5_r3
# chunk_width=140,100,160 #rdi
xent_regularize=0.1
dropout_schedule='0,0@0.20,0.5@0.50,0'
frames_per_iter=5000000

common_egs_dir=
remove_egs=false
reporting_email=
online_cmvn=false
n_gpu=8

. utils.sh
. path.sh
. utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

train_data_dir=$1
lat_dir=$2
ivector_data=$3
tree_dir=$4
dir=$5

#train_ivector_dir=data/${train_set}_x/xivectors
log_info "train dnn"

log_time steps/nnet3/chain/train.py --stage=$train_stage \
  --cmd="run.pl" \
  --feat.online-ivector-dir=${ivector_data} \
  --feat.cmvn-opts="--norm-means=false --norm-vars=false" \
  --chain.xent-regularize $xent_regularize \
  --chain.leaky-hmm-coefficient=0.1 \
  --chain.l2-regularize=0.0 \
  --chain.apply-deriv-weights false \
  --chain.lm-opts="--num-extra-lm-states=2000" \
  --trainer.dropout-schedule $dropout_schedule \
  --trainer.add-option="--optimization.memory-compression-level=2" \
  --egs.dir="$common_egs_dir" \
  --egs.opts="--frames-overlap-per-eg 0 --constrained false --online-cmvn $online_cmvn" \
  --egs.chunk-width=$chunk_width \
  --trainer.num-chunk-per-minibatch=64 \
  --trainer.frames-per-iter=$frames_per_iter \
  --trainer.num-epochs=${num_epochs} \
  --trainer.optimization.num-jobs-initial=$n_gpu \
  --trainer.optimization.num-jobs-final=$n_gpu \
  --trainer.optimization.initial-effective-lrate=0.00025 \
  --trainer.optimization.final-effective-lrate=0.000025 \
  --trainer.max-param-change 2.0 \
  --cleanup.remove-egs=$remove_egs \
  --use-gpu=wait \
  --feat-dir=$train_data_dir \
  --tree-dir=$tree_dir \
  --lat-dir=$lat_dir \
  --dir=$dir  || exit 1;

  # --trainer.srand=$srand \
  #--reporting.email="$reporting_email" \
  # --feat.cmvn-opts="--config=conf/online_cmvn.conf" \

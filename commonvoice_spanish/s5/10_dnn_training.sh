#!/usr/bin/env bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail


stage=14

gmm=tri3b
nnet3_affix=_online_cmn
# affix=f_ivec_specaug
#affix=1a76b #cnntdnn
affix=_xvector
tree_affix=
train_set=test

train_stage=-10
num_epochs=5

srand=0
chunk_width=140,100,160
xent_regularize=0.1

common_egs_dir=
remove_egs=false
reporting_email=
online_cmvn=true
n_gpu=8

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

set -x

dir=exp/chain${nnet3_affix}/tdnn${affix}
tree_dir=exp/chain${nnet3_affix}/tree
#train_ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires
#train_data_dir=data/${train_set}_sp_hires
#train_ivector_dir=data/${train_set}_hires/ivectors
train_ivector_dir=data/${train_set}_x/xivectors
train_data_dir=data/${train_set}_hires
#lat_dir=exp/chain${nnet3_affix}/${gmm}_${train_set}_sp_lats
lat_dir=data/${train_set}/${gmm}_lats

# sudo nvidia-smi -c 3

if [ $stage -le 14 ]; then
 
  steps/nnet3/chain/train.py --stage=$train_stage \
    --cmd="$decode_cmd" \
    --feat.online-ivector-dir=$train_ivector_dir \
    --feat.cmvn-opts="--config=conf/online_cmvn.conf" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient=0.1 \
    --chain.l2-regularize=0.0 \
    --chain.apply-deriv-weights=false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --trainer.srand=$srand \
    --trainer.max-param-change=2.0 \
    --trainer.num-epochs=$num_epochs \
    --trainer.frames-per-iter=3000000 \
    --trainer.optimization.num-jobs-initial=$n_gpu \
    --trainer.optimization.num-jobs-final=$n_gpu \
    --trainer.optimization.initial-effective-lrate=0.002 \
    --trainer.optimization.final-effective-lrate=0.0002 \
    --trainer.num-chunk-per-minibatch=128,64 \
    --egs.chunk-width=$chunk_width \
    --egs.dir="$common_egs_dir" \
    --egs.opts="--frames-overlap-per-eg 0 --online-cmvn $online_cmvn" \
    --cleanup.remove-egs=$remove_egs \
    --use-gpu=wait \
    --reporting.email="$reporting_email" \
    --feat-dir=$train_data_dir \
    --tree-dir=$tree_dir \
    --lat-dir=$lat_dir \
    --dir=$dir  || exit 1;
fi

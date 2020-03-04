#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail


stage=14

gmm=tri3b
nnet3_affix=
# affix=f_ivec_specaug
#affix=1a76b #cnntdnn
train_set=train
#affix=_xvector_${train_set}
affix=
tree_affix=

train_stage=135
num_epochs=150

srand=0
#chunk_width=140,100,160
chunk_width=150,110,100 #tedlium s5_r3
xent_regularize=0.1
dropout_schedule='0,0@0.20,0.5@0.50,0'
frames_per_iter=5000000

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
tree_dir=exp/chain${nnet3_affix}/tree_${train_set}
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
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.dropout-schedule $dropout_schedule \    
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --egs.dir="$common_egs_dir" \
    --egs.opts="--frames-overlap-per-eg 0 --constrained false --online-cmvn $online_cmvn" \
    --egs.chunk-width=$chunk_width \
    --trainer.num-chunk-per-minibatch=64 \
    --trainer.frames-per-iter=$frames_per_iter \
    --trainer.num-epochs=$num_epochs \
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

fi

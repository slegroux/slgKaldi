#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

set -euo pipefail

xent_regularize=0.1

. utils.sh
. path.sh
. utils/parse_options.sh

tree_dir=$1
dir=$2

mkdir -p $dir
echo "$0: creating neural net configs using the xconfig parser";

num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)
affine_opts="l2-regularize=0.008 dropout-proportion=0.0 dropout-per-dim-continuous=true"
tdnnf_opts="l2-regularize=0.008 dropout-proportion=0.0 bypass-scale=0.66"
linear_opts="l2-regularize=0.008 orthonormal-constraint=-1.0"
prefinal_opts="l2-regularize=0.008"
output_opts="l2-regularize=0.002"

dim=1024
bottleneck_dim=128

mkdir -p $dir/configs
cat <<EOF > $dir/configs/network.xconfig
input dim=100 name=ivector
input dim=40 name=input

fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat

# the first splicing is moved before the lda layer, so no splicing here
relu-batchnorm-dropout-layer name=tdnn1 $affine_opts dim=$dim
tdnnf-layer name=tdnnf2 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=1
tdnnf-layer name=tdnnf3 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=1
tdnnf-layer name=tdnnf4 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=1
tdnnf-layer name=tdnnf5 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=0
tdnnf-layer name=tdnnf6 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf7 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf8 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf9 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf10 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf11 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf12 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
tdnnf-layer name=tdnnf13 $tdnnf_opts dim=$dim bottleneck-dim=$bottleneck_dim time-stride=3
linear-component name=prefinal-l dim=256 $linear_opts

## adding the layers for chain branch
prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts small-dim=256 big-dim=$dim
output-layer name=output include-log-softmax=false dim=$num_targets $output_opts

# adding the layers for xent branch
prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts small-dim=256 big-dim=$dim
output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF
steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
# if [ $dir/init/default_trans.mdl ]; then # checking this because it may have been copied in a previous run of the same script
#     copy-transition-model $tree_dir/final.mdl $dir/init/default_trans.mdl  || exit 1 &
# else
#     echo "Keeping the old $dir/init/default_trans.mdl as it already exists."
# fi

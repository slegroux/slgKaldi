#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

xent_regularize=0.1
l2_regularize_begin=0.008
l2_regularize_end=0.002
bypass_scale=0.75
ivector_dim=100
mfcc_dim=40
layer_dim=1536
bottleneck_dim=160
small_dim=256

. utils.sh
. path.sh
. utils/parse_options.sh

tree_dir=$1
dir=$2

mkdir -p $dir
echo "$0: creating neural net configs using the xconfig parser";

num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)

tdnn_opts="l2-regularize=${l2_regularize_begin}"
tdnnf_opts="l2-regularize=${l2_regularize_begin} bypass-scale=${bypass_scale}"
linear_opts="l2-regularize=${l2_regularize_begin} orthonormal-constraint=-1.0"
prefinal_opts="l2-regularize=${l2_regularize_begin}"
output_opts="l2-regularize=${l2_regularize_end}"

mkdir -p $dir/configs
cat <<EOF > $dir/configs/network.xconfig
input dim=${ivector_dim} name=ivector
input dim=${mfcc_dim} name=input

relu-batchnorm-dropout-layer name=tdnn1 $tdnn_opts dim=${layer_dim}
tdnnf-layer name=tdnnf2 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=1
tdnnf-layer name=tdnnf3 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=1
tdnnf-layer name=tdnnf4 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=1
tdnnf-layer name=tdnnf5 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=0
tdnnf-layer name=tdnnf6 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf7 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf8 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf9 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf10 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf11 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf12 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf13 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf14 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf15 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf16 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
tdnnf-layer name=tdnnf17 $tdnnf_opts dim=${layer_dim} bottleneck-dim=${bottleneck_dim} time-stride=3
linear-component name=prefinal-l dim=${small_dim} $linear_opts

## adding the layers for chain branch
prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts small-dim=${small_dim} big-dim=${layer_dim}
output-layer name=output include-log-softmax=false dim=$num_targets $output_opts

# adding the layers for xent branch
prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts small-dim=${small_dim} big-dim=${layer_dim}
output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF
steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/

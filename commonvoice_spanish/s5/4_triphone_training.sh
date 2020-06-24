#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
train_set=train
mono_ali_set=mono_ali

# end configuration section
. ./path.sh
. utils/parse_options.sh


echo ============================================================================
echo " tri1 : TriPhone with delta delta-delta features Training      "
echo ============================================================================

#Train Deltas + Delta-Deltas model based on mono_ali
# parameters from heroico
cluster_thresh=100
num_leaves=1500
tot_gauss=25000

steps/train_deltas.sh --cluster-thresh $cluster_thresh $num_leaves $tot_gauss data/${training_set} data/lang exp/${mono_ali_set} exp/tri1

#Align the train data using tri1 model
steps/align_si.sh --nj $njobs data/${train_set} data/lang exp/tri1 exp/tri1_ali

#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

stage=0

train_set=train_sp_vp
train_lores=train_sp
train_ivector_dir=data/${train_set}_hires/ivectors
xvector_dir=data/${train_set}_x/xvectors
xivector_dir=data/${train_set}_x/xivectors
train_data_dir=data/${train_set}_hires
ivector_extractor=exp/nnet3_${train_set}/extractor
tree=exp/chain/tree_train_sp
lat_dir=data/train_sp/tri3b_lats
#ivector_dir=data/${train_set}_hires/ivectors
model_dir=exp/chain/tdnnf_tedlium_${train_set}
model_dir_xvec=exp/chain/tdnnf_tedlium_train_sp_vp_xvec
test_set=test
graph=exp/chain/tree_train_sp/graph_tgsmall

. cmd.sh
. path.sh
. utils/parse_options.sh 

# 
if [ $stage -le 0 ]; then

#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

stage=0

train_set=train_sp_vp
train_ivector_dir=data/${train_set}_hires/ivectors
train_data_dir=data/${train_set}_hires
ivector_extractor=exp/nnet3_${train_set}/extractor
tree=exp/chain/tree_train_sp
lat_dir=data/train_sp/tri3b_lats
#ivector_dir=data/${train_set}_hires/ivectors
model_dir=exp/chain/tdnnf_tedlium_${train_set}
test_set=test

. cmd.sh
. path.sh
. utils/parse_options.sh 

# train ivectors
if [ $stage -le 0 ]; then
    ./7_ivector_training.sh --train_set ${train_set}
fi

if [ $stage -le 1 ]; then
    # if training on non sp_vp_hires need to compute mfcc feats
    ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor \
        $train_set
fi

if [ $stage -le 2 ]; then
    ./8_dnn_prep.sh --train_set $train_set --train_ivector_dir $train_ivector_dir \
        --train_data_dir $train_data_dir
fi

if [ $stage -le 3 ]; then
    ./9_tdnnf_tedlium_s5_r3.sh --dir $model_dir \
        --tree-dir $tree #--stage 12 || exit 1
fi

if [ $stage -le 4 ]; then
    ./10_dnn_training.sh --dir $model_dir --train_set ${train_set} --tree_dir $tree \
        --lat_dir $lat_dir || exit 1
fi

if [ $stage -le 5 ]; then
    #if other ivector extractor was used to generate ${test_set}_hires
    rm -rf data/${test_set}_hires 
    ./10a_dnn_testing.sh --dir $model_dir --tree_dir $tree \
        --ivector_extractor $ivector_extractor $test_set
fi
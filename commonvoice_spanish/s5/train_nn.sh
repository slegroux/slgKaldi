#!/usr/bin/env bash
stage=0

train_set=train1000
ivector_extractor=exp/nnet3_${train_set}/extractor
tree=exp/chain/tree_${train_set}
ivector_dir=data/${train_set}_hires/ivectors
model_dir=exp/chain/tdnnf_tedlium_${train_set}
test_set=test35


. cmd.sh
. path.sh
. utils/parse_options.sh 

# train ivectors
if [ $stage -eq 0 ]; then
    ./7_ivector_training.sh --train_set ${train_set}
fi

if [ $stage -eq 111 ]; then
    # if training on non sp_vp_hires need to compute mfcc feats
    ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor \
        $train_set
fi

if [ $stage -eq 1 ]; then
    ./8_dnn_prep.sh --train_set $train_set
fi

if [ $stage -eq 2 ]; then
    ./9_tdnnf_tedlium_s5_r3.sh --dir $model_dir \
        --tree-dir $tree
fi

if [ $stage -eq 3 ]; then
    ./10_dnn_training.sh --dir $model_dir --train_set ${train_set}
fi

if [ $stage -eq 4 ]; then
    ./10a_dnn_testing.sh --dir $model_dir --tree_dir $tree \
        --ivector_extractor $ivector_extractor $test_set
fi
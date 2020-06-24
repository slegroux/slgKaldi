#!/usr/bin/env bash

stage=0
gmm=tri3b #tri3b_train_aug
online_cmvn_iextractor=true
train_set=train_1000
test_set=test35

. cmd.sh
. path.sh
. utils/parse_options.sh

njobs=$(($(nproc)-1))

# # DATA AUGMENTATION
# stage=0
# aug_list="reverb babble music noise clean" # Original train dir is referred to as `clean`
# num_reverb_copies=1
# use_ivectors=false
# train_set=train
# clean_ali=tri3b_ali
# ./6a_data_aug.sh --stage $stage --aug_list $aug_list --num_reverb_copies $num_reverb_copies --use_ivectors $use_ivectors \
#     --train_set $train_set --clean_ali $clean_ali

if [ $stage -eq 0 ]; then
    # generates ivectors and speed perturbated data + low & hires mfcc
    # output model in: exp/nnet3_${train_set}_sp_vp/extractor 
    ./7_ivector_training.sh --gmm $gmm --online_cmvn_iextractor $online_cmvn_iextractor --train_set $train_set
fi

if [ $stage -eq 1 ]; then
    # if training on non sp_vp_hires need to compute mfcc feats
    ivector_extractor=exp/nnet3_${train_set}_sp_vp/extractor
    for dataset in {$train_set,$test_set}; do
        ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor $dataset
    done
fi
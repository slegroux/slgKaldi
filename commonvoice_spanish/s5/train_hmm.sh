#!/usr/bin/env bash

stage=1

. cmd.sh
. path.sh
. utils/parse_options.sh

# init
data=$DATA/es/common_voice
train_set=train_1000
test_set=test35
njobs=$(($(nproc)-1))

if [ $stage -eq 0 ]; then
# data prep specific to each dataset
    ./1_data_prep.sh
fi

if [ $stage -eq 1 ]; then
# compute features for both train & test sets
    ./2_feature_extraction.sh --njobs $njobs --stage 5 --train_set $train_set --test_set $test_set
fi

exit 1
stage=6
training_set=train #train_aug
./3_monophone_training.sh --njobs $njobs --stage $stage --training_set $training_set

# TRIPHONE TRAINING
# generates tri1 & tri1_ali
stage=7
njobs=$(($(nproc)-1))
training_set=train #train_aug
mono_ali_set=mono_ali #mono_train_aug_ali
./4_triphone_training.sh --njobs $njobs --training_set $training_set --mono_ali_set $mono_ali_set

# LDA MLLT
# generate tri2b & tri2b_ali
stage=8
njobs=$(($(nproc)-1))
train="train" #train_aug
tri1_ali="tri1_ali" #tri1_train_aug_ali"
./5_lda_mllt_training.sh --njobs $njobs --train $train --tri1_ali $tri1_ali

# SAT
# generrates tri3b & tri3b_ali & tri3b_ali_test
stage=9
njobs=$(($(nproc)-1))
train=train #train_aug
tri2b_ali=tri2b_ali #tri2b_train_aug_ali
./6_sat_training.sh --njobs $njobs --train $train --tri2b_ali $tri2b_ali

# DATA AUGMENTATION
stage=0
aug_list="reverb babble music noise clean" # Original train dir is referred to as `clean`
num_reverb_copies=1
use_ivectors=false
train_set=train
clean_ali=tri3b_ali
./6a_data_aug.sh --stage $stage --aug_list $aug_list --num_reverb_copies $num_reverb_copies --use_ivectors $use_ivectors \
    --train_set $train_set --clean_ali $clean_ali

# IVECTOR
# generates ivectors and speed perturbated data + low & hires mfcc
njobs=$(($(nproc)-1))
gmm=tri3b #tri3b_train_aug
online_cmvn_iextractor=true
nnet3_affix=_online_cmn #_online_cmn_aug
train_set=train #train_aug
test_sets=test
stage=0

./7_ivector_training.sh --njobs $njobs --gmm $gmm --online_cmvn_iextractor $online_cmvn_iextractor \
    --nnet3_affix $nnet3_affix --train_set $train_set --test_sets $test_sets
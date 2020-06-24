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

if [ $stage -eq 2 ]; then
    ./3_monophone_training.sh --njobs $njobs --subset 100 --training_set $train_set
    ./3a_monophone_testing.sh --njobs $njobs --test_set $test_set
fi

if [ $stage -eq 3 ]; then
    # generates tri1 & tri1_ali
    mono_ali_set=mono_ali #mono_train_aug_ali
    # ./4_triphone_training.sh --njobs $njobs --train_set $train_set --mono_ali_set $mono_ali_set
    ./4a_triphone_testing.sh --njobs $njobs --test_set $test_set
fi

if [ $stage -eq 4 ]; then
    # generate tri2b & tri2b_ali
    tri1_ali="tri1_ali" #tri1_train_aug_ali"
    ./5_lda_mllt_training.sh --njobs $njobs --train_set $train_set --tri1_ali $tri1_ali
    ./5a_lda_mllt_testing.sh --njobs $njobs --test_set $test_set
fi

if [ $stage -eq 5 ]; then
    # generrates tri3b & tri3b_ali & tri3b_ali_test
    tri2b_ali=tri2b_ali #tri2b_train_aug_ali
    ./6_sat_training.sh --njobs $njobs --train_set $train_set --tri2b_ali $tri2b_ali
    ./6a_sat_testing.sh --njobs $njobs --test_set $test_set
fi


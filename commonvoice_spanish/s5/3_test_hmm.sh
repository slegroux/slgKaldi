#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=0

. path.sh
. utils/parse_options.sh

# datasets
train_set=data/train500
test_set=data/test35

# lang
lang_train=data/lang
lang_test=data/lang_test

# mono
mono=exp/mono_500
if [ "$stage" == 1 ]; then
    ./hmm/monophone_training.sh ${train_set} ${lang_train} ${mono}
fi

if [ "$stage" == 11 ]; then
    ./hmm/am_testing.sh --mono true --compile_graph false ${test_set} ${lang_test} ${mono} ${mono}/graph
fi

# tri
mono_ali=exp/mono_500_ali
tri1=exp/tri1_500
if [ "$stage" == 2 ]; then
    ./hmm/triphone_training.sh ${train_set} ${lang_train} ${mono_ali} ${tri1}
fi

if [ "$stage" == 21 ]; then
    ./hmm/am_testing.sh --mono false --compile_graph true ${test_set} ${lang_test} ${tri1} ${tri1}/graph
fi

# lda mllt
tri1_ali=exp/tri1_500_ali
tri2=exp/tri2_500
if [ "$stage" == 3 ]; then
    ./hmm/lda_mllt_training.sh ${train_set} ${lang_train} ${tri1_ali} ${tri2}
fi

if [ "$stage" == 31 ]; then
    ./hmm/am_testing.sh --mono false --compile_graph true ${test_set} ${lang_test} ${tri2} ${tri2}/graph
fi

# sat
tri2_ali=exp/tri2_500_ali
tri3=exp/tri3_500
if [ "$stage" == 3 ]; then
    ./hmm/sat_training.sh ${train_set} ${lang_train} ${tri2_ali} ${tri3}
fi
if [ "$stage" == 3 ]; then
    ./hmm/am_testing.sh --mono false --compile_graph true ${test_set} ${lang_test} ${tri3} ${tri3}/graph
fi


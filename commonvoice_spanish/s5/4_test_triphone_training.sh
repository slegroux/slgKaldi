#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500
test_set=data/test35
train_lang=data/lang
test_lang=data/lang_test
ali=exp/mono_500_ali
tri1=exp/tri1_500 #output

# ./4_triphone_training.sh ${train_set} ${train_lang} ${ali} ${tri1}
./3a_am_testing.sh --mono false --compile_graph true ${test_set} ${test_lang} ${tri1} ${tri1}/graph
#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500
test_set=data/test35
lang=data/lang
lang_test=data/lang_test
mono=exp/mono_500

./3_monophone_training.sh ${train_set} ${lang} ${mono}
./3a_am_testing.sh --mono true --compile_graph false ${test_set} ${lang_test} ${mono} ${mono}/graph
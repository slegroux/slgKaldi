#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500
test_set=data/test35
train_lang=data/lang
test_lang=data/lang_test

tri2_ali=exp/tri2_500_ali
tri3=exp/tri3_500

./6_sat_training.sh ${train_set} ${train_lang} ${tri2_ali} ${tri3}
./3a_am_testing.sh --mono false --compile_graph true ${test_set} ${test_lang} ${tri3} ${tri3}/graph
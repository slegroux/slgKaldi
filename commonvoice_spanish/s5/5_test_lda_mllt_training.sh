#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500
test_set=data/test35
train_lang=data/lang
test_lang=data/lang_test

tri1_ali=exp/tri1_500_ali
tri2=exp/tri2_500

./5_lda_mllt_training.sh ${train_set} ${train_lang} ${tri1_ali} ${tri2}
./3a_am_testing.sh --mono false --compile_graph true ${test_set} ${test_lang} ${tri2} ${tri2}/graph
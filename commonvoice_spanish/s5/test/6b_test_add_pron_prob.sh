#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500
test_set=data/test35
train_lang=data/lang
test_lang=data/lang_test
test_lang_pp=data/lang_pp_test
tri3=exp/tri3_500
dict=data/local/dict
# ./6b_add_pron_prob.sh ${train_set} ${train_lang} ${test_lang} ${tri3} ${dict}
./3a_am_testing.sh --mono false --compile_graph false ${test_set} ${test_lang_pp} ${tri3} ${tri3}/graph_pp
#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

data_prep=0
lang=1
grammar=2
features=3
hmm=4
hmm_test=41
ivector_train=5
ivector_extract=6
dnn_train=7
dnn_test=71
ngram_rescore=8
online_decode=10


for i in 7 8 9 10 11; do
    ./run_exp.sh --stage $i cfg/mini_librispeech.cfg 
done

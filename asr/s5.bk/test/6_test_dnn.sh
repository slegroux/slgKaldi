#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

set -x
# basic data
dataset=data/train500
test_set=data/test35
# lang
lang=data/lang
lang_test=data/lang_test
lang_chain=data/lang_chain_500
# am
tri3=exp/tri3_500
# ivectors
train_data=${dataset}_sp_vp_hires
ivector_data=${train_data}/ivectors
ivector_test_data=${test_set}_hires/ivectors
lat_dir=${tri3}_sp_vp_ali_lats
ivec_model=exp/ivector_500_sp_vp_hires
ivec_extractor=${ivec_model}/extractor
# dnn-mdl
tree=exp/chain/tree_train_500 #TODO(sylvain): change to chain2
mdl=exp/chain/tdnnf_tedlium_train_500
# training
train_stage=-10
num_epochs=3
n_gpu=1

# implicitely align on train_500_sp and generate align lats on sp_vp_lats
# ./dnn/make_lang_chain.sh ${dataset}_sp_vp ${tri3} ${lang} ${lang_chain} ${tree}
# ./dnn/tdnnf_tedlium_s5_r3.sh ${tree} ${mdl}
# ./dnn/dnn_training.sh --train_stage ${train_stage} --num_epochs $num_epochs --n_gpu $n_gpu \
#     ${train_data} ${lat_dir} ${ivector_data} ${tree} ${mdl}
./embeddings/ivector_extract.sh ${test_set}_hires ${ivec_extractor} ${test_set}_hires/ivectors
./dnn/dnn_testing.sh --compute_graph false ${test_set} ${lang_test} ${tree} ${ivector_test_data} ${mdl}




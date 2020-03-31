#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

set -euo pipefail

stage=0

#train_set=train_sp_vp
train_set=train_combined
train_data_dir=data/${train_set}_hires
train_lores=train_sp
test_set=test
train_ivector_dataset=train_sp_vp

train_ivector_dir=data/${train_set}_hires/ivectors
ivector_extractor=exp/nnet3_${train_ivector_dataset}/extractor

train_xvector_dir=data/${train_set}_x/xvectors
xivector_dir=data/${train_set}_x/xivectors
xvector_extractor=$DATA/voxceleb/0007_voxceleb_v2_1a/exp/xvector_nnet_1a

tree=exp/chain/tree_train_sp
lat_dir=data/${train_set}/tri3b_lats
#ivector_dir=data/${train_set}_hires/ivectors
model_dir=exp/chain/tdnnf_tedlium_${train_set}
#model_dir_xvec=exp/chain/tdnnf_tedlium_${train_set}_xvec
model_dir_xvec=exp/chain/cnn_tdnnf_rdi_${train_set}_xvec
lang_chain=data/lang_chain
graph=exp/chain/tree_${train_lores}/graph_tgsmall

rnnlm_dir=exp/rnnlm
rnnlm_epochs=40
n_gpu=8
wordlist=${lang_chain}/words.txt
rnnlm_data=data/rnnlm

num_epochs=30
train_stage=-10


. cmd.sh
. path.sh
. utils/parse_options.sh 

# train ivectors
if [ $stage -le 0 ]; then
    ./7_ivector_training.sh --train_set ${train_set} 
fi

if [ $stage -le 1 ]; then
    # if training on non sp_vp_hires need to compute mfcc feats
    ./7a_ivector_extract.sh --ivector_extractor $ivector_extractor \
        $train_set 
fi

if [ $stage -le 2 ]; then
    ./8_dnn_prep.sh --stage 7 --train_set $train_set --train_ivector_dir $train_ivector_dir || exit 1
fi

if [ $stage -le 3 ]; then
    ./9_tdnnf_tedlium_s5_r3.sh --dir $model_dir \
        --tree-dir $tree #--stage 12 || exit 1
fi

if [ $stage -le 4 ]; then
    ./10_dnn_training.sh --train_stage -10 --num_epochs $num_epochs --dir $model_dir --train_set ${train_set} --tree_dir $tree \
        --lat_dir $lat_dir --train_ivector_dir $train_ivector_dir 
fi

if [ $stage -le 5 ]; then
    #if other ivector extractor was used to generate ${test_set}_hires
    #rm -rf data/${test_set}_hires 
    ./10a_dnn_testing.sh --dir $model_dir --tree_dir $tree \
        --ivector_extractor $ivector_extractor $test_set
fi

if [ $stage -le 6 ]; then
    ./13_prepare_online_decoding.sh --stage 0 --model $model_dir --online_model ${model_dir}_online \
        --extractor $ivector_extractor --graph $graph --test_set test35
fi

# train rnnlm
if [ $stage -le 7 ]; then
    ./local/rnnlm/run_lstm_tdnn.sh --dir $rnnlm_dir --epochs $rnnlm_epochs --n_gpu $n_gpu \
        --wordlist $wordlist --text_dir $rnnlm_data
fi

# test rnnlm
if [ $stage -le 7 ]; then
    ./local/rnnlm/rescore_vca.sh --rnnlm_dir $rnnlm_dir --lang_dir data/lang_test --test_set $test_set \
        --model $model_dir
fi

# exit 1
# XVector training

# if [ $stage -le 110 ]; then
#     ./9_tdnnf_tedlium_s5_r3_xvec.sh --dir $model_dir_xvec \
#         --tree-dir $tree #--stage 12 || exit 1
# fi


if [ $stage -le 110 ]; then
    ./7c_xvector_extract.sh --xvector_extractor $xvector_extractor $train_set
    ./7d_concat_xivectors.sh $train_ivector_dir $train_xvector_dir $xivector_dir
fi

if [ $stage -le 111 ]; then
    ./9_cnn_tdnnf_rdi_xvec.sh --dir $model_dir_xvec \
        --tree-dir $tree #--stage 12 || exit 1
fi

if [ $stage -le 112 ]; then
    ./10_dnn_training.sh --train_stage $train_stage --num_epochs $num_epochs --train_set $train_set --dir $model_dir_xvec --tree_dir $tree \
        --lat_dir $lat_dir --train_data_dir $train_data_dir --train_ivector_dir $xivector_dir
fi

if [ $stage -le 113 ]; then
    ./10b_dnn_xvector_testing.sh --dir $model_dir_xvec --tree_dir $tree \
        --ivector_extractor $ivector_extractor --xvector_extractor $xvector_extractor \
        ${test_set}
fi

if [ $stage -eq 114 ]; then
    ./13_prepare_online_decoding.sh --stage 0 --model $model_dir_xvec --online_model ${model_dir_xvec}_online \
        --extractor $ivector_extractor --graph $graph --test_set test35
fi

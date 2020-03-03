#!/usr/bin/env bash

# DATA PREP
data='/home/workfit/Sylvain/Data/Librifrench' # Set this to directory where you put the data
adapt=false # Set this to true if you want to make the data as the vocabulary file,
	    # example: dès que (original text) => dès_que (vocabulary word)
liaison=true # Set this to true if you want to makes lexicon while taking into account liaison for French language
stage=0
data_train=train
data_test=test

./1_data_prep.sh --data $data --adapt $adapt --stage $stage --data_train $data_train --data_test $data_test

# MFCC / PLP EXTRACTION
njobs=$(($(nproc)-1))
stage=5
train_set=train
test_set=test
./2_feature_extraction.sh --njobs $njobs --stage $stage --train_set $train_set --test_set $test_set



# MONOPHONE TRAINING
# generate mono & mono_ali
njobs=$(($(nproc)-1))
stage=6
training_set=train #train_aug
./3_monophone_training.sh --njobs $njobs --stage $stage --training_set $training_set

# TRIPHONE TRAINING
# generates tri1 & tri1_ali
stage=7
njobs=$(($(nproc)-1))
training_set=train #train_aug
mono_ali_set=mono_ali #mono_train_aug_ali
./4_triphone_training.sh --njobs $njobs --training_set $training_set --mono_ali_set $mono_ali_set

# LDA MLLT
# generate tri2b & tri2b_ali
stage=8
njobs=$(($(nproc)-1))
train="train" #train_aug
tri1_ali="tri1_ali" #tri1_train_aug_ali"
./5_lda_mllt_training.sh --njobs $njobs --train $train --tri1_ali $tri1_ali

# SAT
# generrates tri3b & tri3b_ali & tri3b_ali_test
stage=9
njobs=$(($(nproc)-1))
train=train #train_aug
tri2b_ali=tri2b_ali #tri2b_train_aug_ali
./6_sat_training.sh --njobs $njobs --train $train --tri2b_ali $tri2b_ali

# DATA AUGMENTATION
stage=0
aug_list="reverb babble music noise clean" # Original train dir is referred to as `clean`
num_reverb_copies=1
use_ivectors=false
train_set=train
clean_ali=tri3b_ali
./6a_data_aug.sh --stage $stage --aug_list $aug_list --num_reverb_copies $num_reverb_copies --use_ivectors $use_ivectors \
    --train_set $train_set --clean_ali $clean_ali

# IVECTOR
# generates ivectors and speed perturbated data + low & hires mfcc
njobs=$(($(nproc)-1))
gmm=tri3b #tri3b_train_aug
online_cmvn_iextractor=true
nnet3_affix=_online_cmn #_online_cmn_aug
train_set=train #train_aug
test_sets=test
stage=0

./7_ivector_training.sh --njobs $njobs --gmm $gmm --online_cmvn_iextractor $online_cmvn_iextractor \
    --nnet3_affix $nnet3_affix --train_set $train_set --test_sets $test_sets

# DNN PREP
# generates: lang & tree for chain-type topology
n_speakers_test_set=$(cat data/test/spk2utt| wc -l)
stage=10
decode_nj=$n_speakers_test_set
njobs=$(($(nproc)-1))
train_set=train #train_aug
test_sets=test #test
gmm=tri3b #tri3b_train_aug
nnet3_affix=_online_cmn #_online_cmn_aug
tree_affix=
./8_dnn_prep.sh --decode_nj $decode_nj --njobs $njobs \
    --train_set $train_set --test_sets $test_sets --gmm $gmm \
    --nnet3_affix $nnet3_affix

# TDNN CONF
# generate config file for tdnn
stage=13
nnet3_affix=_online_cmn #_online_cmn_aug
affix=1k
tree_affix=
xent_regularize=0.1
./9_tdnn_config.sh --nnet3_affix $nnet3_affix

# DNN TRAINING
gmm=tri3b #tri3b_train_aug
nnet3_affix=_online_cmn #_online_cmn_aug
affix=1k #tdnn
#affix=1a76b #cnntdnn
tree_affix=
lang_test=data/lang_test_SRILM

train_set=train
test_sets=test

train_stage=-10
online_cmvn=true #tdnn
#online_cmvn=false #cnn-tdnn

srand=0
chunk_width=140,100,160
common_egs_dir=
remove_egs=false
reporting_email=

xent_regularize=0.1
dir=exp/chain${nnet3_affix}/tdnn${affix}_sp

./10_dnn_training.sh --gmm $gmm --nnet3_affix $nnet3_affix \
    --affix $affix --train_set $train_set --online_cmvn $online_cmvn
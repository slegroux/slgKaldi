#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
train_set=train
tri1_ali=tri1_ali

. ./path.sh
. utils/parse_options.sh


echo ============================================================================
echo " tri2b : LDA + MLLT Training & Decoding / Speaker Adaptation"
echo ============================================================================

#Train LDA + MLLT model based on tri1_ali
# parameters from heroico
num_leaves=3100
tot_gauss=50000

steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" \
  $num_leaves $tot_gauss data/${train_set} data/lang exp/${tri1_ali} exp/tri2b

steps/align_si.sh --nj $njobs data/${train_set} data/lang exp/tri2b exp/tri2b_ali

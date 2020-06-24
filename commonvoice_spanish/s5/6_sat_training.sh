#!/bin/bash
# 2020 slegroux@ccrma.stanford.edu

njobs=$(($(nproc)-1))
train_set=train
tri2b_ali=tri2b_ali

# end configuration section
. ./path.sh
. utils/parse_options.sh

echo ============================================================================
echo " tri3b : LDA+MLLT+SAT Training "
echo ============================================================================

# Train GMM SAT model based on Tri2b_ali
# parameters from heroico & same as lda_mllt
num_leaves=3100
tot_gauss=50000
steps/train_sat.sh $num_leaves $tot_gauss data/${train_set} data/lang exp/${tri2b_ali} exp/tri3b

# Align the train data using tri3b model
steps/align_fmllr.sh --nj $njobs data/${train_set} data/lang exp/tri3b exp/tri3b_ali
# steps/align_fmllr.sh --nj $n_speakers_test data/test data/lang exp/${tri3b} exp/${tri3b_ali}_test

#!/bin/bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

nj=$(($(nproc)-2))

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
tri1_ali=$3
tri2=$4

log_info "LDA + MLLT training / speaker adaptation"

# parameters from heroico
num_leaves=3100
tot_gauss=50000

log_time steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" \
  $num_leaves $tot_gauss ${dataset} ${lang} ${tri1_ali} ${tri2}

log_info "Lda mllt alignement"
log_time steps/align_si.sh --nj $nj ${dataset} ${lang} ${tri2} ${tri2}_ali

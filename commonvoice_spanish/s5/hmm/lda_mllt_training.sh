#!/bin/bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
tri1_ali=$3
tri2=$4

nj=$(get_njobs $dataset)

log_info "LDA + MLLT training / speaker adaptation"

declare -A heroico=( ["num_leaves"]=3100 ["tot_gauss"]=50000 )
declare -A minilibri=( ["num_leaves"]=2500 ["tot_gauss"]=15000 )

num_leaves="${heroico["num_leaves"]}"
tot_gauss="${heroico["tot_gauss"]}"

log_time steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" \
  $num_leaves $tot_gauss ${dataset} ${lang} ${tri1_ali} ${tri2}

log_info "Lda mllt alignement"
log_time steps/align_si.sh --nj $nj ${dataset} ${lang} ${tri2} ${tri2}_ali

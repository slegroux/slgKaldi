#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
tri2_ali=$3
tri3=$4

nj=$(get_njobs $dataset)

log_info "SAT Training"
# parameters from heroico & same as lda_mllt
declare -A heroico=( ["num_leaves"]=3100 ["tot_gauss"]=50000 )
declare -A minilibri=( ["num_leaves"]=2500 ["tot_gauss"]=15000 )
num_leaves="${heroico["num_leaves"]}"
tot_gauss="${heroico["tot_gauss"]}"
log_time steps/train_sat.sh $num_leaves $tot_gauss ${dataset} ${lang} ${tri2_ali} ${tri3}

log_info "Align fmllr"
log_time steps/align_fmllr.sh --nj $nj ${dataset} ${lang} ${tri3} ${tri3}_ali

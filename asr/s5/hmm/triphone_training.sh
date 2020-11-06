#!/usr/bin/env bash

# Triphone training
# Arguments:
#   dataset, lang, mono_ali
#   clustering param (thre,leaves,gauss)
# Outputs:
#   tri, (tri_ali)
# 
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

boost_silence=1.0
cluster_thresh=100
num_leaves=1500
tot_gauss=25000

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
lang=$2
mono_ali=$3
tri=$4

nj=$(get_njobs $dataset)

log_info "Triphone delta training"
# declare -A heroico=( ["cluster_thresh"]=100 ["num_leaves"]=1500 ["tot_gauss"]=25000 )
# declare -A minilibri=( ["cluster_thresh"]=-1 ["num_leaves"]=2000 ["tot_gauss"]=10000 )

log_time steps/train_deltas.sh --boost-silence ${boost_silence} --cluster-thresh $cluster_thresh $num_leaves $tot_gauss ${dataset} ${lang} ${mono_ali} ${tri}
log_info "Triphone alignment"
log_time steps/align_si.sh --nj $nj --boost-silence ${boost_silence} ${dataset} ${lang} ${tri} ${tri}_ali

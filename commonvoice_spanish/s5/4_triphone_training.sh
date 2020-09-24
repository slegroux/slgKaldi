#!/usr/bin/env bash

# Triphone training
# Arguments:
#   dataset, lang, mono_ali
#   clustering param (thre,leaves,gauss)
# Outputs:
#   tri, (tri_ali)
# 
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

njobs=$(($(nproc)-2))

. path.sh
. utils/parse_options.sh
. utils.sh

dataset=$1
lang=$2
mono_ali=$3
tri=$4

# log_info "Triphone delta training"
# # parameters from heroico
# cluster_thresh=100
# num_leaves=1500
# tot_gauss=25000
# log_time steps/train_deltas.sh --cluster-thresh $cluster_thresh $num_leaves $tot_gauss ${dataset} ${lang} ${mono_ali} ${tri}

log_info "Triphone alignment"
log_time steps/align_si.sh --nj $njobs ${dataset} ${lang} ${tri} ${tri}_ali

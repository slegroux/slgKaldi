#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1

# Although the nnet will be trained by high resolution data, we still have to
# perturb the normal data to get the alignment _sp stands for speed-perturbed
log_info "Speed perturb"
log_time utils/data/perturb_data_dir_speed_3way.sh ${dataset} ${dataset}_sp
# utils/utt2spk_to_spk2utt.pl ${dataset}/utt2spk > data/${dataset}/spk2utt
utils/fix_data_dir.sh ${dataset}_sp
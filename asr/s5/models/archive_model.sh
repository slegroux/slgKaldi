#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=0

. utils.sh
. path.sh
. utils/parse_options.sh


today=$(date +'%Y%m%d')

model_dir=$1
graph=$2
archive_name=$3

tar -zvcp --exclude="${model_dir}/decode*" -f models/${archive_name} ${model_dir} ${graph}
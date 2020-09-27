#!/usr/bin/env bash
# Extract MFCC or PLP features from kaldi formatted folder
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

feature_type="mfcc"
mfcc_config=conf/mfcc.conf
plp_config=conf/plp.conf
subset=4000

. utils/parse_options.sh
. utils.sh
. path.sh

dataset=$1

nj=$(get_njobs $dataset)

if [ "$feature_type" == "mfcc" ]; then
  log_info "MFCC extraction"
  log_time steps/make_mfcc.sh --mfcc-config ${mfcc_config} --nj $nj ${dataset}
  log_time steps/compute_cmvn_stats.sh ${dataset}
fi

if [ "$feature_type" == "plp" ]; then
  log_info "PLP extraction"
  log_time steps/make_plp.sh --plp-config ${plp_config} --nj $nj ${dataset} 
  log_time steps/compute_cmvn_stats.sh ${dataset}
fi

utils/fix_data_dir.sh ${dataset}
utils/validate_data_dir.sh ${dataset}
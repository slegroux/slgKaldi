#!/usr/bin/env bash
# Extract MFCC or PLP features from kaldi formatted folder
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh

feature_type="mfcc"
mfcc_config=conf/mfcc.conf
plp_config=conf/plp.conf
subset=4000
nj=
. utils/parse_options.sh

dataset=$1

if [ ! -z ${nj} ]; then
  echo "nj set by user: $nj"
else
  nj=$(get_njobs $dataset)
  echo "nj set as max n_speakers $nj"
fi

log_info "Feature extraction njobs: $nj"

if [ "$feature_type" == "mfcc" ]; then
  log_info "MFCC extraction"
  log_time steps/make_mfcc.sh --mfcc-config ${mfcc_config} --nj $nj ${dataset}
  log_time steps/compute_cmvn_stats.sh ${dataset}

elif [ "$feature_type" == "plp" ]; then

  log_info "PLP extraction"
  log_time steps/make_plp.sh --plp-config ${plp_config} --nj $nj ${dataset} 
  log_time steps/compute_cmvn_stats.sh ${dataset}
else
  log_info "Feature ${feature_type} is not supported"
fi

utils/fix_data_dir.sh ${dataset}
utils/validate_data_dir.sh ${dataset}
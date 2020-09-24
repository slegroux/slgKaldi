#!/usr/bin/env bash
# Extract MFCC or PLP features from kaldi formatted folder
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

feature_type="mfcc"
mfcc_conf=conf/mfcc.conf
plp_conf=conf/plp.conf
subset=4000

. utils/parse_options.sh
. utils.sh
. path.sh

dataset=$1
echo $feature_type
if [ "$feature_type" == "mfcc" ]; then
  echo "[INFO] MFCC extraction "
  nj=$(get_njobs $dataset)
  steps/make_mfcc.sh --mfcc-config ${conf} --nj $nj ${dataset}
  steps/compute_cmvn_stats.sh ${dataset}
fi

if [ "$feature_type" == "plp" ]; then
  echo "[INFO] PLP extraction "
  nj=$(get_njobs $dataset)
  steps/make_plp.sh --plp-config ${plp_conf} --nj $nj ${dataset} 
  steps/compute_cmvn_stats.sh ${dataset}
fi

utils/fix_data_dir.sh ${dataset}
utils/validate_data_dir.sh ${dataset}
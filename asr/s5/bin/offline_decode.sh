#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=0

compute_graph=false

. utils.sh
. path.sh
. utils/parse_options.sh

dataset=$1
ivec_extractor=$2
lang_test=$3
tree=$4
graph=$5
mdl=$6

if [ $stage -le 0 ]; then
    set -x
    if [ ! -d ${dataset}_hires ]; then
        utils/copy_data_dir.sh ${dataset} ${dataset}_hires
        ./features/feature_extract.sh --feature_type "mfcc" --mfcc_config conf/mfcc_hires.conf ${dataset}_hires
    fi
    if [ ! -d ${dataset}_hires/ivectors ]; then
        ./embeddings/ivector_extract.sh ${dataset}_hires ${ivec_extractor} ${dataset}_hires/ivectors
    fi
fi

if [ $stage -le 1 ]; then
    decode_name=$(basename $dataset)
    ./dnn/dnn_testing.sh --compute_graph ${compute_graph} ${dataset}_hires ${lang_test} ${tree} ${graph} ${dataset}_hires/ivectors ${mdl} decode_${decode_name}
fi
#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train500

./features/feature_extraction.sh --feature_type "mfcc" --mfcc_config conf/mfcc.conf $train_set
# ./features/feature_extraction.sh --feature_type "plp" --plp_config conf/plp.conf $train_set
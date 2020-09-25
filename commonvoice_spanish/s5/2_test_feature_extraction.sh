#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

train_set=data/train_500

./2_feature_extraction.sh --feature_type "mfcc" $train_set
./2_feature_extraction.sh --feature_type "plp" $train_set
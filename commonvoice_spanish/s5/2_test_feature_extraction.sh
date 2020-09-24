#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

./2_feature_extraction.sh --feature_type "mfcc" data/train_50
./2_feature_extraction.sh --feature_type "plp" data/train_50
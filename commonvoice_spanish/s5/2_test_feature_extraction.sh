#!/usr/bin/env bash

./2_feature_extraction.sh --feature_type "mfcc" data/train_50
./2_feature_extraction.sh --feature_type "plp" data/train_50
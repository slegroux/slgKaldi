#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

dataset=data/train500
ivec_extractor=exp/nnet3_train_sp_vp/extractor
ivec_dir=${dataset}_hires/ivec

# compute hires mfcc
utils/copy_data_dir.sh $dataset ${dataset}_hires
./features/feature_extract.sh --feature_type "mfcc" --mfcc-config conf/mfcc_hires.conf ${dataset}_hires
# extract ivec on hires mfcc
./features/ivector_extract.sh ${dataset}_hires ${ivec_extractor} ${ivec_dir}

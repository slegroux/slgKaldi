#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

dataset=data/train500
lang=data/lang
tri3=exp/tri3_500

ivec_model=exp/ivector_500_sp_vp_hires
ivec_extractor=${ivec_model}/extractor
ivec_data=${dataset}_hires/ivectors

./embeddings/ivector_data_prep.sh ${dataset} ${lang} ${tri3} #${dataset}_sp_vp_hires #tri3_500_sp_ali
./embeddings/ivector_training.sh --online_cmvn_iextractor false ${dataset}_sp_vp_hires ${tri3} ${ivec_model}

# compute hires mfcc
utils/copy_data_dir.sh $dataset ${dataset}_hires
./features/feature_extract.sh --feature_type "mfcc" --mfcc-config conf/mfcc_hires.conf ${dataset}_hires
# extract ivec on hires mfcc
./embeddings/ivector_extract.sh ${dataset}_hires ${ivec_extractor} ${ivec_data}

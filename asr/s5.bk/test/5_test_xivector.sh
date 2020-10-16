#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# basic data
dataset=data/train500
lang=data/lang
tri3=exp/tri3_500

# ivector
ivec_model=exp/ivector_500_sp_vp_hires
ivec_extractor=${ivec_model}/extractor

online_cmvn_iextractor=false

./embeddings/ivector_data_prep.sh ${dataset} ${lang} ${tri3} #${dataset}_sp_vp_hires #tri3_500_sp_ali
./embeddings/ivector_training.sh --online_cmvn_iextractor ${online_cmvn_iextractor} ${dataset}_sp_vp_hires ${tri3} ${ivec_model}

# extract ivectors from hires mfcc
./embeddings/ivector_extract.sh ${dataset}_sp_vp_hires ${ivec_extractor} ${dataset}_sp_vp_hires/ivectors

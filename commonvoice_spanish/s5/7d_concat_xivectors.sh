#!/usr/bin/env bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail

njobs=$(($(nproc)-1))

stage=0

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

#input
ivector_dir=$1
xvector_dir=$2
#output
xivector_dir=$3

# #input
# ivector_dir=data/${dataset}_hires/ivectors
# xvector_dir=data/${dataset}_x/xvectors
# #output
# xivector_dir=data/${dataset}_x/xi_vectors

if [ $stage -le 0 ]; then
    # append to ivectors
    if [ ! -d $xivector_dir ]; then
      mkdir -p $xivector_dir
    fi
    
    cp $ivector_dir/ivector_period $xivector_dir
    
    append-vector-to-feats scp:$ivector_dir/ivector_online.scp \
                scp:$xvector_dir/xvector.scp \
                ark,scp:$xivector_dir/ivectors.ark,$xivector_dir/ivector_online.scp

fi 

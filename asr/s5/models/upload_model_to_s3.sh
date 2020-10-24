#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

lang=$1
mdl_archive=$2

aws s3 cp $mdl_archive s3://kaldi-models/${lang}/
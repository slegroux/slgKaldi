#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

corpus=$1
train=$2

cat ${corpus} |cut -d' ' -f2- > ${train}
#!/usr/bin/env bash

. cmd.sh
. path.sh
. utils/parse_options.sh

feat_scp=$1
tri_ali_mdl=$2

feat-to-dim scp:${feat_scp} -
hmm-info $tri_ali_mdl
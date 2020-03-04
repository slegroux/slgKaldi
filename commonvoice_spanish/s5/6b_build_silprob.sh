#!/usr/bin/env bash
# 2020 slegroux@ccrma.stanford.edu

. cmd.sh
. path.sh
. utils/parse_options.sh

local/build_silprob.sh --train_set train --lang_dir data/lang --tri exp/tri3b
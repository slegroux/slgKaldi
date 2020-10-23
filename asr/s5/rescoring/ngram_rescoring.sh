#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

. utils.sh
. path.sh
. utils/parse_options.sh

old_lang=$1
new_lang=$2
datadir=$3
decodedir=$4

steps/lmrescore.sh --cmd "run.pl" --self-loop-scale 1.0 ${old_lang} ${new_lang} \
          ${datadir} ${decodedir} ${decodedir}_rescored || exit 1

log_wer ${decodedir}
log_wer ${decodedir}_rescored
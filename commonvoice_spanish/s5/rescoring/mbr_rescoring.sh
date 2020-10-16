#!/usr/bin/env bash
# (c)2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail


test_set=test
lang=lang_chain
model=exp/chain/tdnnf_tedlium_train_combined
decode_dir=${model}/decode_tgsmall_${test_set}

. cmd.sh
. path.sh
. utils/parse_options.sh

decode_dir_mbr=${decode_dir}.mbr

cp -r $decode_dir{,.mbr}
local/score_mbr.sh data/${test_set} data/$lang $decode_dir_mbr
echo "MBR rescoring" | tee -a WER.txt
for x in $decode_dir_mbr; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done |tee -a WER.txt

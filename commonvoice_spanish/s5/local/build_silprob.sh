#!/bin/bash

set -e

train_set=train
lang_dir=data/lang
tri=exp/tri3b
dict_dir=data/local/dict

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

steps/get_prons.sh --cmd "$train_cmd" data/${train_set} ${lang_dir} ${tri}

utils/dict_dir_add_pronprobs.sh --max-normalize true \
  ${dict_dir} ${tri}/pron_counts_nowb.txt \
  ${tri}/sil_counts_nowb.txt ${tri}/pron_bigram_counts_nowb.txt data/local/dict_pp

utils/prepare_lang.sh data/local/dict_pp "<UNK>" data/local/lang_pp data/lang_pp

cp -rT data/lang_pp data/lang_pp_test
cp -f data/lang_test/G.fst data/lang_pp_test

# cp -rT data/lang_pp data/lang_pp_test_fg
# cp -f data/lang_test_fg/G.carpa data/lang_pp_test_fg

utils/mkgraph.sh data/lang_pp_test ${tri} ${tri}/graph_pp

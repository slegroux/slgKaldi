#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

stage=

. path.sh
. utils.sh
. utils/parse_options.sh

dataset=$1
lang=$2
lang_test=$3
tri3=$4
dict=$5

log_info "Add pronunciations probs"
./steps/get_prons.sh ${dataset} ${lang} ${tri3}

if [ -d ${dict}_pp ]; then
    mv ${dict}_pp ${dict}_pp_$(date '+%Y-%m-%d-%H-%M-%S')
else
    log_time utils/dict_dir_add_pronprobs.sh --max-normalize true \
        ${dict} ${tri3}/pron_counts_nowb.txt \
        ${tri3}/sil_counts_nowb.txt ${tri3}/pron_bigram_counts_nowb.txt ${dict}_pp
fi

tmp_dir=$(mktemp -d)
log_info "Prepare lang with pp"
log_time utils/prepare_lang.sh ${dict}_pp "<UNK>" ${tmp_dir}/lang_pp ${lang}_pp

cp -rT ${lang}_pp ${lang}_pp_test
cp -f ${lang_test}/G.fst ${lang}_pp_test

log_info "Make pp graph"
log_time utils/mkgraph.sh ${lang}_pp_test ${tri3} ${tri3}/graph_pp

#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

unk="<UNK>"
lang='es'

. utils.sh
. path.sh
. utils/parse_options.sh

lexicon=$1
dict=$2
lang_dir=$3

tmp=$(mktemp -d /tmp/lang-XXXX) #data/local/lang

log_info "Prepare dict"
if [ $lang == 'es' ]; then
    log_time ./data_prep/es_prepare_dict.sh --unk ${unk} ${lexicon} ${dict}
else
    echo "[ERROR] langauge not supported"
fi

log_info "Prepare lang"
log_time ./utils/prepare_lang.sh \
    ${dict} ${unk} \
    ${tmp} ${lang_dir}


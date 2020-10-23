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


if [ $lang == 'es' ]; then
    log_info "Prepare ES dict"
    log_time ./data_prep/es_prepare_dict.sh --unk ${unk} ${lexicon} ${dict}
elif [ $lang == 'en' ]; then
    log_info "Prepare EN dict"
    log_time ./data_prep/en_prepare_dict.sh --unk ${unk} ${lexicon} ${dict}
else
    log_err "Language not supported"
fi

log_info "Prepare lang"
log_time ./utils/prepare_lang.sh \
    ${dict} ${unk} \
    ${tmp} ${lang_dir}

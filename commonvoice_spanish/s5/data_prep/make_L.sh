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

if [ $lang == $es ]; then
    ./data_prep/es_prepare_dict.sh --unk ${unk} ${lexicon} ${dict}
else
    echo "[ERROR] langauge not supported"
fi

./utils/prepare_lang.sh \
    ${dict} ${unk} \
    ${tmp} ${lang_dir}


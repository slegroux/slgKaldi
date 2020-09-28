#!/usr/bin/env bash
# (c) 2020 Sylvain Le Groux <slegroux@ccrma.stanford.edu>

unk="<UNK>"

. utils.sh
. path.sh
. utils/parse_options.sh

lexicon=$1
dict=$2
lang=$3

tmp=$(mktemp -d /tmp/lang-XXXX) #data/local/lang

./data_prep/es_prepare_dict.sh --unk ${unk} ${lexicon} ${dict}
./utils/prepare_lang.sh \
    ${dict} ${unk} \
    ${tmp} ${lang}

